# Track I - Event Handling And State

Read:

- `../examples/aggregate-architecture-templates.md`
- `../topics/setup-process.md`

Checklist:

- [ ] `*EventDispatcher.dispatch` is the only aggregate-root event router.
- [ ] Each concrete event owns its colocated handler under `events/<EventName>.scala`, plus the shared `events/EventHandler.scala` base trait.
- [ ] Event-to-state mapping is inline and field-by-field; no private `toState`/`toXxx` helpers.
- [ ] Bulk setup events replace the relevant state slice rather than merging stale maps.
- [ ] `SetupDummyEvent` is a no-op on state.
- [ ] Event handling does not write projections or call Slick repositories.
- [ ] Event handling does not import table/entity/internal/shared model types.
