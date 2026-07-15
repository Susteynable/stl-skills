# Track P - Kafka Consumers

Read:

- `../topics/kafka-projection-consumers.md`
- `../topics/kafka-consumer-template.md`
- `../topics/entity-table-constraints.md`

Checklist:

- [ ] Consumer `start()` and `SlickHandler` have no `ApmManager` / `ApmProbe`.
- [ ] Handler DBIO chains do not swallow errors through `cleanUp`.
- [ ] Event routing uses `ProtobufTypeUrl.parse(typeUrl) match`.
- [ ] Unknown events return `DBIO.successful(Done)` with debug logging.
- [ ] Projection remaps upstream events to entity rows inline.
- [ ] Projection insert/update follows audit column rules.
- [ ] Type URL parsing has a unit spec.
