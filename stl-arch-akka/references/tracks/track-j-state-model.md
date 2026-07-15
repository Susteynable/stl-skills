# Track J - State Model

Read:

- `../topics/onion-model.md`
- `../topics/onion-boundary-rules.md`
- `../topics/aggregate-json-serialization.md`
- `../topics/display-only-tags-and-logs.md`

Checklist:

- [ ] State slices live under `state/`.
- [ ] State does not use shared domain aliases or `package.scala` aliases.
- [ ] State does not import command, event, entity, table, internal, or shared model types.
- [ ] State uses Jackson-compatible schema evolution such as `@JsonCreator` when needed.
- [ ] State has no spray `RootJsonFormat`, `jsonFormatN`, or aggregate-tier spray imports.
- [ ] Each state nested ADT is owned by its state companion; event/command tiers redefine equivalent shapes and remap inline.
- [ ] Business-critical facts use dedicated state fields/flags; tags are display/search only and must not be the sole source of truth (see `../topics/display-only-tags-and-logs.md`).
