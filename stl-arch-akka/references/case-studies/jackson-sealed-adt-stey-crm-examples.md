# SteyCrm examples (#24793 / #24795)

Concrete locations in `SteyCrm` (`stey-crm-impl`) after the LeadFollowUp / SurveyReward Jackson fix.

## Binding

`stey-crm-impl/src/main/resources/application.conf`:

```hocon
serialization-bindings {
  "com.stey.crm.impl.JsonSerializable" = jackson-json
}
```

## Preferred sealed ADT shape

**Event / State** (journal-persisted):

```scala
@JsonSubTypes(Array(
  new JsonSubTypes.Type(value = classOf[LeadFollowUp.CommunicationRecord], name = "communication_record")
))
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.PROPERTY, property = "_type")
sealed trait LeadFollowUp extends Product with Serializable

object LeadFollowUp {
  final case class CommunicationRecord(...) extends LeadFollowUp
}
```

**Command** (cluster transport only — see SteyCrs `Command.scala`):

```scala
@JsonSubTypes(Array(
  new JsonSubTypes.Type(value = classOf[RatePlanAdjustment.Fixed], name = "fixed")
))
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.PROPERTY, property = "_type")
sealed trait RatePlanAdjustment extends Product with Serializable

object RatePlanAdjustment {
  final case class Fixed(...) extends RatePlanAdjustment
}
```

Prefer trait-level `@JsonSubTypes` registration for aggregate sealed ADTs, including nested shapes.

## Events — `aggregates/Event.scala`

| Event | Field | Status |
|-------|-------|--------|
| `SetupLeadAddEvent` | `leadFollowUps` | Reference implementation |
| `LeadTransferInEvent` | `leadFollowUps` | Fixed (#24795) |
| `LeadUndoConvertEvent` | `leadFollowUps` | Fixed (#24795) |
| `LeadFollowUpCreateEvent` | `leadFollowUp` | Already OK |
| `LeadFollowUpUpdateEvent` | `leadFollowUp` | Already OK |
| `LeadCreateEvent` | no `leadFollowUps` map | N/A |

## Commands — `aggregates/Command.scala`

| Command | Field | Status |
|---------|-------|--------|
| `SetupLeadAdd` | `leadFollowUps` | Reference |
| `LeadTransferIn` | `leadFollowUps` | Fixed (#24795) |
| `LeadUndoConvert` | `leadFollowUps` | Fixed (#24795) |

## Survey — `aggregates/survey/Command.scala`

| Command | Field | Status |
|---------|-------|--------|
| `SetupSurvey` | `surveyReward` | Reference |
| `SurveyCreate` | `surveyReward` | Fixed (#24795) |
| `SurveyUpdate` | `surveyReward` | Fixed (#24795) |

Survey **events** in `aggregates/survey/Event.scala` already had `SurveyReward` Jackson on all four setup/lifecycle events.

## State / DB (already OK)

- `aggregates/state/State.scala` — `Lead.LeadFollowUp`
- `entities/SteyCrmLeadFollowUpTable.scala`
- `entities/SteyCrmSurveyTable.scala`

## Related commit messages

- `fix: use singular English price units in lead quotation (#24793)` — unrelated HTML; same release train.
- `fix: add Jackson serializers for LeadFollowUp and SurveyReward (#24795)`

## Aggregate rebuild

`actors/setupmanager/aggregaterebuild/AggregateRebuildEngine.scala` issues `SetupLeadAdd` with full Jackson ADT—transfer/undo paths emit `LeadTransferInEvent` / `LeadUndoConvertEvent`, which required the event fix for journal replay after rebuild.
