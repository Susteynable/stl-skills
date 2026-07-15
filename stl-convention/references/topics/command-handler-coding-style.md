# Command handler coding style

Applies to command handlers, internal orchestration that returns `Either[AggregateException, ...]`, and any for-comprehension validation chain in Stey Akka services.

Architecture (dispatcher wiring, validate-from-state, no table/entity imports): **`stl-arch-akka`** Track E. This topic owns coding shape and snippets.

## Handler signature and dispatcher context

```scala
def handle(command: C)(implicit state: State, runDispatcher: RunDispatcher, system: ActorSystem[_]): ReplyEffect[Event, State]
```

- Parameter name: `runDispatcher` (not `runHandler`).
- Do not derive `ActorSystem` via `runDispatcher.system` inside handlers; receive it from `CommandDispatcher`.
- For non-trivial handlers, prefer `import state._` at the top of `handle` and use unqualified `configState`, `reservationState`, helpers, etc. Tiny handlers may keep `state.xxx`.

When a handler emits concrete events, bind each to a descriptively named val using the **actual event name**, then compose `events` with `+:` / `++`.

## Event composition: assign, then yield

Bind `events` in the comprehension body and `yield events` — do not inline `++` / `:+` chains in `yield`.

```scala
// Preferred
for {
  inventoryReleaseEvents <- wrapper.reservationRelease(...)
  roomUnAssignEvent = ReservationRoomUnAssignEvent(...)
  reAssignEvents       <- reservationRoomAssign(...)
  events = roomUnAssignEvent +: inventoryReleaseEvents ++ reAssignEvents
} yield events

// Avoid
for {
  ...
} yield Seq(roomUnAssignEvent) ++ inventoryReleaseEvents ++ reAssignEvents
```

Rules:

- Event vals use the actual event name (`roomUnAssignEvent`, `rateSetEvent`, …).
- Prefer `singleEvent +:` over `Seq(singleEvent) ++` when prepending one event.
- `yield events` or `yield (events, Done)` — never a multi-part `++` / `:+` chain in `yield`.
- Applies to nested comprehensions and private helpers returning `Either[..., Seq[Event]]`.

Out of scope: `yield inventoryRoomTypeEvents` when already a single named binding; tuple yields for non-event intermediates (`yield (date, events, dailyTotal)`).

## Helper functions

Private helpers that read aggregate state take `(implicit state: State)`, not an explicit `state: State` parameter. Call sites inside `handle` should not pass `state = state`. For `foldLeft` batch event handlers, re-bind `implicit val state: State = currentState` inside the fold before calling `applyRow`.

```scala
private def handleBlockStay(reservationGroupId: UUID, at: Instant, by: UUID)(implicit state: State): Either[AggregateException, Seq[Event]] = {
  import state._
  ...
}
```

Name helpers and locals for intent and domain type: `var-and-method-naming.md`.

## Prefer `Either.cond` over `if` / `else` for validation steps

```scala
// Preferred
_ <- Either.cond(
  configState.calendar.systemDate.isEqualOrBefore(command.checkInOn),
  (),
  HasReservation.InvalidCheckInDate(command.checkInOn)
)

// Avoid
_ <- if (configState.calendar.systemDate.isEqualOrBefore(command.checkInOn)) {
  Right(())
} else {
  Left(HasReservation.InvalidCheckInDate(command.checkInOn))
}
```

`Either.cond(test, right, left)` — use `()` as success for validation-only steps.

| Situation | Form |
|-----------|------|
| Boolean predicate | `Either.cond(predicate, success, error)` |
| Optional lookup (`Map.get`, `Option`) | `.toRight(Error(...))` |
| ADT / sealed branch with different payloads | `match { … }` |
| Multiple predicates | Separate `Either.cond` bindings (one per line) |

Do not replace meaningful `match` with nested `Either.cond` when branches carry different success payloads.

## For-comprehension shape

```scala
val result: Either[AggregateException, (Seq[Event], Seq[Run], Reply)] = for {
  import state._

  _ <- Right[AggregateException, Unit](())

  entity <- entities.get(id).toRight(MyCommand.NotFound(id))
  _      <- Either.cond(entity.isActive, (), MyCommand.Inactive(id))

  otherEvents <- loadRelatedEvents(entity.id)
  event = MyEvent(id = id, by = command.by, at = Instant.now)
  events = event +: otherEvents
} yield (events, Seq.empty, MyCommand.Reply(id))

result.intercept(state = state, by = command.by).reply(command.replyTo)
```

## Related

- Naming: `var-and-method-naming.md` · Companions: `command-companion-formatting.md` · Proto/response assign-then-yield: `delegate-coding-style.md` · Tags/logs: `stl-arch-akka` → `display-only-tags-and-logs.md`
