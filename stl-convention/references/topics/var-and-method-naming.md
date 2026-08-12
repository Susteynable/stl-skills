# Var and method naming

Applies to command handlers, private helpers, and for-comprehension locals. Canonical example: SteyCrs `ReservationDateSet` renames (`2a628f17`).

Name for **intent and domain type**, not for implementation trivia (`get`, tuple arity, verb stem alone).

## Method verbs

| Role | Verb / shape | Example |
|------|----------------|---------|
| Look up or compute a domain value from state / inputs | `resolve*` | `resolveRoomRateForDate`, `resolveAddonBreakdownForDate` |
| Assemble concrete events (and optional companion payload) | `build*Events` / `build*Event` | `buildAddonItemRateDailyEvents`, `buildRateEventsForStayExtension` |
| Scope of iteration or domain window | suffix `ForDate` / `ForDays` / `ForStayExtension` | `extendMultiplePostingAddonRatesForDays` |

Avoid:

- Vague `get*` for non-trivial resolve-or-fallback logic (`getRoomRateWithBreakfastForDate` → `resolveRoomRateForDate`).
- Reusing `resolve*` when the helper’s primary product is events (`resolveAddonItemRateForDate` → `buildAddonItemRateDailyEvents`).
- Verb-only names that omit what is returned or over what range (`extendStayRateEvents` → `buildRateEventsForStayExtension`).

## Local / parameter names

| Situation | Convention | Prefer | Avoid |
|-----------|------------|--------|--------|
| `Option[T]` | `maybe*` prefix | `maybeDerivedRate`, `maybeBlockStayGroupId` | `derivedOpt`, `blockStayGroupIdOpt`, any `*Opt` suffix |
| Domain values | include type word (`Rate`, `Breakdown`, `Events`) | `existingRate`, `derivedRate`, `dailyAddonBreakdown`, `roomRates` | `existing`, `derived`, `dailyTotal`, `rates` |
| Results of an action | past participle / result noun | `extendedAddonBreakdownByDate`, `extendedAddonEvents` | `extendAddonByDate`, `extendAddonEvents` |
| Concrete events | actual event type as val name | `addonItemRateDailySetEvent`, `reservationRateDailySetEvents` | bare `rateDailySetEvent` when the event is `ReservationAddonItemRateDailySetEvent` |
| Event collections by kind | name after the event | `rateDailyUnsetEvents`, `rateDailySetEvents` | `unsets`, `sets` |
| Filtered collections | say the filter | `plannedOrActiveRerents` | reusing singular `reservationRerent` for a `Seq` |
| Tuples | name the parts | `breakfastRatePerDayUnitAndTotal`, `addonItemRateDaily` | `breakfastRatePerDayT2`, `t` |

### `Option` locals: `maybe*` not `*Opt`

For vals, params, and for-comprehension bindings of type `Option[_]`, use the **`maybe*` prefix**. Do **not** use an `*Opt` / `xxxOpt` suffix.

| From | To |
|------|----|
| `derivedOpt` | `maybeDerivedRate` (include domain type word when helpful) |
| `blockStayGroupIdOpt` | `maybeBlockStayGroupId` |
| `adjustmentOpt` | `maybeAdjustment` |
| `existingGroupOpt` | `maybeExistingGroup` |

Mechanical rename: `fooOpt` → `maybeFoo` (capitalize the stem). Prefer a typed stem when the bare name is ambiguous (`derivedOpt` → `maybeDerivedRate`, not `maybeDerived`).

Exception: Slick’s API method **`filterOpt`** stays as-is — it is not an Option variable name.

Unused left side of a tuple may be `_` when the binding name still describes the whole: `(_, breakfastRatePerDayTotal) = breakfastRatePerDayUnitAndTotal`.

## Mini examples

```scala
// Preferred — resolve value, maybe Option, typed locals
maybeDerivedRate <- getDerivedRate(...)
derivedRate      <- maybeDerivedRate.toRight(...)
roomRateWithBreakfast = derivedRate + breakfastRatePerDayTotal

// Preferred — build events, event-shaped vals
addonItemRateDailySetEvent = ReservationAddonItemRateDailySetEvent(...)
events = Seq(addonItemRateDailySetEvent, inventoryAdjustmentEvent)

// Preferred — result maps / sequences
extendedAddonBreakdownByDate = extendedAddonRateEntries.groupMapReduce(...)(...)(_ + _)
rateDailyUnsetEvents = dailyRateEvents.collect { case e: ReservationRateDailyUnsetEvent => e }
```

```scala
// Avoid
derivedOpt <- getDerivedRate(...)
systemBreakdown = derived + breakfastRatePerDayTotal
unsets = dailyAndAddonRateEvents.collect { case e: ReservationRateDailyUnsetEvent => e }
t <- resolveAddonItemRateForDate(...)
```

## Related

- Event vals / assign-then-yield: `command-handler-coding-style.md`
