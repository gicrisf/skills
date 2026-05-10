---
name: react-advanced-patterns
description: >
  Advanced React patterns: useEffectEvent, stable callback refs, app
  initialization guards, avoiding Effect Event in dependency arrays. Use when
  working with advanced React APIs, Effect Events, or initialization patterns.
---

# React Advanced Patterns

## useEffectEvent for stable callback refs

Access latest values in callbacks without adding them to dependency arrays:

```typescript
import { useEffect, useEffectEvent } from 'react'

function SearchInput({ onSearch }) {
  const [query, setQuery] = useState('')
  const onSearchEvent = useEffectEvent(onSearch)

  useEffect(() => {
    const timeout = setTimeout(() => onSearchEvent(query), 300)
    return () => clearTimeout(timeout)
  }, [query])  // onSearch not in deps — no re-subscribe
}
```

## Don't put Effect Events in dependency arrays

Effect Event functions intentionally change identity each render:

```typescript
function Chat({ roomId, onConnected }) {
  const handleConnected = useEffectEvent(onConnected)

  // WRONG — re-runs every render
  useEffect(() => { /* ... */ }, [roomId, handleConnected])

  // RIGHT — depend on reactive values only
  useEffect(() => { /* ... */ }, [roomId])
}
```

## Initialize app once, not per mount

Components can remount; effects re-run:

```typescript
let didInit = false

function App() {
  useEffect(() => {
    if (didInit) return
    didInit = true
    loadFromStorage()
    checkAuth()
  }, [])
}
```

## Store event handlers in refs for stable subscriptions

```typescript
import { useEffectEvent } from 'react'

function useWindowEvent(event, handler) {
  const onEvent = useEffectEvent(handler)

  useEffect(() => {
    window.addEventListener(event, onEvent)
    return () => window.removeEventListener(event, onEvent)
  }, [event])  // handler not in deps — stable subscription
}
```

