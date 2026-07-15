# Audit checklist — missing Jackson on sealed ADTs

Use when replay, rebuild, or command transport fails on aggregate sealed traits.

## Common symptoms

- replay or rebuild fails on ADT fields like `leadFollowUps`, `leadFollowUp`, or `surveyReward`
- cluster `askWithStatus` fails on commands carrying a sealed ADT
- Jackson sees `LinkedHashMap` / empty objects instead of discriminated variants
- event handler or processor fails because an event field references another event's nested ADT after tier decoupling

## High-value greps

```bash
# SteyCrs canonical paths (legacy services: aggregates/, entities/, aggregate/internal/ or internals/)
rg -n 'sealed trait (LeadFollowUp|SurveyReward|UserContactMethod|AddonItemUnitPriceFormula) extends' aggregate/ entity/
rg -n '@JsonTypeInfo.*property = "_type"' aggregate/command aggregate/event aggregate/state   # should be empty
rg -n 'JsonSubTypes\.Type\([^)]*name = ' aggregate/command aggregate/event aggregate/state   # should be empty
rg -n 'implicit def columnMapper|MappedColumnType\.base' aggregate/command aggregate/event aggregate/state   # should be empty
rg -n '@JsonTypeInfo.*property = "_type"' entity/
rg -n '@JsonTypeInfo\(use = JsonTypeInfo\.Id\.NAME\)' aggregate/
rg -n '@JsonSubTypes' aggregate/ entity/
rg -n '@JsonSerialize\(using = classOf\[.*\.JacksonSerializer\]\)' aggregate/
rg -n 'ConfigState\.|ReservationState\.' aggregate/command aggregate/event   # command/event ADT sections only (see audit_command_no_state)
rg -n 'ReservationAddonItemAddEvent\.' aggregate/event   # cross-event ADT smell
rg -n 'spray\.json|RootJsonFormat' aggregate/ aggregate/internal/
```

SteyCrs CI gates (copy from `stl-arch-akka/scripts/`): `audit_command_no_state.sh`, `audit_event_no_state.sh` (ADTs only; handlers may use state), `audit_internal_no_serialization.sh`, `audit_command_dispatcher_coverage.sh`, `audit_event_handler_coverage.sh`. Full catalog: `architecture-audit-scripts.md`.

## Pass / fail

| Check | Pass | Fail |
|-------|------|------|
| Command sealed ADT | parent has `@JsonTypeInfo(use = NAME)` + `@JsonSubTypes` with `value = classOf[...]` only (no `include`/`property`/`name`) | `_type` discriminator or named subtypes on aggregate tier |
| Event / State sealed ADT | same as Command | spray-only, missing discriminator, legacy `_type`/`name` on aggregate tier, or Slick `columnMapper` on aggregate ADT |
| Table JSON ADT | parent has `@JsonTypeInfo(use = NAME, include = As.PROPERTY, property = "_type")` + `@JsonSubTypes`; column mapper uses `JsonSerialization` | spray-only after migration, or missing discriminator |
| Subtype registration | variants listed on parent | discovery-only setup |
| Custom serializer | legacy JsonNode bridge or nested deserializers for case objects | new ADT depends on custom serializer without need |
| Tier ownership | each companion owns its nested ADTs | cross-event/state/command references |
| Internal tier | no serializers on `object *Internal` | spray or Jackson on internal companions |
| mirrored command/event ADT | both sides fixed | one side still legacy |

## Good reference

- Event / State: trait-level `@JsonTypeInfo(use = NAME)` + `@JsonSubTypes` (no `include`/`property`)
- Table ADT: trait-level `@JsonTypeInfo(use = NAME, include = As.PROPERTY, property = "_type")` + `@JsonSubTypes`
- Command: same pattern as Event/State, even if not journal-persisted
- Case objects: nested class `JacksonDeserializer` on the variant case object itself
- SteyCrs full refactor: `../case-studies/jackson-serialization-stey-crs-refactor.md`
- CRM LeadFollowUp fix: `../case-studies/jackson-sealed-adt-stey-crm-examples.md`

## Usually out of scope

- local wrapper types under `survey/Internal.scala`
- legacy admin JSON under `admin/*LegacyJson`
- `ProcessorLog` audit JSON alone

## After fix

```bash
sbt "<impl-module>/compile"
bash scripts/audit_missing_jackson.sh   # when present in repo
```

Spot-check that every aggregate sealed trait in `aggregate/command/**`, `aggregate/event/**`, or `aggregate/state/**` has trait-level `@JsonTypeInfo(use = NAME)` plus explicit subtype registration, and that events do not reference state or sibling-event ADTs.
