# Track H - Event Model

Read:

- `../topics/onion-model.md`
- `../topics/onion-boundary-rules.md`
- `../topics/aggregate-json-serialization.md`

Checklist:

- [ ] Event-layer nested types live on the event companion that owns them.
- [ ] Same conceptual shapes are redefined per event when needed; no cross-tier aliases and no references to another event's nested ADTs.
- [ ] Events extend the aggregate `JsonSerializable` marker where required.
- [ ] Events do not import command, table, state, entity, or shared `impl.models` types.
- [ ] Setup event shapes match setup command and rebuild requirements; prefer nested ADTs on `Setup*AddEvent` companions.
- [ ] Parent `Event` trait is **unsealed**; one event case class per file under `event/` with colocated `*EventHandler`.
- [ ] Event sealed **nested** ADTs use `@JsonTypeInfo(use = JsonTypeInfo.Id.NAME)` plus `@JsonSubTypes`; no spray formats.
