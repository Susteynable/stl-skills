# Track L - Producer And Integrations

Read:

- `../topics/api-protobuf-pattern.md`
- `../topics/onion-model.md`
- `../topics/inline-boundary-remap.md`

Checklist:

- [ ] Outbound producers map Event to nested event proto types inline in the producer `match`; no `*Mappers` objects, table-companion `toEventGrpc`, or other shared cross-tier helpers.
- [ ] Producer remaps go directly event ADT → outbound proto; avoid event → table → proto double conversion.
- [ ] Producers do not import aggregate `State`.
- [ ] Producers no-op setup events where applicable.
- [ ] Integration boundaries do not expose table, state, command, or shared domain types.
- [ ] Producer proto type names match the event contract files.
