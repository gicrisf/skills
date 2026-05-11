---
name: react-elm-architecture
description: >
  Elm-style modular architecture in React: Model/Msg/init/update/view per
  module, tagged union variants, nested Msg wrapping for parent-child
  composition, pure reducers driven by Zustand or useReducer, exhaustive
  discriminated-union switches. Use when porting from Elm, designing a domain
  with many variants that share an interface, or wanting framework-free
  business logic in a React app.
---

# React Elm Architecture

The Elm Architecture (TEA) splits each domain concept into a self-contained module exporting `Model`, `Msg`, `init`, `update`, `view`. State is plain data, transitions are pure functions, and the framework (Zustand, `useReducer`, anything) just drives the loop. This skill describes how to translate that style faithfully into TypeScript + React.

## Module shape

A TEA module is one file exporting a fixed surface:

```typescript
// shapes/Circle.tsx

// Model — the data
export interface Model {
  pointIds: PointId[]
}

// Msg — all possible transitions, as a tagged union
export type Msg =
  | { type: 'AddPoint'; pointId: PointId }
  | { type: 'RemovePoint'; pointId: PointId }

// init — factory for the empty model
export function init(): Model {
  return { pointIds: [] }
}

// update — pure reducer
export function update(msg: Msg, model: Model): Model {
  switch (msg.type) {
    case 'AddPoint':
      return { ...model, pointIds: [...model.pointIds, msg.pointId] }
    case 'RemovePoint':
      return { ...model, pointIds: model.pointIds.filter(id => id !== msg.pointId) }
  }
}

// view — pure function, not a component class
interface ViewProps {
  model: Model
  points: Record<PointId, Point>
  onSelect: (pointId: PointId) => void
}

export function view({ model, points, onSelect }: ViewProps) {
  return (
    <g>
      {model.pointIds.map(id => (
        <PointDot key={id} point={points[id]} onSelect={() => onSelect(id)} />
      ))}
    </g>
  )
}

// Optional: pure query helpers
export function pointIds(model: Model): PointId[] { return model.pointIds }
```

Conventions:

- One module per concept. No default exports — everything named.
- `update` is pure: no fetch, no setState, no console. All effects live in the driver.
- `view` takes its data as props. It does not subscribe to a store directly — the parent passes the slice in.
- Helper queries (`pointIds`, `isCompleted`) live next to the module so callers don't reach into `Model`.

## Module-as-namespace imports

Mirror Elm's qualified imports — never default-export, always import the whole module:

```typescript
import * as Circle from './Circle'
import * as Polygon from './Polygon'

const m1 = Circle.init()
const m2 = Circle.update({ type: 'AddPoint', pointId: 1 }, m1)
const ui = Circle.view({ model: m2, points, onSelect })
```

Reads exactly like Elm's `Circle.update msg model`. Makes the module boundary visible at every call site.

## Tagged unions for variants

When you have multiple sibling modules implementing the same concept, wrap them in a discriminated union at the parent:

```typescript
// shapes/index.tsx
import * as Circle from './Circle'
import * as Polygon from './Polygon'

export type Shape =
  | { type: 'Circle'; model: Circle.Model }
  | { type: 'Polygon'; model: Polygon.Model }

export type Msg =
  | { type: 'CircleMsg'; msg: Circle.Msg }
  | { type: 'PolygonMsg'; msg: Polygon.Msg }
```

This is the TypeScript translation of Elm's:

```elm
type Shape = Circle Circle.Model | Polygon Polygon.Model
type Msg = CircleMsg Circle.Msg | PolygonMsg Polygon.Msg
```

The wrapper Msg constructors (`CircleMsg`, `PolygonMsg`) let child messages flow up through the parent without the parent understanding the child's internals.

## Parent update — delegation switch

The parent `update` is a router. It pattern-matches on its own Msg, unwraps the inner Msg, and hands it to the child's `update`:

