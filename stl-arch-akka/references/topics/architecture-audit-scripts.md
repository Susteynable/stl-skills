# Architecture audit scripts

Shell gates for Stey Akka CQRS onion boundaries. Canonical copies live in the skill:

`stl-arch-akka/scripts/audit_*.sh`, `audit_lib.sh`, `audit.env.example`, `run_all_audits.sh`

Track **Q** (and serialization tracks **D, H, J, O**) reference these gates. SteyCrs case study: `../case-studies/jackson-serialization-stey-crs-refactor.md`.

## Adopt in a new repo

1. Copy from the skill into repo `scripts/`:
   - `audit_lib.sh`
   - `audit.env.example` → `audit.env` (edit paths)
   - all `audit_*.sh` and `run_all_audits.sh`
2. `chmod +x scripts/audit_*.sh scripts/audit_lib.sh scripts/run_all_audits.sh`
3. Set in `scripts/audit.env`:
   - `AUDIT_IMPL_MODULE` — e.g. `stey-foo-impl`
   - `AUDIT_IMPL_PKG_PATH` — e.g. `com/stey/foo/impl`
   - `AUDIT_GRPC_IMPORT`, `AUDIT_ENTITY_IMPORT`, `AUDIT_STATE_ADT_PATTERN` as needed
4. Document in repo-root `AGENTS.md`:

```bash
for s in scripts/audit_*.sh; do bash "$s"; done
# or
bash scripts/run_all_audits.sh
```

5. Wire into CI when the service uses the canonical aggregate layout.

Requires: `bash`, `rg` (ripgrep), `awk`, `find`, `grep`.

## Config (`audit.env`)

| Variable | Purpose |
|----------|---------|
| `AUDIT_IMPL_MODULE` | sbt impl module name |
| `AUDIT_IMPL_PKG_PATH` | package path under `src/main/scala` |
| `AUDIT_GRPC_IMPORT` | rg pattern — forbidden grpc API imports in `aggregate/internal` |
| `AUDIT_ENTITY_IMPORT` | rg pattern — forbidden entity imports in `aggregate/state` |
| `AUDIT_STATE_ADT_PATTERN` | rg pattern — state ADT refs forbidden on **command/event definitions** (handlers may use state) |
| `AUDIT_INTERNAL_STATE_IMPORT` | rg pattern — forbidden `aggregate.state` imports in `aggregate/internal` |
| `AUDIT_INTERNAL_FLAT_PARAM_PATTERN` | optional — internal methods must not take `request: FooInternal.*` wrappers |
| `AUDIT_SERIALIZATION_SPEC_DIR` | test dir for `StateJacksonSpec` / `EventJacksonSpec` / `TableJacksonSpec` |
| `AUDIT_FORBIDDEN_REL_PATHS` | space-separated paths under impl main (project-specific legacy files) |
| `AUDIT_STATE_SUBDIR_ALLOWLIST` | space-separated `subdir:Allowed.scala,Other.scala` extra-file gates |

Derived paths (do not set manually): `AUDIT_MAIN`, `AUDIT_AGGREGATE`, `AUDIT_COMMAND`, `AUDIT_EVENT`, `AUDIT_STATE`, `AUDIT_INTERNAL`, `AUDIT_PRODUCER`, `AUDIT_ENTITY`.

## Gate catalog

| Script | Tier / concern | Pass criteria |
|--------|----------------|---------------|
| `audit_command_no_state.sh` | Command model | Case class + command companion have no state ADT references; **handlers may** import/use state |
| `audit_event_no_state.sh` | Event model | Case class + event companion have no state ADT references; **handlers may** import/use state |
| `audit_command_dispatcher_coverage.sh` | Wiring | Every `final case class` in `command/` has `case command: Name` in `CommandDispatcher` |
| `audit_event_handler_coverage.sh` | Wiring | Every event case class appears in `EventDispatcher` |
| `audit_internal_no_grpc.sh` | Internal | No service grpc proto imports; no `fromRequest` / grpc `apply` on internal companions |
| `audit_internal_no_cross_tier.sh` | Internal | No `aggregate.state` imports; write-path ADTs belong on `object *Internal` |
| `audit_internal_no_serialization.sh` | Internal | No spray/Jackson/DB codecs on `*Internal` |
| `audit_internal_flat_params.sh` | Internal | Optional — no `request: *Internal.*` parameter objects when pattern set |
| `audit_missing_jackson.sh` | Serialization | Sealed ADTs in command/event/state/entity have Jackson; aggregate tier forbids `_type`/`name` polymorphism |
| `audit_serialization_colocated.sh` | Serialization | No central `serialization/` package; no aggregate Slick column mappers; optional forbidden paths |
| `audit_serialization_spec_tiers.sh` | Tests | State/Event specs do not import entity; `TableJacksonSpec` exists |
| `audit_state_no_entities.sh` | State | State tier does not import entity |
| `audit_producer_no_state.sh` | Producer | Producers do not import aggregate state |

## Command / event tier rule (2026-07)

Handlers validate or mutate **state** and often need state-owned types (`InventoryRoomTypeId`, `AvailabilityId`, etc.). The onion rule applies to **persisted/journal ADTs**:

- **Forbidden:** state ADT fields or references on `final case class … extends Command/Event` or nested types on the command/event companion (before `*CommandHandler` / `*EventHandler`).
- **Allowed:** imports and state ADT usage in colocated handlers only.

Audit implementation: take lines before `object *CommandHandler` / `object *EventHandler`, strip `import` lines, rg for `AUDIT_STATE_ADT_PATTERN`.

## Customization

- **Minimal service:** only set `AUDIT_IMPL_MODULE` + `AUDIT_IMPL_PKG_PATH`; leave optional vars empty to skip project-specific gates.
- **SteyCrs:** see `audit.env.example` in the skill (forbidden legacy files, reservation state allowlist, flat-param pattern).
- **Extend:** add `audit_custom_*.sh` in repo `scripts/`; keep using `audit_load_config` from `audit_lib.sh`.

## Related

- `jackson-sealed-adt-audit.md` — manual greps when replay fails
- `jackson-sealed-adt-template.md` — annotation pattern
- `onion-boundary-rules.md` — tier ownership rules the audits enforce
