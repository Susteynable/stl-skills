# Canonical aggregate folder layout

**Required layout for all new Stey Akka services** (SteyCrs reference):

```
impl/
├── aggregate/
│   ├── Aggregate.scala
│   ├── Command.scala          # unsealed parent trait only
│   ├── Event.scala            # unsealed parent trait only
│   ├── CommandDispatcher.scala
│   ├── EventDispatcher.scala
│   ├── RunDispatcher.scala    # when runs exist
│   ├── command/               # one command + handler per file
│   ├── event/                 # one event + handler per file
│   ├── interceptor/
│   ├── internal/              # *Internal.scala write-path orchestration
│   ├── processor/
│   ├── runhandler/            # when runs exist
│   └── state/
├── entity/                    # SteyCrs*Table.scala read models
├── surface/
│   ├── Stey*ServiceImpl.scala
│   └── delegate/
├── projection/consumer|producer/
├── actor/
└── implicits/                 # plural — exception to singular rule
```

When a service hosts multiple aggregates, use `aggregate/<AggregateName>/` with the same subfolder names inside each aggregate folder.

## At aggregate root

| File / concern | Role |
|----------------|------|
| `Aggregate.scala` | `EventSourcedBehavior` wiring only |
| `Command.scala`, `Event.scala` | **Unsealed** parent traits only (`extends JsonSerializable with Product`) |
| `*Exception.scala`, `*EntityId.scala` | As needed |
| `*CommandDispatcher.scala` | **Routing only**: `dispatch` → handlers under `command/` |
| `*EventDispatcher.scala` | **Routing only**: `dispatch` → handlers under `event/` |
| `*Run.scala` (or `runhandler/Run.scala` if split) + `*RunDispatcher.scala` | **Only if** post-persist runs |

Command and event **case classes** live one per file under `command/` and `event/` with colocated handlers. Do **not** seal the parent `Command` / `Event` traits (Scala 2.13 file split); enforce coverage with `audit_command_dispatcher_coverage.sh` and `audit_event_handler_coverage.sh`.

## Subfolders

| Subfolder | Contents | Must **not** contain |
|-----------|----------|----------------------|
| `state/` | `*State.scala` (`object State` tree only) | Dispatchers, handlers, `impl.models._` |
| `command/` | Command ADTs + colocated `*CommandHandler` (one file per command), plus `CommandHandler.scala` | `*CommandDispatcher`; state/entity imports |
| `event/` | Event ADTs + colocated `*EventHandler` (one file per event), plus `EventHandler.scala` | `*EventDispatcher`; state ADT references |
| `interceptor/` | `*EventInterceptor.scala` + `*CommandResultSupport` **same file** | Separate `support/*CommandResultSupport.scala` |
| `internal/` | `class *Internal` + `object *Internal` write-path models | Serializers, gRPC imports |
| `runhandler/` | Colocated `*Run` + handler when split; base `Run.scala` / `RunHandler.scala` | `*RunDispatcher` |

## Omit

- Plural legacy folders: `aggregates/`, `entities/`, `internals/`, `surfaces/delegates/`, `commandhandlers/`, `eventhandlers/`
- Root monolithic `*CommandHandler.scala` / `*EventHandler.scala` once `command/` and `event/` own handlers
- `package.scala` re-exporting `type XState = state.XState` — use `import ...state.State`
- `support/` only for `CommandResultSupport` — belongs in `interceptor/`
- `mappers/` or `impl/models` shared across tiers
- `aggregate/README.md` or `aggregates/README.md` — use repo-root `AGENTS.md` + `stl-arch-akka` instead

Aggregates **without** runs: omit `Run.scala` / `runhandler/` / `RunDispatcher.scala`.

## Documentation

Do **not** add architecture README files under `aggregate/` or `aggregates/`. Document tier boundaries, serialization, inline remap, setup/rebuild, and audit scripts in:

- repo-root `AGENTS.md` (service-specific commands and gates)
- `stl-arch-akka` skill (canonical Stey Akka patterns and tracks A–Q)

## Behavioral placement

| Component | Responsibility |
|-----------|----------------|
| Command handlers | Validate; `Command.*` → `Event.*` inline; optional runs → `intercept(...).reply(replyTo)` |
| Event dispatcher | Root event routing only: `Event` → concrete per-event handler |
| Event handler | `Event.*` → `State.*` inline only, colocated under `event/` |
| Processor | `Event.*` → entity row inline; not `State` |
| Producer | `Event.*` → nested outbound event proto inline |
| Surface delegate | Write: proto → `Internal.*`; read: entity → response proto inline |
