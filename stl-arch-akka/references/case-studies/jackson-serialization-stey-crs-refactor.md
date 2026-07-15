# SteyCrs Jackson and tier-decoupling refactor (2026-06)

Reference for the `feature/rate-amount-basis-refactor` commit series in `SteyCrs`. Use with tracks **D, H, J, M, N, O, Q** and `../case-studies/grpc-surface-steycrs-case-study.md` (inline remap).

## Outcome

| Tier | Serializer | ADT home |
|------|------------|----------|
| Command / Event / State / Run | Akka Jackson (`JsonSerializable` binding) | owning companion in `Command.scala`, `Event.scala`, `state/**` |
| Internal write input | none | `object *Internal` in `aggregate/internal/*Internal.scala` |
| Table JSON columns | Jackson via `JsonSerialization.toJsonString` / `fromJsonString` | `object *Table` in `entity/*Table.scala` |
| Legacy admin / migration JSON | targeted legacy readers only | `admin/*LegacyJson` |

Spray-json was removed from `stey-crs-impl` main sources. Table column mappers and aggregate journal paths both use the shared Jackson mapper.

## Commit themes (newest first)

1. **Remove legacy spray-json; standardise on Jackson** — table companions, enums, and remaining bridges.
2. **Typed Jackson reservation values** — reservation state/event fields use native Jackson types instead of string-embedded JSON.
3. **Remove spray from aggregate state/event tiers** — `RootJsonFormat` gone; legacy journal replay via JsonNode deserializers only.
4. **Table ADTs Jackson-only; internal tier serializer-free** — `InternalTierSpec`, `audit_internal_no_serialization.sh`.
5. **Inline cross-layer ADT remaps** — removed `*ToTable`, `*FromTable`, companion `to*Grpc` helpers; explicit `match` at Processor, delegate, producer, rebuild call sites.
6. **Alphabetical ADT ordering** — `Command.scala`, `Event.scala`, `ConfigState`, `ReservationState`, `InventoryState` (organizational only).
7. **Eliminate cross-event ADT references** — e.g. `ReservationAddonItemUpdateEvent` owns its own `AddonItemUnitPriceFormula`, not `ReservationAddonItemAddEvent.*`.
8. **Annotation-based polymorphic Jackson** — parent trait `_type` + `@JsonSubTypes` on Command, Event, State, and table companions.
9. **Relocate map key codecs** — moved from ADT companions into `EventJacksonSpec` / `StateJacksonSpec`.
10. **Singleton deserializers for case objects** — `@JsonDeserialize(using = classOf[*.PredefinedJacksonDeserializer])` on table and aggregate case objects.
11. **Setup ADT colocation on Add events** — removed bulk `Setup*` commands/handlers; nested setup shapes live on `Setup*AddEvent` companions; rebuild emits Add events.

## Canonical patterns

### Aggregate tier (journal)

```scala
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME)
@JsonSubTypes(Array(
  new JsonSubTypes.Type(value = classOf[AddonItemUnitPriceFormula.Fixed]),
  new JsonSubTypes.Type(value = classOf[AddonItemUnitPriceFormula.Predefined.type])
))
sealed trait AddonItemUnitPriceFormula extends Product with Serializable

object AddonItemUnitPriceFormula {
  final case class Fixed(rate: BigDecimal, amountBasis: AmountBasis) extends AddonItemUnitPriceFormula

  final class PredefinedJacksonDeserializer extends JsonDeserializer[Predefined.type] {
    override def deserialize(parser: JsonParser, context: DeserializationContext): Predefined.type = Predefined
  }

  @JsonDeserialize(using = classOf[PredefinedJacksonDeserializer])
  final case object Predefined extends AddonItemUnitPriceFormula
}
```

Each event that needs the shape redefines it on its own companion (`ConfigAddonItemCreateEvent`, `ConfigAddonItemUpdateEvent`, `ReservationAddonItemAddEvent`, `ReservationAddonItemUpdateEvent`).

### Table tier (JSON columns)

Same `_type` + `@JsonSubTypes` on `object SteyCrs*Table`. Column mapper uses shared mapper only — no per-table `JacksonSerializer` class:

```scala
implicit def columnMapper(implicit profile: JdbcProfile): JdbcType[UnitPriceFormula] = {
  import profile.api._
  MappedColumnType.base[UnitPriceFormula, String](
    v => JsonSerialization.toJsonString(v),
    s => JsonSerialization.fromJsonString(s, classOf[UnitPriceFormula])
  )
}
```

### Internal tier

Pure case classes and sealed traits on `object *Internal`. No `spray.json`, `JacksonSerializer`, `readDbString`, or `writeDbString`.

### Inline remap (Processor)

```scala
unitPriceFormula = unitPriceFormula match {
  case ReservationAddonItemAddEvent.AddonItemUnitPriceFormula.Fixed(rate, amountBasis) =>
    SteyCrsReservationAddonItemTable.ReservationAddonItemUnitPriceFormula.Fixed(rate, amountBasis)
  case ReservationAddonItemAddEvent.AddonItemUnitPriceFormula.Predefined =>
    SteyCrsReservationAddonItemTable.ReservationAddonItemUnitPriceFormula.Predefined
}
```

## Verification (SteyCrs repo)

Run all gates:

```bash
bash scripts/run_all_audits.sh
# or
for s in scripts/audit_*.sh; do bash "$s"; done
```

Copy/adopt scripts from `stl-arch-akka/scripts/` — see `references/topics/architecture-audit-scripts.md`.

| Gate | Purpose |
|------|---------|
| `audit_command_no_state.sh` | command **ADTs** have no state references (handlers may use state) |
| `audit_event_no_state.sh` | event **ADTs** have no state references (handlers may use state) |
| `audit_command_dispatcher_coverage.sh` | every command case class has a dispatcher case |
| `audit_event_handler_coverage.sh` | every event case class has an event handler case |
| `audit_internal_no_serialization.sh` | internal companions have no serializers |
| `audit_internal_no_grpc.sh` | no gRPC imports in `aggregate/internal/` |
| `audit_internal_no_cross_tier.sh` | no `aggregate.state` imports in `aggregate/internal/` |
| `audit_internal_flat_params.sh` | flat params on internal methods |
| `audit_missing_jackson.sh` | sealed nested ADTs have Jackson annotations |
| `audit_serialization_colocated.sh` | no centralized serialization package |
| `audit_serialization_spec_tiers.sh` | spec imports match tier boundaries |
| `audit_state_no_entities.sh` | state does not import `impl.entity` |
| `audit_producer_no_state.sh` | producers do not import state |

Tests: `serialization/StateJacksonSpec`, `EventJacksonSpec`, `TableJacksonSpec`, `InternalTierSpec`.

Architecture docs: repo `AGENTS.md` and `stl-arch-akka` skill only — no `aggregate/README.md`.

## Related CRM case study

`jackson-sealed-adt-stey-crm-examples.md` covers the earlier LeadFollowUp / SurveyReward fix pattern; SteyCrs extends that to full-tier decoupling, table Jackson, setup simplification, and inline remap removal.
