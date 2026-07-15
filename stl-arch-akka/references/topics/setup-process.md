# Setup process

Use when auditing or changing init, rebuild, or aggregate re-hydration from the read model.

Setup is cross-cutting: command -> event -> event handler -> processor. Missing one layer breaks rebuild.

## Lifecycle

```text
read DB snapshot -> Setup* command -> Setup* event -> EventHandler state update
                                               -> Processor no-op during rebuild
journal truncate -> SetupDummyEvent re-seed
```

## Coverage checklist

### Commands and dispatch

- [ ] Every `Setup*` command has a dedicated handler.
- [ ] Handler is wired in `*CommandDispatcher`.
- [ ] Handler maps command companion -> event companion inline.
- [ ] Handler does not write Slick tables or mutate `State`.
- [ ] Handler replies through `intercept(...).reply(...)`.

### Events and state

- [ ] Every `Setup*` event has an `*EventHandler.onEvent` branch.
- [ ] Bulk setup replaces full slices instead of merging stale data.
- [ ] Re-running setup overwrites prior nested maps.
- [ ] `SetupDummyEvent` is a state no-op.
- [ ] Legacy granular setup branches remain only if old journals still replay them.

### SetupDummyEvent and truncate

- [ ] `SetupDummyEvent` is minimal (`by`, `at` only).
- [ ] Aggregate events do not expose spray formats for dummy-event storage.
- [ ] Dummy payload uses `JsonSerialization.toCompactString(...)`.
- [ ] Re-seed uses the correct `event_ser_manifest` FQN.
- [ ] Aggregate key prefix matches the truncate branch.

### Processor

- [ ] Every persisted setup event has an explicit processor case.
- [ ] Setup events no-op during rebuild when the read side is already the source of truth.
- [ ] No catch-all skip branch hides missing setup cases.
- [ ] Secondary projections also no-op setup and dummy events where needed.

### Rebuild engine

- [ ] Rebuild reads a complete snapshot from DB.
- [ ] Rebuild emits the current setup command shape, not deprecated granular shapes.
- [ ] Table/entity → state or setup command remaps are inline in rebuild code; no shared `*FromTable` or `*Remap` objects.
- [ ] `mapAsync` parallelism is deliberate.
- [ ] No-op run wiring is active in setup modes.

### Producers and tests

- [ ] Producers skip or no-op setup events unless product explicitly needs them.
- [ ] Tests cover setup success, overwrite-not-merge behavior, dummy-event replay no-op, and Jackson round-trip.

## Optimization rules

- Prefer one bulk setup event per aggregate instance when replaying full snapshots.
- Colocate setup nested ADTs on `Setup*AddEvent` companions instead of maintaining parallel bulk setup command ADT trees (SteyCrs pattern).
- Keep `SetupDummyEvent` tiny.
- During rebuild, processor behavior should be explicit no-op rather than double-writing.
- Use granular setup events only for legacy journal compatibility or very high-cardinality cases.
- If a single setup payload approaches ~0.5-1 MB, review snapshot frequency, binding choice, or split strategy.

## Mode expectations

| Mode | Journal | Read side | Aggregate |
|------|---------|-----------|-----------|
| `Off` | normal append | normal projection | normal |
| `Init` | truncate + dummy | seed tasks | empty start |
| `RebuildAggregate` | truncate + dummy | unchanged source | replay setup commands |
| `Migrate` | truncate + dummy | migration-specific | migration-specific |

Do not mix init seeding logic into rebuild handlers.

## Anti-patterns

- rebuild emitting granular setup when a bulk event exists
- missing processor case for setup events
- setup handler writing read tables
- `EventHandler` merging maps when bulk setup should replace
- huge setup event without retention or snapshot consideration
