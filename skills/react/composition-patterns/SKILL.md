---
name: composition-patterns
description: >
  React composition patterns that scale: compound components, state lifting,
  context interfaces, explicit variants, React 19 APIs. Use when refactoring
  components with boolean props, building reusable component libraries, or
  designing component APIs.
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

## Compound components with shared context

```typescript
const ComposerContext = createContext(null)

function Provider({ children, state, actions, meta }) {
  return <ComposerContext value={{ state, actions, meta }}>{children}</ComposerContext>
}

function Input() {
  const { state, actions } = use(ComposerContext)
  return <TextInput value={state.input} onChangeText={text => actions.update(s => ({ ...s, input: text }))} />
}

function Submit() {
  const { actions } = use(ComposerContext)
  return <Button onPress={actions.submit}>Send</Button>
}

const Composer = { Provider, Frame, Input, Submit, Header, Footer }
```

## Define generic context interfaces

Three parts: `state` (data), `actions` (callbacks), `meta` (refs/config):

```typescript
interface ComposerContextValue {
  state: ComposerState
  actions: ComposerActions
  meta: ComposerMeta
}
```

Different providers implement the same interface:

```typescript
// Provider A: local state
function ForwardProvider({ children }) {
  const [state, setState] = useState(initState)
  return <Composer.Provider state={state} actions={{ update: setState, submit }}>{children}</Composer.Provider>
}

// Provider B: global synced state
function ChannelProvider({ channelId, children }) {
  const { state, update, submit } = useGlobalChannel(channelId)
  return <Composer.Provider state={state} actions={{ update, submit }}>{children}</Composer.Provider>
}

// Same UI works with both
<ForwardProvider><Composer.Frame><Composer.Input /><Composer.Submit /></Composer.Frame></ForwardProvider>
<ChannelProvider channelId="abc"><Composer.Frame><Composer.Input /><Composer.Submit /></Composer.Frame></ChannelProvider>
```

## Lift state into providers

Components needing shared state don't need visual nesting — just the same provider:

```typescript
function ForwardMessageDialog() {
  return (
    <ForwardMessageProvider>
      <Dialog>
        <Composer.Frame>
          <Composer.Input />
        </Composer.Frame>
        <MessagePreview />       {/* outside Frame, inside provider */}
        <DialogActions>
          <ForwardButton />      {/* outside Frame, inside provider */}
        </DialogActions>
      </Dialog>
    </ForwardMessageProvider>
  )
}

function ForwardButton() {
  const { actions } = use(ComposerContext)
  return <Button onPress={actions.submit}>Forward</Button>
}
```

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

### use() instead of useContext

```typescript
// React 18
const value = useContext(MyContext)

// React 19
const value = use(MyContext)
// Can be called conditionally
```

