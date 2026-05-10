---
name: react-bundle-optimization
description: >
  Bundle size and JavaScript performance patterns: dynamic imports, barrel
  file avoidance, lazy loading, array/Set/Map optimizations. Use when reducing
  bundle size, optimizing load time, or applying JS micro-optimizations in
  React apps.
---

# React Bundle Optimization

## Bundle Size Optimization

### Avoid barrel file imports

Barrel files (`index.js` re-exporting everything) load thousands of unused modules. Import directly:

```typescript
// WRONG — loads entire library (~1583 modules for lucide-react)
import { Check, X } from 'lucide-react'

// RIGHT — direct import
import Button from '@mui/material/Button'
```

Cost: 200-800ms import time. Affects `lucide-react`, `@mui/material`, `@tabler/icons-react`, `react-icons`, `lodash`, `date-fns`, `rxjs`.

### Dynamic imports for heavy components

```typescript
// WRONG — bundles with main chunk
import { MonacoEditor } from './monaco-editor'

// RIGHT — lazy loaded
const MonacoEditor = lazy(() => import('./monaco-editor'))
```

### Prefer statically analyzable paths

```typescript
// WRONG — bundler can't analyze
const Page = await import(PAGE_MODULES[pageName])

// RIGHT — explicit map
const PAGES = {
  home: () => import('./pages/home'),
  settings: () => import('./pages/settings'),
}
const Page = await PAGES[pageName]()
```

### Preload based on user intent

```typescript
function EditorButton({ onClick }) {
  const preload = () => import('./monaco-editor')
  return <button onMouseEnter={preload} onFocus={preload} onClick={onClick}>Open</button>
}
```

## JavaScript Performance

### Build index maps for repeated lookups

```typescript
// WRONG — O(n) per lookup
orders.map(o => ({ ...o, user: users.find(u => u.id === o.userId) }))

// RIGHT — O(1) per lookup
const userById = new Map(users.map(u => [u.id, u]))
orders.map(o => ({ ...o, user: userById.get(o.userId) }))
```

For 1000 orders × 1000 users: 1M ops → 2K ops.

### Use Set/Map for O(1) lookups

```typescript
// WRONG — O(n) per check
items.filter(item => allowedIds.includes(item.id))

// RIGHT — O(1) per check
const allowed = new Set(allowedIds)
items.filter(item => allowed.has(item.id))
```

### Use flatMap to map and filter in one pass

```typescript
// WRONG — 2 iterations
const names = users.map(u => u.isActive ? u.name : null).filter(Boolean)

// RIGHT — 1 iteration
const names = users.flatMap(u => u.isActive ? [u.name] : [])
```

### Use toSorted() instead of sort() for immutability

```typescript
// WRONG — mutates original
users.sort((a, b) => a.name.localeCompare(b.name))

// RIGHT — returns new array
users.toSorted((a, b) => a.name.localeCompare(b.name))
```

### Cache property access in loops

```typescript
// WRONG — 3 lookups × N iterations
for (let i = 0; i < arr.length; i++) process(obj.x.y.z)

// RIGHT — 1 lookup total
const val = obj.x.y.z
for (let i = 0; i < arr.length; i++) process(val)
```

### Cache repeated function calls

```typescript
const cache = new Map()

function cachedSlugify(text) {
  if (cache.has(text)) return cache.get(text)
  const result = slugify(text)
  cache.set(text, result)
  return result
}
```

### Cache Storage API calls

```typescript
const storageCache = new Map()

function getLocal(key) {
  if (!storageCache.has(key))
    storageCache.set(key, localStorage.getItem(key))
  return storageCache.get(key)
}
```

### Combine multiple array iterations

```typescript
// WRONG — 3 iterations
const admins = users.filter(u => u.isAdmin)
const inactive = users.filter(u => !u.isActive)

// RIGHT — 1 iteration
const admins = [], inactive = []
for (const u of users) {
  if (u.isAdmin) admins.push(u)
  if (!u.isActive) inactive.push(u)
}
```

### Use loop for min/max instead of sort

```typescript
// WRONG — O(n log n)
const sorted = [...items].sort((a, b) => b.date - a.date)
return sorted[0]

// RIGHT — O(n)
let latest = items[0]
for (let i = 1; i < items.length; i++)
  if (items[i].date > latest.date) latest = items[i]
```

### Hoist RegExp creation

```typescript
// WRONG — recreated every call
function validate(email) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) }

// RIGHT — created once
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
function validate(email) { return EMAIL_RE.test(email) }
```

### Early return from functions

```typescript
function validateUsers(users) {
  for (const user of users) {
    if (!user.email) return { valid: false, error: 'Email required' }
    if (!user.name) return { valid: false, error: 'Name required' }
  }
  return { valid: true }
}
```

