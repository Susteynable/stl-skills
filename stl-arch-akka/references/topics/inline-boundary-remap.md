# Inline boundary remap

Use when mapping between onion tiers at Processor, delegate, producer, rebuild, or internal write boundaries.

## Core decision

**Remap with an explicit inline `match` (or equivalent field copy) at every boundary call site.**

Duplication across 2–3 call sites is intentional. Do not extract shared converters to reduce repetition.

## Where inline remap is required

| Boundary | Owner | Example |
|----------|-------|---------|
| Event → table ADT | `Processor` | `ReservationAddonItemAddEvent.AddonItemUnitPriceFormula` → `SteyCrsReservationAddonItemTable.ReservationAddonItemUnitPriceFormula` |
| Entity / table ADT → gRPC response | delegate / `*ServiceImpl` read path | table `UnitPriceFormula` → `ConfigAddonItemGetResponse.AddonItemUnitPriceFormula` |
| Event → outbound Kafka / event proto | `*EventProducer` | event ADT → nested `crsevent` message in one step |
| Table / entity → state or setup command | rebuild engine | table `RatePlanBreakfastRule` → `ConfigState.RatePlanBreakfastRule` inline in `AggregateRebuild*` |
| Service / consumer → internal | `*ServiceImpl`, consumers | proto → `*Internal.<Model>` inline |
| Internal → command | `class *Internal` | internal model → `Command.*` inline |

Map **directly** across the two tiers at the arrow. Avoid double conversion (event → table → proto when event → proto is enough).

## Pattern

```scala
unitPriceFormula = unitPriceFormula match {
  case ReservationAddonItemAddEvent.AddonItemUnitPriceFormula.Fixed(rate, amountBasis) =>
    SteyCrsReservationAddonItemTable.ReservationAddonItemUnitPriceFormula.Fixed(rate, amountBasis)
  case ReservationAddonItemAddEvent.AddonItemUnitPriceFormula.Predefined =>
    SteyCrsReservationAddonItemTable.ReservationAddonItemUnitPriceFormula.Predefined
}
```

For `Option` fields:

```scala
breakfastRule = breakfastRule
  .map {
    case SteyCrsRatePlanBreakfastTable.RatePlanBreakfastRule.PerPersonPerDay(rate, amountBasis) =>
      ConfigRatePlanGetResponse.PerPersonPerDay(rate = rate.toString(), amountBasis = implicitly[AmountBasis](amountBasis))
    case SteyCrsRatePlanBreakfastTable.RatePlanBreakfastRule.FixedQuantityPerDay(quantity, rate, amountBasis) =>
      ConfigRatePlanGetResponse.FixedQuantityPerDay(quantity = quantity, rate = rate.toString(), amountBasis = implicitly[AmountBasis](amountBasis))
  }
  .getOrElse(ConfigRatePlanGetResponse.RatePlanBreakfastRule.Empty)
```

No `optTo*` helpers.

## Forbidden

| Pattern | Why |
|---------|-----|
| `*Mapping.scala`, `*Mappers.scala`, `AggregateRebuild*Remap` objects | hides blast radius; reintroduces shared cross-tier coupling |
| private `fooToTable` / `barFromTable` in `Processor` | same as above |
| companion `toGetResponseGrpc`, `toSearchResponseGrpc`, `toEventGrpc`, `from*RequestGrpc`, `optTo*Grpc` on `object *Table` or state companions | companions own storage/serialization only |
| implicit cross-tier conversions on shared ADTs | bypasses explicit boundary review |
| table helper that builds gRPC/event proto from storage ADT | read/write path coupling |

## Allowed on table / state companions

Keep only tier-local concerns:

- Jackson annotations and `columnMapper` via `JsonSerialization` (SteyCrs canonical), or legacy spray `format` during migration
- domain methods that interpret stored data (`getUnitPrice`, etc.)
- colocated custom JsonNode deserializers for legacy replay on aggregate tiers only

## Allowed outside table/state companions

- enum ↔ proto helpers on `impl.enums.*` (e.g. `ReservationTagType.toGrpc`)
- infrastructure with no onion-tier crossing (DB row assembly, pagination, APM)
- same-tier reuse that does not remap one tier into another

## Review grep signals

Flag PRs that add or keep:

```text
*ToTable|*FromTable|ToTable\(|FromTable\(
toGetResponseGrpc|toSearchResponseGrpc|optTo.*Grpc|toEventGrpc|from.*Grpc
*Mappers|*Mapping|FormulaRemap|AggregateRebuild.*Remap
```

Enum helpers under `impl.enums` and profile/external-service adapters are out of scope for this grep.

## Cross-references

- tier ownership: `onion-model.md`, `onion-boundary-rules.md`
- table companion scope: `entity-table-json-types.md`
- processor: track K
- producers: track L
- delegates: track B
- rebuild: track N, `setup-process.md`
