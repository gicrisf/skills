---
name: composition-patterns
description: >
  React composition patterns with Zustand + Immer: compound components, slices
  pattern, scoped stores via createStore + Context, explicit variants. Use
  when refactoring components with boolean props, building reusable component
  libraries, or designing component APIs.
---

# React Composition Patterns

## Avoid boolean prop proliferation

Each boolean doubles possible states. Use composition instead:

```typescript
// WRONG — exponential complexity
function Composer({ isThread, isEditing, isDMThread, ... }) {
  return (
    <form>
      {isDMThread ? <DMField /> : isThread ? <ChannelField /> : null}
      {isEditing ? <EditActions /> : <DefaultActions />}
    </form>
  )
}

// RIGHT — explicit variants
function ThreadComposer({ channelId }) {
  return (
    <Composer.Frame>
      <Composer.Input />
      <AlsoSendToChannelField id={channelId} />
      <Composer.Footer>
        <Composer.Submit />
      </Composer.Footer>
    </Composer.Frame>
  )
}

function EditComposer() {
  return (
    <Composer.Frame>
      <Composer.Input />
      <Composer.Footer>
        <Composer.CancelEdit />
        <Composer.SaveEdit />
      </Composer.Footer>
    </Composer.Frame>
  )
}
```

## Compound components with Zustand store

Replace Context-as-state-delivery with a Zustand store. For a singleton composer, components import the store hook directly — no Provider tree needed. Use Immer middleware so actions can mutate a draft:

```typescript
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'

type ComposerState = {
  input: string
  attachments: Attachment[]
  isSubmitting: boolean
}
type ComposerActions = {
  setInput: (input: string) => void
  addAttachment: (a: Attachment) => void
  removeAttachment: (id: string) => void
  submit: () => Promise<void>
}

const useComposerStore = create<ComposerState & ComposerActions>()(
  immer((set, get) => ({
    input: '',
    attachments: [],
    isSubmitting: false,
    setInput: (input) => set((s) => { s.input = input }),
    addAttachment: (a) => set((s) => { s.attachments.push(a) }),
    removeAttachment: (id) => set((s) => {
      s.attachments = s.attachments.filter(a => a.id !== id)
    }),
    submit: async () => {
      set((s) => { s.isSubmitting = true })
      try { await send(get().input, get().attachments) }
      finally { set((s) => { s.isSubmitting = false }) }
    },
  }))
)

function Input() {
  const input = useComposerStore(s => s.input)
  const setInput = useComposerStore(s => s.setInput)
  return <TextInput value={input} onChangeText={setInput} />
}

function Submit() {
  const submit = useComposerStore(s => s.submit)
  const disabled = useComposerStore(s => s.isSubmitting)
  return <Button onPress={submit} disabled={disabled}>Send</Button>
}

const Composer = { Frame: ComposerFrame, Input, Submit, Header, Footer }
```

Conventions, per the Zustand docs:

- Colocate actions next to state, with intent-revealing names (`setInput`, `addAttachment`) — avoid a generic `update(fn)` that exposes the whole shape.
- `set` shallow-merges by default, so spreads like `set(s => ({ ...s, input }))` are redundant. With Immer, just mutate: `set((s) => { s.input = input })`.
- Subscribe to one value per `useStore` call. Selecting an object literal needs `useShallow` (see render-optimization skill).

Usage — no Provider wrapper:

```typescript
<Composer.Frame>
  <Composer.Input />
  <Composer.Footer>
    <Composer.Submit />
  </Composer.Footer>
</Composer.Frame>
```

## Split features with the slices pattern

When a store grows, split it into slices and combine them. Each slice owns its state + actions; consumers don't know about the split:

