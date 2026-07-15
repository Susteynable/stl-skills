# Track Q - Tests And Documentation

Read:

- `../topics/test-akka-remoting-ports.md`
- `../topics/aggregate-json-serialization.md`
- `../topics/architecture-audit-scripts.md`
- `../case-studies/jackson-serialization-stey-crs-refactor.md`

Checklist:

- [ ] Handler specs use command-layer companions, not removed shared model types.
- [ ] Test aggregate config uses non-`Off` setup mode where run no-ops are required.
- [ ] Setup overwrite behavior has regression coverage.
- [ ] Serialization tests round-trip Command/Event/State through Jackson, not spray formats.
- [ ] Table JSON ADT tests use `TableJacksonSpec` (or equivalent) with `JsonSerialization`; aggregate specs do not import `impl.entity`.
- [ ] `InternalTierSpec` or `audit_internal_no_serialization.sh` gates serializer-free internal companions.
- [ ] Tier decoupling audits pass: `audit_command_no_state`, `audit_event_no_state` (ADTs only — handlers may use state), `audit_command_dispatcher_coverage`, `audit_event_handler_coverage`, `audit_internal_no_grpc`, `audit_internal_no_cross_tier`, `audit_internal_flat_params`, `audit_serialization_colocated`, `audit_missing_jackson`, `audit_serialization_spec_tiers`, `audit_state_no_entities`, `audit_producer_no_state`. See `../topics/architecture-audit-scripts.md`.
- [ ] Shared test `reference.conf` sets `akka.remote.artery.canonical.port = 0`.
- [ ] No per-spec Akka remoting `canonical.port` overrides exist under `src/test/**`.
- [ ] Repo-root `AGENTS.md` mirrors onion rules (see skill `SKILL.md` → Repo documentation) and points coding style at `stl-convention`; covers layers, remap, serialization, `impl.enums`, tags/logs, setup/rebuild, audits when applicable.
- [ ] No `aggregate/README.md` (or `aggregates/README.md`) exists; remove if present.
