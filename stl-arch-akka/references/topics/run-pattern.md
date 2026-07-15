# Run pattern (post-persist side effects)

Runs are imperative side effects executed **after** events are persisted (or immediately when there are no events). They must not write to the journal or projections.

Reference implementation: `stey-cms-impl/.../aggregates/property/`.

## SteyCrm dual aggregates

Both CRM aggregates use the same layout (mirror each other):

| Piece | CRM (`com.stey.crm.impl.aggregates`) | Survey (`...aggregates.survey`) |
|-------|--------------------------------------|----------------------------------|
| ADT | `Run.scala` | `survey/Run.scala` |
| Dispatcher | `RunDispatcher.scala` | `survey/RunDispatcher.scala` |
| Handler | `runhandlers/RunHandler.scala` | `survey/runhandlers/RunHandler.scala` |
| Interceptor | `CrmCommandResultSupport.ResultWithRunSupport` | `SurveyCommandResultSupport.ResultWithRunSupport` |
| Wiring | `Aggregate.apply(..., steyCrmConfig)` + `Behaviors.setup` | same |

`Aggregate.start(steyCrmConfig)` is required in `ApplicationLoader` for both shards.

## Setup mode wiring

In `Aggregate.apply(persistenceId, projectionTag, steyCrmConfig)`:

```scala
Behaviors.setup { _ =>
  implicit val runDispatcher: RunDispatcher = steyCrmConfig.setupMode match {
    case SetupModes.Off => DefaultRunDispatcher(EntityId(...))
    case _              => NoOpsRunDispatcher()
  }
  implicit val runHandler: RunHandler = steyCrmConfig.setupMode match {
    case SetupModes.Off => DefaultRunHandler(EntityId(...))
    case _              => NoOpsRunHandler()
  }
  EventSourcedBehavior.withEnforcedReplies(...)
}
```

- **`off`**: real dispatch/handle (may be no-op `match` until concrete runs exist).
- **`init`**, **`rebuild_aggregate`**, **`migration`**: no-ops so setup/rebuild does not trigger production side effects.

Tests: pass `SteyCrmConfig(..., setupMode = SetupModes.Init, ...)` into `Aggregate(persistenceId, tag, steyCrmConfig)` so `EventSourcedBehaviorTestKit` gets no-op run wiring.

## Command handler shape

**Without runs** (current majority):

```scala
for { ... } yield (events, Done)
result.intercept(state, by).reply(replyTo)  // ResultSupport
```

**With runs**:

```scala
for { ... } yield (events, Seq(MyNotificationRun(...)), Done)
result.intercept(state, by).reply(replyTo)  // ResultWithRunSupport; implicit RunHandler
```

## Single-file vs. Split run patterns

Depending on the size of the aggregate, runs can be organized in two ways:

1. **Single-file (Legacy/Small aggregates)**:
   - Base `sealed trait Run` and all concrete subclass `case class`es are defined in a single `Run.scala` file at the aggregate root.
   - All handlers are wired or defined in `runhandlers/RunHandler.scala`.

2. **Split Colocated (Large/Standard aggregates - e.g., SteyCrs)**:
   - The base `trait Run` lives in `aggregate/runhandler/Run.scala` (not `sealed` to allow sub-classing in other files).
   - Each concrete `Run` case class (and companion object) is colocated with its corresponding `RunHandler` in a file named after the run (e.g. `ReservationCancellationSendNotificationRun.scala` under `aggregate/runhandler/`).
   - The base `RunHandler[R <: Run]` trait remains in `aggregate/runhandler/RunHandler.scala`.
   - `RunDispatcher.scala` remains at the aggregate root level, importing `runhandler._`.

Add concrete `Run` case classes either to `Run.scala` (single-file style) or split colocated with their handlers (split style), route in `DefaultRunHandler` / `DefaultRunDispatcher`, and keep side effects out of command handlers and `Processor`.

## Checklist (per aggregate)

1. `RunDispatcher.scala` present at aggregate root (or `survey/`).
2. Run structure:
   - For single-file: `Run.scala` at aggregate root, `runhandler/RunHandler.scala` handles all runs.
   - For split: `runhandler/Run.scala` (base trait) and `runhandler/RunHandler.scala` (base handler trait) present, with each concrete run class colocated with its handler in `runhandler/RunName.scala`.
3. `*CommandResultSupport` defines both `ResultSupport` and `ResultWithRunSupport` in the interceptor file.
4. `Aggregate` returns `Behavior[Command]` from `Behaviors.setup` with implicits for `RunDispatcher` and `RunHandler`.
5. `start(steyCrmConfig)` used from application bootstrap.
6. Each new `Run` type handled in `DefaultRunHandler.handle` and `DefaultRunDispatcher.dispatch`.
7. No journal/projection writes inside run handlers.
