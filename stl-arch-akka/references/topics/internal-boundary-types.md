# Internal boundary types

Use when defining service/consumer input types for `class *Internal`.

## Full tier isolation (required)

The internal tier is **fully isolated** from command, event, state, and table ADTs on its **public API** (method parameters and return types on `class *Internal`).

| Allowed on `class *Internal` | Forbidden on `class *Internal` |
|------------------------------|--------------------------------|
| `*Internal.*` models from the matching companion | `State.*`, `Command.*`, `Event.*`, `*Table.*` as parameter or return types |
| Shared primitives (`UUID`, `LocalDate`, `I18nText`, `Code`, …) | `import aggregate.state.*` or `import …State._` |
| `impl.enums.*` | cross-tier `type Foo = OtherTier.Foo` aliases |
| Constructing `Command.*` **inside** the method body for `askWithStatus` | wildcard imports that pull another tier's nested ADTs into scope |

Each `*Internal.scala` file defines its write-path shapes on **`object *Internal`** only:

```text
aggregate/internal/ConfigInternal.scala
├── class ConfigInternal(...)     # orchestration only
└── object ConfigInternal         # ALL write-path input ADTs for this domain
    ├── sealed trait RatePlanAdjustment
    ├── final case class Season(...)
    ├── sealed trait RatePlanBreakfastRule
    └── ...
```

**Delegate / consumer** builds `ConfigInternal.Season`, not `ConfigState.RatePlanSeason`. **Class** remaps `ConfigInternal.*` → `Command.*` inline at the `askWithStatus` call site.

Duplicating the same conceptual shape on internal + command + state + table is intentional. Do not reuse `ConfigState.RatePlanSeason` (or any other tier's ADT) as an internal method parameter to avoid duplication.

Gate: `audit_internal_no_cross_tier.sh` (forbidden `aggregate.state` imports under `aggregate/internal/`).

## Core rule

- `object *Internal` owns write-path internal models.
- They are not persisted as a unit.
- They are not table-column storage models.

For storage models, use `entity-table-json-types.md`.

## Placement

```text
aggregate/internal/FooInternal.scala
├── class FooInternal(...)   # orchestration, askWithStatus, pre-checks
└── object FooInternal       # internal models only
```

## Internal model test

Put a case class on `object *Internal` only if all are true:

1. it is built before calling `class *Internal`
2. it is remapped inline to `Command.*`
3. it is not stored as one table row or JSON column shape

## Not internal models

| Shape | Correct home |
|-------|--------------|
| stored JSON / TEXT column tree | `object *Table` in `entity/` |
| type+key column ADT | `object *Table` |
| command/event/state shape | owning onion tier |
| shared aggregate type under `impl.models` | remove and split by tier |

## Write path

```text
proto / consumer data -> *Internal.<Model> -> class *Internal -> Command.* -> Event.* -> State.* -> Processor
```

Service code should not pass `Command.*`, `State.*`, or `*Table.*` into public `class *Internal` methods.

## Remap rules

- Service/consumer -> `*Internal.<Model>` inline
- `*Internal.<Model>` -> `Command.*` inline inside `class *Internal`
- No private `toXxx` / `fromXxx` remap helpers across tiers
- Internal models must not use `Command.*` types as their field types

Same-boundary reuse between internal models is fine when it stays inside the internal boundary.

## Decision rule

| If the type is... | Home |
|-------------------|------|
| built only before `askWithStatus` | `object *Internal` |
| stored in that table's columns | `object *Table` |
| used only after command acceptance | Command / Event / State |

Matching entity fields do not make it a table model.

## Anti-patterns

- write DTOs on `object *Table`
- table models on `object *Internal`
- **`import com.stey.*.impl.aggregate.state.*` or `import …ConfigState._` in `aggregate/internal/`**
- **public `class *Internal` methods taking `ConfigState.RatePlanSeason`, `ReservationState.*`, `Command.*`, or `*Table.*` as parameters**
- spray, Jackson, `readDbString` / `writeDbString`, or Slick column mappers on `object *Internal`
- `impl.models` imports on the write path
- service code skipping the internal boundary and constructing command types directly at the delegate (delegate must build `*Internal.*` first)
- cross-tier `toXxx` helpers inside `class *Internal`
- placing `*Internal.scala` under plural `internals/` instead of `aggregate/internal/`

## Checklist

- [ ] case class lives on `object *Internal` under `aggregate/internal/`
- [ ] public `class *Internal` method takes `*Internal.<Model>`
- [ ] service/consumer builds the internal model inline
- [ ] remap to `Command.*` stays inline inside `class *Internal`
- [ ] no duplicate shape was added to `object *Table` unless it is truly persisted there
- [ ] no spray, Jackson, or DB-string serializers on `object *Internal`
