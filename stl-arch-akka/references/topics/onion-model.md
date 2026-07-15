# Onion domain model

Use for write-side aggregates with gRPC surfaces and Slick-backed read models.

## Layer map

| # | Layer | Where types live | Boundary owner |
|---|-------|------------------|----------------|
| 1 | API | Nested proto per RPC or outbound event | Surface delegate / Producer |
| 2 | Internal | `object *Internal` in `aggregate/internal/*Internal.scala` | `*ServiceImpl`, consumers, actors |
| 3 | Command | Per-command file under `aggregate/command/` | `class *Internal` |
| 4 | Command handler | Colocated in `aggregate/command/` | command handler object |
| 5 | Event | Per-event file under `aggregate/event/` | command handlers |
| 6 | State | `aggregate/state/**` | colocated `*EventHandler` via `EventDispatcher` |
| 7 | Entity / table | `entity/*Table.scala` | `Processor`, surface read path |
| 8 | Producer | Nested outbound proto messages | `*EventProducer` |

Allowed shared primitives only: `I18nText`, `RelativeFile`, `I18nRelativeFile`, `UUID`, `Instant`, `Code`, and `impl.enums.*`.

## Ownership rules

- Redefine the same conceptual shape per tier: `Internal.Address`, `Command.Address`, `Event.Address`, `State.Address`, response-proto `Address`.
- `object *Internal` holds write-path input models only.
- `object *Table` holds storage-only table models only.
- `object *Repository` holds `rows` only.
- Parent `Command` / `Event` traits are **unsealed**; nested ADTs on each command/event companion are sealed when polymorphic.
- Aggregate `Command`, `Event`, `State`, and `Internal` must not import shared aggregate shapes from `impl.models`.

## Boundary rules

### Required

- Remap field-by-field at the owning boundary.
- Keep command/event/state nested types on the owning companion.
- Keep surface read mapping inline from entity to that RPC's response proto.
- Keep Producer mapping inline from Event to that outbound proto.

### Forbidden

- `*Mapping.scala`, `*Mappers.scala`, mapper packages, or shared remap helper objects
- private `*ToTable`, `*FromTable`, `toXxx` / `fromXxx`, or companion `to*Grpc` / `from*Grpc` across onion tiers
- cross-tier type aliases or re-export vals
- `commanddomain/` or `eventdomain/` packages
- shared `api/grpc/models/*.proto` for aggregate shapes
- `State.*` used in Processor writes
- table or entity models used in write-path services

See `inline-boundary-remap.md` for call-site patterns and review greps.

## Write path

```text
RPC proto -> *Internal.* -> Command.* -> Event.* -> State.* -> *Table.* -> outbound proto
```

Every boundary remap is inline where the arrow happens.

## Read path

```text
Entity (+ table companion JSON types) -> this RPC's response proto
```

Not from `State`, not from `impl.models`, not from shared API model protos.

## Companion placement

| Companion | Holds |
|-----------|-------|
| `object *Internal` | write-path internal models |
| command companion (`aggregate/command/*.scala`) | command-layer nested types |
| event companion (`aggregate/event/*.scala`) | event-layer nested types |
| state object / nested objects | state-layer nested types |
| `object *Table` | JSON column and storage ADTs |

## Command Companion Formatting & Ordering

When defining companion objects for command models (`aggregate/command/*.scala`):
- **No Blank Lines before Companions:** Neither traits nor main case classes should have blank lines before their companion objects.
- **Internal Ordering:**
  1. **ADT Models:** Defined first (traits then normal classes). If a trait has a companion object, it must follow the trait definition with no blank line in between.
  2. **Exception Definition:** Follows the ADT models. The base exception (extending `AggregateException`) must be immediately followed by concrete subclass/object definitions with no blank lines in between (double newlines removed).
  3. **Reply:** The `Reply` case class/object (if any) is defined at the very end.

## Checklist

- [ ] Nested types live on the owning tier companion.
- [ ] Same conceptual shapes are duplicated per tier when needed.
- [ ] Boundary remaps are inline and explicit.
- [ ] No mapper package or cross-tier `toXxx` helper exists.
- [ ] Package segments are singular (`aggregate/`, `entity/`, `surface/delegate/`).
- [ ] Command companion formatting and ordering rules are followed.
