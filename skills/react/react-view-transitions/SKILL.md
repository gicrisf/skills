---
name: react-view-transitions
description: >
  Animate UI state changes using React's View Transition API: ViewTransition
  component, shared element morphs, CSS pseudo-elements, Suspense reveals,
  list reorder. Use when adding page transitions, route animations, or shared
  element animations in React apps.
---

# React View Transitions

## Core Concepts

### ViewTransition component

```typescript
import { ViewTransition } from 'react'

<ViewTransition>
  <Component />
</ViewTransition>
```

Only activated by `startTransition`, `useDeferredValue`, or `Suspense`. Regular `setState` does not animate.

### Critical placement rule

VT only activates if it appears before any DOM nodes:

```typescript
// Works
<ViewTransition enter="auto"><div>Content</div></ViewTransition>

// Broken — div wraps VT
<div><ViewTransition enter="auto"><div>Content</div></ViewTransition></div>
```

### Animation triggers

| Trigger | When it fires |
|---|---|
| `enter` | VT inserted during a transition |
| `exit` | VT removed during a transition |
| `update` | DOM mutations inside VT |
| `share` | Same `name` unmounts in one VT and mounts in another |

### Styling with view transition classes

```typescript
<ViewTransition
  default="none"
  enter="slide-in"
  exit="slide-out"
  share="morph"
/>
```

CSS pseudo-elements:

```css
::view-transition-old(.slide-out) { /* outgoing snapshot */ }
::view-transition-new(.slide-in)  { /* incoming snapshot */ }
```

## Transition types

Tag transitions with `addTransitionType` for context-specific animations:

```typescript
import { addTransitionType } from 'react'

startTransition(() => {
  addTransitionType('nav-forward')
  router.push('/detail/1')
})
```

Map types to CSS classes:

```typescript
<ViewTransition
  default="none"
  enter={{ 'nav-forward': 'slide-from-right', 'nav-back': 'slide-from-left', default: 'none' }}
  exit={{ 'nav-forward': 'slide-to-left', 'nav-back': 'slide-to-right', default: 'none' }}
>
  <Page />
</ViewTransition>
```

## Shared element transitions

Same `name` on two VTs creates a morph:

```typescript
<ViewTransition name="hero-image">
  <img src="/thumb.jpg" onClick={() => startTransition(() => onSelect())} />
</ViewTransition>

<ViewTransition name="hero-image">
  <img src="/full.jpg" />
</ViewTransition>
```

Only one VT with a given `name` can be mounted at a time — use unique IDs.

## Common patterns

### Enter/Exit

```typescript
{show && (
  <ViewTransition enter="fade-in" exit="fade-out">
    <Panel />
  </ViewTransition>
)}
```

### List reorder

```typescript
{items.map(item => (
  <ViewTransition key={item.id}>
    <ItemCard item={item} />
  </ViewTransition>
))}
```

Trigger inside `startTransition`. No wrapper `<div>` between list and VT.

### Composing shared elements with list identity

```typescript
{items.map(item => (
  <ViewTransition key={item.id}>                                          {/* list identity */}
    <Link to={`/items/${item.id}`}>
      <ViewTransition name={`image-${item.id}`} share="morph" default="none">  {/* shared element */}
        <Image src={item.image} />
      </ViewTransition>
    </Link>
  </ViewTransition>
))}
```

Missing either layer means that animation silently doesn't happen.

### Force re-enter with key

```typescript
<ViewTransition key={searchParams.toString()} enter="slide-up" default="none">
  <ResultsGrid />
</ViewTransition>
```

### Suspense fallback to content

```typescript
<Suspense fallback={<ViewTransition exit="slide-down"><Skeleton /></ViewTransition>}>
  <ViewTransition enter="slide-up" default="none"><Content /></ViewTransition>
</Suspense>
```

## CSS animation recipes

```css
:root {
  --duration-exit: 150ms;
  --duration-enter: 210ms;
  --duration-move: 400ms;
}

@keyframes fade {
  from { filter: blur(3px); opacity: 0; }
  to { filter: blur(0); opacity: 1; }
}

/* Fade */
::view-transition-old(.fade-out) {
  animation: var(--duration-exit) ease-in fade reverse;
}
::view-transition-new(.fade-in) {
  animation: var(--duration-enter) ease-out var(--duration-exit) both fade;
}

/* Directional navigation */
::view-transition-old(.nav-forward) { animation: 150ms ease-in fade reverse; }
::view-transition-new(.nav-forward) { animation: 210ms ease-out 150ms both fade; }
::view-transition-old(.nav-back) { animation: 150ms ease-in fade reverse; }
::view-transition-new(.nav-back) { animation: 210ms ease-out 150ms both fade; }

/* Shared element morph */
::view-transition-group(.morph) {
  animation-duration: var(--duration-move);
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(*),
  ::view-transition-new(*),
  ::view-transition-group(*) {
    animation-duration: 0s !important;
  }
}
```

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(*),
  ::view-transition-new(*),
  ::view-transition-group(*) {
    animation-duration: 0s !important;
    animation-delay: 0s !important;
  }
}
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| VT not activating | Ensure VT comes before any DOM node; ensure `startTransition` |
| "Two VTs with same name" | Names must be globally unique — use IDs |
| Layout VT prevents page VTs from animating | Remove layout VT wrapping `{children}` |
| Only updates animate | Conditionally render VT itself or wrap in `Suspense` |
| `default` key missing | Type-keyed objects require `default` key |
| Backdrop-blur flickers | `::view-transition-old(name) { display: none }` |

