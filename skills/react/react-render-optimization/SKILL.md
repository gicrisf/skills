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

