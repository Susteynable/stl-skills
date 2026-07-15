# Track D - Command Model

Read:

- `../topics/onion-model.md`
- `../topics/onion-boundary-rules.md`
- `../topics/aggregate-json-serialization.md`

Checklist:

- [ ] Command-layer nested types live on the command companion that owns them.
- [ ] Same conceptual shapes are redefined per command when needed; no cross-tier aliases and no references to state/event ADTs.
- [ ] Command companion formatting and ordering rules are followed:
  - No blank lines before companion objects of main case classes or traits.
  - ADT models first (traits then normal classes; trait companion object follows trait with no blank line).
  - Exceptions next (concrete exceptions follow the base exception sequentially with no blank lines in between).
  - Reply at the very end.
- [ ] Commands extend the aggregate `JsonSerializable` marker where required by Akka serialization.
- [ ] Parent `Command` and `Event` traits are **unsealed** (`trait Command extends JsonSerializable with Product`); one command/event case class per file under `command/` and `event/`.
- [ ] Command sealed **nested** ADTs use `@JsonTypeInfo(use = JsonTypeInfo.Id.NAME)` plus `@JsonSubTypes` on the parent trait — omit `include` and `property` (see `../topics/jackson-sealed-adt-template.md`).
- [ ] `CommandDispatcher` coverage is enforced by `audit_command_dispatcher_coverage.sh` (every case class has a dispatcher case).
- [ ] Command models do not import entity, table, state, event, or shared `impl.models` types.
- [ ] Command companion objects have no spray formats; Jackson uses `_type` + `@JsonSubTypes` per Track O.