```typescript
export function update(msg: Msg, shape: Shape): Shape {
  switch (msg.type) {
    case 'CircleMsg':
      if (shape.type === 'Circle') {
        return { type: 'Circle', model: Circle.update(msg.msg, shape.model) }
      }
      return shape
    case 'PolygonMsg':
      if (shape.type === 'Polygon') {
        return { type: 'Polygon', model: Polygon.update(msg.msg, shape.model) }
      }
      return shape
  }
}
```

The inner type check (`shape.type === 'Circle'`) is the TS price for not having Elm's pattern-match-on-product-types. If shape/Msg are mismatched, return `shape` unchanged — Msg directed at the wrong variant is a no-op.

## Sibling composition via Msg wrapping

A module can build on another by reusing its `Model` and wrapping its `Msg` — no inheritance:

```typescript
// shapes/CircleWithCenter.tsx
import * as Circle from './Circle'

// Reuse Circle's data shape
export type Model = Circle.Model

// Wrap Circle's Msg
export type Msg = { type: 'CircleMsg'; msg: Circle.Msg }

export function init(): Model { return Circle.init() }

export function update(msg: Msg, model: Model): Model {
  switch (msg.type) {
    case 'CircleMsg':
      return Circle.update(msg.msg, model)
  }
}

// view extends Circle.view by composing
export function view(props: ViewProps) {
  return (
    <g>
      {Circle.view(props)}
      <CenterMarker model={props.model} />
    </g>
  )
}
```

If you later need a Msg specific to `CircleWithCenter` (e.g. `MoveCenter`), add it to the union:

```typescript
export type Msg =
  | { type: 'CircleMsg'; msg: Circle.Msg }
  | { type: 'MoveCenter'; x: number; y: number }
```

Existing `CircleMsg` paths keep working; new variants slot in cleanly.

## Exhaustive switch with TypeScript

Type the return on `update` explicitly and TS forces every variant. To make missing cases a compile error, end with a never-check:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unhandled variant: ${JSON.stringify(x)}`)
}

export function update(msg: Msg, model: Model): Model {
  switch (msg.type) {
    case 'AddPoint':    return { ...model, pointIds: [...model.pointIds, msg.pointId] }
    case 'RemovePoint': return { ...model, pointIds: model.pointIds.filter(id => id !== msg.pointId) }
    default:            return assertNever(msg)   // compile error if a case is missing
  }
}
```

This is the TS equivalent of Elm's required-exhaustive `case` expressions. Adding a new Msg variant lights up every switch.

## Pure reducers driven by Zustand

The reducer module knows nothing about React, Zustand, or fetch. The store wires the model into a runtime — actions become "lift msg into store state":

```typescript
import * as Shape from './shapes'
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'

type State = { shape: Shape.Shape }
type Actions = { dispatch: (msg: Shape.Msg) => void }

const useStore = create<State & Actions>()(
  immer((set) => ({
    shape: { type: 'Circle', model: Shape.Circle.init() },
    dispatch: (msg) => set((state) => {
      state.shape = Shape.update(msg, state.shape)   // pure call, immer captures the diff
    }),
  }))
)
```

Side effects (history, persistence, API sync) wrap the dispatch in the store layer — they never leak into `Shape.update`. The same module would plug into `useReducer` unchanged:

```typescript
const [shape, dispatch] = useReducer(Shape.update, { type: 'Circle', model: Shape.Circle.init() })
```

This separation is the architectural payoff: the business logic is framework-free, fully unit-testable as pure functions, and survives any state-library migration.

## When to reach for this

- A domain with multiple variants that share an interface but diverge in detail.
- Code being ported from Elm, PureScript, or a Redux app heavy on reducers.
- A team wanting to write business logic in pure functions and decide on the React glue separately.

Skip it for: simple stateful UI, forms, one-off components — the ceremony costs more than the modularity buys. The Zustand-with-named-actions style in `composition-patterns` is lower overhead and usually a better default.

