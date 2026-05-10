---
name: react-data-fetching
description: >
  Async data fetching patterns for React: eliminate waterfalls, parallelize
  requests, Suspense boundaries, SWR caching. Use when implementing data
  fetching, optimizing async operations, or reducing request waterfalls in
  React components.
---

# React Data Fetching

## Eliminate Waterfalls

Waterfalls are the #1 performance killer. Each sequential await adds full network latency.

```typescript
// WRONG — sequential
const user = await fetchUser()
const posts = await fetchPosts()

// RIGHT — parallel
const [user, posts] = await Promise.all([
  fetchUser(),
  fetchPosts()
])
```

### Defer await until needed

Move awaits into branches that actually use them:

```typescript
// WRONG — blocks both branches
async function handle(userId, skip) {
  const data = await fetchData(userId)
  if (skip) return { skipped: true }
  return processData(data)
}

// RIGHT — only blocks when needed
async function handle(userId, skip) {
  if (skip) return { skipped: true }
  const data = await fetchData(userId)
  return processData(data)
}
```

### Check cheap conditions before async

```typescript
// WRONG — awaits flag even when condition is false
const flag = await getFlag()
if (flag && someCondition) { ... }

// RIGHT — check cheap condition first
if (someCondition) {
  const flag = await getFlag()
  if (flag) { ... }
}
```

### Strategic Suspense boundaries

Wrap data-dependent sections, not whole pages:

```typescript
function Page() {
  return (
    <div>
      <Header />            {/* renders immediately */}
      <Suspense fallback={<Skeleton />}>
        <DataSection />     {/* streams in */}
      </Suspense>
      <Footer />            {/* renders immediately */}
    </div>
  )
}
```

## Client-Side Data Fetching

### SWR for automatic deduplication

```typescript
import useSWR from 'swr'

function UserList() {
  // Multiple instances share one request
  const { data } = useSWR('/api/users', fetcher)
}
```

For mutations:

```typescript
import { useSWRMutation } from 'swr/mutation'

function UpdateButton() {
  const { trigger } = useSWRMutation('/api/user', updateUser)
  return <button onClick={() => trigger()}>Update</button>
}
```

### Passive event listeners

Add `{ passive: true }` to touch/wheel listeners that don't call `preventDefault()`:

```typescript
useEffect(() => {
  const handler = (e) => console.log(e.touches[0].clientX)
  document.addEventListener('touchstart', handler, { passive: true })
  return () => document.removeEventListener('touchstart', handler)
}, [])
```

### Version and minimize localStorage

```typescript
const VERSION = 'v2'

function saveConfig(config) {
  try {
    localStorage.setItem(`config:${VERSION}`, JSON.stringify(config))
  } catch { /* quota exceeded, private browsing */ }
}

function loadConfig() {
  try {
    return JSON.parse(localStorage.getItem(`config:${VERSION}`))
  } catch { return null }
}
```

Always wrap in try-catch — `getItem` / `setItem` throw in incognito, quota exceeded, or disabled storage.

