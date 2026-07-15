# Onion boundary rules

These rules override older shared-types, mapper-object, and alias-heavy patterns.

## 1. Own types on the owning tier

| Tier | Type home |
|------|-----------|
| Command | each command companion in `Command.scala` |
| Event | each event companion in `Event.scala` |
| State | `state/**` |
| Internal write input | `object *Internal` |
| Storage JSON / column ADT | `object *Table` |

Do not introduce `commanddomain/*`, `eventdomain/*`, or shared aggregate type packages.

## 2. Remap inline only

See `inline-boundary-remap.md` for patterns, examples, and review greps.

Required at the owning call site:

- Service -> Internal inline
- Internal -> Command inline
- Command -> Event inline
- Event -> State inline
- Event -> table model inline (`Processor`)
- entity / table ADT -> response proto inline (delegates)
- Event -> outbound proto inline (`*EventProducer`)
- table / entity -> state or setup command inline (rebuild engine)

Forbidden:

- `*Mapping.scala`, `*Mappers.scala`, `AggregateRebuild*Remap`, or any shared cross-tier mapper object
- private/protected/local `*ToTable`, `*FromTable`, `toEntity`, `toTableModel`, or other cross-tier `toXxx` / `fromXxx`
- companion `to*Grpc`, `from*Grpc`, `optTo*Grpc`, `to*EventGrpc` on `object *Table` or state companions
- implicit aggregate-type conversions on shared models
- double conversion through an intermediate tier when a direct remap is possible (event -> table -> proto)

Allowed exceptions:

- enum <-> proto helpers on `impl.enums.*`
- infrastructure helpers with no onion-tier crossing
- same-tier helpers that do not remap one tier to another
- storage/domain methods on table companions (`columnMapper`, `getUnitPrice`, Jackson annotations, etc.)

Intentional duplication at 2–3 boundary call sites is correct. Do not reintroduce shared helpers to dedupe.

## 3. No cross-tier aliases

Forbidden:

- `type Foo = OtherTier.Foo`
- re-export `val` aliases for other-tier constants
- `package object models { type X = State... }`

Use explicit nested paths instead.

## 4. Aggregate and table serialization

- Command, Event, State, and Run use Akka Jackson only.
- No aggregate-tier spray `format`, `RootJsonFormat`, or `jsonFormatN`.
- `object *Internal` has no serializers (spray, Jackson, or DB-string codecs).
- Table JSON column ADTs use Jackson via shared `JsonSerialization` with colocated `@JsonTypeInfo` on `object *Table` (SteyCrs canonical). Legacy services may retain spray during migration.
- Each command/event/state/table companion owns its nested ADTs; do not reference another tier's nested type.
- See `aggregate-json-serialization.md` for the full serialization checklist and `../case-studies/jackson-serialization-stey-crs-refactor.md` for SteyCrs audit gates.

## 5. `impl.models`

- Do not import `impl.models._` on the write path.
- Legacy journal-FQN shims are acceptable only as thin replay bridges.
- Those shims must not reintroduce aliases or shared aggregate domain shapes.

## 6. Internal tier isolation

- Every write-path input ADT for a domain lives on **`object *Internal`** in `aggregate/internal/*Internal.scala`.
- **`class *Internal` public methods** take `*Internal.*` (plus shared primitives and `impl.enums.*`), never `State.*`, `Command.*`, `Event.*`, or `*Table.*` as parameters or return types.
- **`aggregate/internal/` must not import `aggregate.state`** (no `ConfigState._`, no `ReservationState.*` on the internal API). Command imports are allowed only to **construct** commands inside method bodies.
- Delegates and consumers remap proto / consumer payloads → `*Internal.*` inline; they do not pass state or command ADTs into internal.

See `internal-boundary-types.md` for placement, checklist, and examples.

## 7. Internal vs table models

| If the type is... | Home |
|-------------------|------|
| write-path input to `class *Internal` | `object *Internal` |
| data stored in that table's columns | `object *Table` |

Matching entity fields do not make something a table model.

## Review signals

Flag PRs that add or keep:

- `commanddomain/` or `eventdomain/`
- `*Mapping.scala`, `*Mappers.scala`, or `object *Remap`
- cross-tier `*ToTable`, `*FromTable`, `toXxx` / `fromXxx`, or companion `to*Grpc` / `from*Grpc`
- cross-tier `type` aliases
- aggregate spray formats on command/event/state
- table companion write DTOs or gRPC/event proto converters
- `impl.models` imports in command/event/state/internal/service write paths
- `import …aggregate.state` or `import …State._` under `aggregate/internal/`
- public `class *Internal` methods whose parameters use `State.*`, `Command.*`, or `*Table.*` ADTs (command construction inside the body is fine)
