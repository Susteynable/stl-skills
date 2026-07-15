# Track N - Setup And Rebuild

Read:

- `../topics/setup-process.md`
- `../topics/aggregate-json-serialization.md`
- `../case-studies/jackson-serialization-stey-crs-refactor.md`

Checklist:

- [ ] Every `Setup*` command has handler and dispatcher wiring.
- [ ] Every `Setup*` event has an event handler branch.
- [ ] Setup events bulk replace state slices.
- [ ] Processor no-ops setup events during rebuild.
- [ ] `SetupDummyEvent` no-ops everywhere.
- [ ] Journal re-seed payload uses `JsonSerialization.toCompactString(SetupDummyEvent(...))`.
- [ ] Rebuild engine commands/events match the current setup shape.
- [ ] Setup nested ADTs live on `Setup*AddEvent` companions (SteyCrs pattern); avoid separate bulk setup command tiers when Add events can carry the snapshot shape.
- [ ] Rebuild remaps table/entity ADTs to state/setup inline; no shared `*FromTable` or `*Remap` helper objects.
