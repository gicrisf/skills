---
name: react-render-optimization
description: >
  React re-render and rendering performance patterns: useMemo, useCallback,
  state management, memo, Suspense, hydration, SVG optimization. Use when
  optimizing component re-renders, reducing unnecessary renders, or improving
  rendering performance in React apps.
---

# React Render Optimization

## Re-render Optimization

### Calculate derived state during render

```typescript
// WRONG — redundant state + effect
const [fullName, setFullName] = useState('')
useEffect(() => setFullName(first + ' ' + last), [first, last])

// RIGHT — derive during render
const fullName = first + ' ' + last
```

### Don't define components inside components

```typescript
// WRONG — remounts on every render
function Profile({ user }) {
  const Avatar = () => <img src={user.avatar} />
  return <Avatar />
}

// RIGHT — pass props
function Avatar({ src }) { return <img src={src} /> }
function Profile({ user }) { return <Avatar src={user.avatar} /> }
```

### Functional setState updates

```typescript
// WRONG — stale closure risk
const addItems = useCallback((items) => {
  setItems([...items, ...items])  // uses stale items
}, [items])

// RIGHT — functional update, no dependency needed
const addItems = useCallback((newItems) => {
  setItems(curr => [...curr, ...newItems])
}, [])
```

### Lazy state initialization

```typescript
// WRONG — runs on every render
const [index] = useState(buildIndex(items))

// RIGHT — runs once
const [index] = useState(() => buildIndex(items))
```

### Narrow effect dependencies

```typescript
// WRONG — re-runs on any user field change
useEffect(() => { console.log(user.id) }, [user])

// RIGHT — re-runs only when id changes
useEffect(() => { console.log(user.id) }, [user.id])
```

### Extract to memoized components

```typescript
const UserAvatar = memo(function UserAvatar({ user }) {
  return <Avatar id={computeAvatarId(user)} />
})

function Profile({ user, loading }) {
  if (loading) return <Skeleton />  // skips avatar computation
  return <UserAvatar user={user} />
}
```

### Hoist static JSX elements

```typescript
const loadingSkeleton = <div className="animate-pulse h-20 bg-gray-200" />

function Container() {
  return <div>{loading && loadingSkeleton}</div>
}
```

### Zustand selectors for fine-grained re-renders

Subscribe to one slice at a time — a component re-renders only when its selected value changes by `Object.is`. With Immer middleware, actions mutate a draft directly:

```typescript
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'

type State = {
  user: { name: string; email: string; avatar: string }
  isOpen: boolean
}
type Actions = {
  setUserName: (name: string) => void
  toggle: () => void
}

const useStore = create<State & Actions>()(
  immer((set) => ({
    user: { name: 'Alice', email: 'a@b.com', avatar: '/img.png' },
    isOpen: false,
    setUserName: (name) => set((s) => { s.user.name = name }),
    toggle: () => set((s) => { s.isOpen = !s.isOpen }),
  }))
)

// Re-renders only when user.name changes
function UserName() {
  const name = useStore(s => s.user.name)
  return <span>{name}</span>
}

// Re-renders only when isOpen flips — unaffected by user updates
function Panel() {
  const isOpen = useStore(s => s.isOpen)
  return isOpen ? <div>...</div> : null
}
```

More targeted than passing whole objects through props or Context. Note the extra `()` after `create<...>` — required when chaining middleware in TypeScript.

### Use useShallow when selecting multiple values

A selector that returns a new object/array creates a fresh reference each render and re-renders on every store change. Wrap it in `useShallow` to compare contents instead:

```typescript
import { useShallow } from 'zustand/react/shallow'

// WRONG — new object each render → re-renders on any store change
const { name, email } = useStore(s => ({ name: s.user.name, email: s.user.email }))

// RIGHT — shallow-compares the returned object
const { name, email } = useStore(
  useShallow(s => ({ name: s.user.name, email: s.user.email }))
)
```

Same applies to array-returning selectors (`Object.keys(state)`, filtered lists). For a single primitive value, no wrapper is needed.

### Use transitions for non-urgent updates

```typescript
import { startTransition } from 'react'

function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)
  useEffect(() => {
    const handler = () => startTransition(() => setScrollY(window.scrollY))
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])
}
```

### useDeferredValue for expensive derived renders

```typescript
function Search({ items }) {
  const [query, setQuery] = useState('')
  const deferredQuery = useDeferredValue(query)
  const filtered = useMemo(
    () => items.filter(item => fuzzyMatch(item, deferredQuery)),
    [items, deferredQuery]
  )
  const isStale = query !== deferredQuery

  return (
    <>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <div style={{ opacity: isStale ? 0.7 : 1 }}>
        <ResultsList results={filtered} />
      </div>
    </>
  )
}
```

### Use useRef for transient values

```typescript
function Tracker() {
  const lastX = useRef(0)
  useEffect(() => {
    const onMove = (e) => { lastX.current = e.clientX }
    window.addEventListener('mousemove', onMove)
    return () => window.removeEventListener('mousemove', onMove)
  }, [])
  // No re-render on mouse move
}
```

### Extract default non-primitive values to constants

```typescript
const NOOP = () => {}

const Avatar = memo(function Avatar({ onClick = NOOP }) {
  // ...
})
```

### Split combined hook computations

Separate independent computations with different deps:

```typescript
const filtered = useMemo(
  () => items.filter(p => p.category === category),
  [items, category]
)
const sorted = useMemo(
  () => filtered.toSorted((a, b) => sortOrder === "asc" ? a.price - b.price : b.price - a.price),
  [filtered, sortOrder]
)
```

## Rendering Performance

### CSS content-visibility for long lists

```css
.message-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px;
}
```

Browser skips layout/paint for off-screen items. ~10× faster initial render for 1000 items.

### Animate SVG wrapper instead of SVG element

Many browsers lack GPU acceleration for CSS animations on SVG:

```typescript
// WRONG — no GPU acceleration
<svg className="animate-spin">...</svg>

// RIGHT — animate the wrapper
<div className="animate-spin">
  <svg>...</svg>
</div>
```

### Explicit conditional rendering

```typescript
// WRONG — renders "0" when count is 0
{count && <span>{count}</span>}

// RIGHT
{count > 0 ? <span>{count}</span> : null}
```

### Use defer or async on script tags

Scripts without `defer` or `async` block HTML parsing:

```typescript
// WRONG — blocks rendering
<script src="analytics.js" />

// RIGHT — non-blocking
<script src="analytics.js" defer />
<script src="analytics.js" async />
```

### Hoist RegExp creation

```typescript
// WRONG — new RegExp every render
function Highlighter({ text, query }) {
  const regex = new RegExp(`(${query})`, 'gi')
}

// RIGHT — memoize
const regex = useMemo(() => new RegExp(`(${query})`, 'gi'), [query])
```

