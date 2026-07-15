# Track C - Application/Internal Services

Read:

- `../topics/internal-boundary-types.md`
- `../topics/onion-model.md`
- `../topics/onion-boundary-rules.md`

Checklist:

- [ ] Write-path DTOs live on `object *Internal` in `aggregate/internal/*Internal.scala` (one companion per domain file).
- [ ] Each duplicated conceptual shape is redefined on `object *Internal` — no `import …State._` or state ADT method parameters.
- [ ] `aggregate/internal/` has no imports from `aggregate.state` (`audit_internal_no_cross_tier.sh`).
- [ ] `object *Internal` companions have no spray, Jackson, or DB-string serializers.
- [ ] Delegates / consumers map request nested proto types to `*Internal.*` inline before calling `class *Internal`.
- [ ] Public methods on `class *Internal` take `*Internal.*` (+ primitives / enums), not command/state/event/table types as parameters or return types.
- [ ] Command types appear only inside method bodies when building `askWithStatus` payloads.
- [ ] Services do not build table companion types for write RPCs.
- [ ] No shared `impl.models` package is imported into write-path code.
- [ ] Remapping is inline and explicit; no mapper package, shared mapping object, or private `toXxx`/`fromXxx` helpers across tiers.
