# Aggregate architecture templates

Canonical code shape only. Layout rules live in `folder-layout.md`. Onion ownership and remap rules live in `onion-model.md` and `onion-boundary-rules.md`.

## Parent traits (unsealed)

```scala
// aggregate/Command.scala
package com.stey.crs.impl.aggregate.command

import com.stey.crs.impl.JsonSerializable

trait Command extends JsonSerializable with Product

// aggregate/Event.scala
package com.stey.crs.impl.aggregate.event

import com.stey.crs.impl.JsonSerializable

trait Event extends JsonSerializable with Product with Serializable
```

Do **not** seal `Command` or `Event`. Add one case class per file under `command/` and `event/`; enforce dispatcher coverage with audit scripts.

## Command and Command Handler (colocated)

```scala
package com.stey.crs.impl.aggregate.command

import akka.Done
import akka.actor.typed.ActorRef
import akka.pattern.StatusReply
import com.stey.crs.impl.aggregate.AggregateException
import java.time.Instant
import java.util.UUID
import akka.persistence.typed.scaladsl.ReplyEffect
import com.stey.crs.impl.aggregate.RunDispatcher
import com.stey.crs.impl.aggregate.event._
import com.stey.crs.impl.aggregate.interceptor.EventInterceptor.ResultSupport
import com.stey.crs.impl.aggregate.state.State

final case class NewDomainCommand(
    id: UUID,
    by: UUID,
    replyTo: ActorRef[StatusReply[Done]]
) extends Command

object NewDomainCommand {
  sealed abstract class Exception(message: String) extends AggregateException(message)
  final case class NotFound(id: UUID) extends Exception("NotFound id [%s]".format(id.toString))
  final case class Invalid(id: UUID) extends Exception("Invalid id [%s]".format(id.toString))
}

object NewDomainCommandHandler extends CommandHandler[NewDomainCommand] {
  override def handle(state: State, command: NewDomainCommand)(implicit runDispatcher: RunDispatcher): ReplyEffect[Event, State] = {
    import state._
    val NewDomainCommand(id, by, replyTo) = command

    val result = for {
      current <- configState.someStateMap.get(id).toRight(NewDomainCommand.NotFound(id))
      _       <- Either.cond(current.isValid, (), NewDomainCommand.Invalid(id))
      event    = NewDomainEvent(id = id, by = by, at = Instant.now)
      runs     = Seq(NewRun(id))
    } yield (Seq(event), runs, Done)

    result.intercept(state = state, by = by).reply(replyTo)
  }
}
```

Rules: validate against `state`, build Event/Run inline, never write Slick tables or mutate `State`. Shared `CommandHandler` trait lives in `aggregate/command/CommandHandler.scala`.

## Event dispatcher and event handler

```scala
// aggregate/EventDispatcher.scala
object EventDispatcher {
  def dispatch(state: State, event: Event): State = event match {
    case event: NewDomainEvent =>
      NewDomainEventEventHandler.handle(state = state, event = event)
    case event: SetupDummyEvent =>
      SetupDummyEventEventHandler.handle(state = state, event = event)
    case unknown: Event =>
      throw new IllegalArgumentException(s"Unhandled event: ${unknown.getClass.getName}")
  }
}

// aggregate/event/EventHandler.scala
trait EventHandler[E <: Event] {
  def handle(state: State, event: E): State
}

// aggregate/event/NewDomainEvent.scala
object NewDomainEventEventHandler extends EventHandler[NewDomainEvent] {
  override def handle(state: State, event: NewDomainEvent): State = {
    val NewDomainEvent(id, _, _, _) = event
    state.focus(_.someStateMap).modify(_.updated(id, NewStateModel(...)))
  }
}
```

Rules: `EventDispatcher.dispatch` is the only aggregate-root event router; concrete handlers live in `aggregate/event/` and mutate `State` inline.

## Interceptor and runs

```scala
final class NewEventInterceptor(val state: State) extends EventInterceptor {
  override def intercept(events: Seq[Event], by: UUID): Either[AggregateException, Seq[Event]] =
    Right(events)
}

sealed trait Run extends Product with Serializable
final case class NewRun(id: UUID) extends Run

final class NewRunHandler extends RunHandler[NewRun] {
  override def handle(entityId: EntityId, state: State, run: NewRun): Unit = {
    // side effects only
  }
}
```

Rules: interceptors only validate/transform events; runs fire after persistence and never write journal or projections.

## Processor

```scala
override def process(envelope: EventEnvelope[Event]): DBIO[Done] =
  envelope.event match {
    case event: NewDomainEvent =>
      repository.rows.insertOrUpdate(
        Entity(
          id = event.id,
          createdBy = event.by,
          createdAt = event.at,
          updatedBy = event.by,
          updatedAt = event.at
        )
      ).map(_ => Done)

    case _: SetupEvent | SetupDummyEvent(_, _) =>
      DBIO.successful(Done)
  }
```

Rules: map Event -> read-model rows inline at each call site; no `*ToTable` or other shared cross-tier helpers. Setup events are explicit no-ops during rebuild. See `inline-boundary-remap.md`.

## Wiring

```scala
command match {
  case command: NewDomainCommand =>
    NewDomainCommandHandler.handle(state = state, command = command)
}

implicit val runDispatcher: RunDispatcher = config.setupMode match {
  case SetupModes.Off => DefaultRunDispatcher(entityId = entityId, newRunHandler = wire[NewRunHandler])
  case _              => wire[NoOpsRunDispatcher]
}
```

Rules: `CommandDispatcher` and `EventDispatcher` stay at aggregate root; run wiring switches by setup mode.

## `impl.enums` StringEnum

Allowed shared primitives across tiers. Copy-paste new enum files from `impl-enums-string-enum-template.md`. Rules: `../topics/impl-enums-string-enum.md`.
