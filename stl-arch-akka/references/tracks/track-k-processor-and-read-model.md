# Track K - Processor And Read Model

Read:

- `../examples/aggregate-architecture-templates.md`
- `../topics/inline-boundary-remap.md`
- `../topics/entity-table-constraints.md`
- `../topics/entity-table-json-types.md`
- `../topics/aggregate-json-serialization.md`
- `../topics/display-only-tags-and-logs.md`

Checklist:

- [ ] Processor maps Event to entity/table ADT inline at each insert/update site; no private `*ToTable`, `*FromTable`, `toEntity`, or other shared cross-tier helpers.
- [ ] Processor does not import aggregate `State`.
- [ ] Setup events are explicit no-ops during rebuild when applicable.
- [ ] Mutable entity inserts set `createdBy`, `createdAt`, `updatedBy`, and `updatedAt`.
- [ ] Mutable entity updates preserve `created*` and change only `updated*`.
- [ ] Log/audit projections that store event JSON use `JsonSerialization`, not `event.toJson`.
- [ ] Log/`*log` projections remain read/audit only; write-path services and handlers must not query them for business decisions (see `../topics/display-only-tags-and-logs.md`).