```typescript
import { create, StateCreator } from 'zustand'
import { immer } from 'zustand/middleware/immer'

type InputSlice = {
  input: string
  setInput: (input: string) => void
}
type AttachmentSlice = {
  attachments: Attachment[]
  addAttachment: (a: Attachment) => void
}

// Immer slice signature: see Advanced TypeScript guide
const createInputSlice: StateCreator<
  InputSlice & AttachmentSlice,
  [['zustand/immer', never]],
  [],
  InputSlice
> = (set) => ({
  input: '',
  setInput: (input) => set((s) => { s.input = input }),
})

const createAttachmentSlice: StateCreator<
  InputSlice & AttachmentSlice,
  [['zustand/immer', never]],
  [],
  AttachmentSlice
> = (set) => ({
  attachments: [],
  addAttachment: (a) => set((s) => { s.attachments.push(a) }),
})

const useComposerStore = create<InputSlice & AttachmentSlice>()(
  immer((...a) => ({
    ...createInputSlice(...a),
    ...createAttachmentSlice(...a),
  }))
)
```

Slices can read each other via `get()`. Apply middleware only on the combined store, not inside individual slices.

## Scoped stores via createStore + Context

When multiple instances of the same component need independent state (each dialog gets its own composer), build a vanilla store per-instance and provide it through Context — this is the Zustand-recommended pattern for "initialize state with props":

```typescript
import { createStore, useStore } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { createContext, useContext, useState } from 'react'

type ComposerStore = ReturnType<typeof createComposerStore>

function createComposerStore(initial?: Partial<ComposerState>) {
  return createStore<ComposerState & ComposerActions>()(
    immer((set) => ({
      input: '',
      attachments: [],
      isSubmitting: false,
      ...initial,
      setInput: (input) => set((s) => { s.input = input }),
      addAttachment: (a) => set((s) => { s.attachments.push(a) }),
      removeAttachment: (id) => set((s) => {
        s.attachments = s.attachments.filter(a => a.id !== id)
      }),
      submit: async () => { /* ... */ },
    }))
  )
}

const ComposerContext = createContext<ComposerStore | null>(null)

function ComposerProvider({ children, initial }: { children: ReactNode; initial?: Partial<ComposerState> }) {
  const [store] = useState(() => createComposerStore(initial))  // stable across renders
  return <ComposerContext.Provider value={store}>{children}</ComposerContext.Provider>
}

// Custom hook mirrors the shape of `create`'s hook
function useComposer<T>(selector: (s: ComposerState & ComposerActions) => T): T {
  const store = useContext(ComposerContext)
  if (!store) throw new Error('Missing ComposerProvider')
  return useStore(store, selector)
}

function ForwardMessageDialog() {
  return (
    <ComposerProvider initial={{ input: 'FWD: ' }}>
      <Dialog>
        <ComposerFrame />
        <MessagePreview />
        <ForwardButton />
      </Dialog>
    </ComposerProvider>
  )
}

function ForwardButton() {
  const submit = useComposer(s => s.submit)
  return <Button onPress={submit}>Forward</Button>
}
```

Two things to get right:

- Use `useState(() => createStore(...))`, not `useMemo`. `useState` guarantees the store survives across renders; `useMemo` may be evicted in some environments.
- Context here delivers the store reference — never raw state. Components still subscribe through `useStore(store, selector)`, so selector-based re-render scoping still works.

For non-reactive state per instance (DOM handles, abort controllers, debounce timers), keep `useRef` — refs aren't React state and shouldn't be in the store.

## Action design patterns

### Cross-slice access via get()

Slices stay decoupled at the type level but coordinate at runtime through `get()`. A UI-slice action can call a domain-slice action without importing it:

```typescript
// uiSlice — declares only its own shape in its interface
confirmDelete: () => {
  const id = get().pendingDeleteId
  if (id !== null) {
    get().deleteItem(id)                  // action lives in domainSlice
    set((state) => { state.pendingDeleteId = null })
  }
},
```

The combined store type makes `get()` return the full surface. Use this for orchestration (UI → domain) rather than reaching into another slice's state to re-implement its logic.

