# Track A - API Contracts

Read:

- `../topics/api-protobuf-pattern.md`

Checklist:

- [ ] No `api/grpc/models/*.proto` domain files for aggregate shapes.
- [ ] RPC request and response protos define nested messages per use case.
- [ ] Outbound event protos define nested messages per event.
- [ ] Proto contracts do not expose aggregate `Command`, `Event`, `State`, `Entity`, or table companion types.
- [ ] Mapping between proto and application/internal models is explicit and inline at service boundaries; no private `toGrpc`/`toInternal`/`toXxx` helpers across tiers.