### Read-then-set split

Read values via `get()` before calling `set`. Keeps the Immer recipe focused on mutation and avoids redundant lookups inside it:

```typescript
commitGesture: () => {
  const { gesture, preGestureSnapshot, items } = get()
  if (!gesture) return

  const item = items[gesture.targetId]
  const derivedIndex = computeIndex(item)   // computed once, outside the recipe

  set((state) => {
    if (preGestureSnapshot) {
      state.history = pushHistory(preGestureSnapshot, state.history)
    }
    state.gesture = null
    state.preGestureSnapshot = null
  })

  // Side effects use the pre-mutation values
  if (item) get().syncRemote(derivedIndex, item)
},
```

Particularly useful when you need a value as it was **before** the mutation, or want to compute derived data outside the recipe.

### Batch intermediate state — commit one history entry

Continuous interactions (drag, resize, scrub, range-select) emit many state updates but should be a single undoable step. Snapshot on start, mutate freely during, commit once on end:

```typescript
startGesture: (targetId, originX, originY) => {
  const target = get().items[targetId]
  if (!target) return
  set((state) => {
    state.gesture = { targetId, offsetX: originX - target.x, offsetY: originY - target.y }
    state.preGestureSnapshot = toUndoableState(state)   // snapshot, don't push yet
  })
},

updateGesture: (x, y) => {
  const { gesture } = get()
  if (!gesture) return
  set((state) => {                                       // no history push during gesture
    const t = state.items[gesture.targetId]
    t.x = x - gesture.offsetX
    t.y = y - gesture.offsetY
  })
},

endGesture: () => {
  const { gesture, preGestureSnapshot } = get()
  if (!gesture) return
  set((state) => {
    if (preGestureSnapshot) {
      state.history = pushHistory(preGestureSnapshot, state.history)   // commit once
    }
    state.gesture = null
    state.preGestureSnapshot = null
  })
},
```

Same shape works for any "begin / progress / end" interaction.

### Fire-and-forget async side effects after set

Update local state synchronously, then kick off remote sync without awaiting. The action stays sync, the UI stays responsive, and optimistic-update semantics fall out naturally:

```typescript
createItem: (payload) => {
  set((state) => {
    state.items[state.nextId] = { id: state.nextId, ...payload }
    state.nextId += 1
  })
  get().syncCreate(payload)   // async, not awaited — failures handled inside
}
```

Put the sync action in its own slice (e.g. an `apiSlice`) so it owns its error/retry state without leaking into the domain slice.

### Combined store type, re-declared per slice

Each slice re-declares the combined type locally to type its `StateCreator`:

```typescript
// inside domainSlice.ts
type AppStore = DomainSlice & UiSlice & ApiSlice

export const createDomainSlice: StateCreator<
  AppStore,
  [['zustand/immer', never]],
  [],
  DomainSlice
> = (set, get) => ({ /* ... */ })
```

The canonical `AppStore` still lives in the entry file (`useAppStore.ts`). Re-deriving it inside each slice from sibling interfaces is a small duplication that avoids the circular import you'd hit by importing the combined type back into a slice.

## Prefer children over render props

```typescript
// WRONG — awkward render props
<Composer renderHeader={() => <Header />} renderFooter={() => <><Formatting /><Submit /></>} />

// RIGHT — compound components
<Composer.Frame>
  <Composer.Header />
  <Composer.Input />
  <Composer.Footer>
    <Composer.Formatting />
    <Composer.Submit />
  </Composer.Footer>
</Composer.Frame>
```

Use render props only when the parent needs to pass data back (e.g., `renderItem={({ item }) => ...}`).

## React 19 API changes

### Ref as regular prop (no forwardRef)

```typescript
// React 18
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => <input ref={ref} {...props} />)

// React 19
function Input({ ref, ...props }: Props & { ref?: Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />
}
```

