# Aggregate JSON serialization

Use when auditing or migrating aggregate `Command`, `Event`, or `State` away from spray-json, or when aligning table JSON columns with the SteyCrs Jackson pattern.

## Core rule

| Tier | Serializer | spray-json |
|------|------------|------------|
| Command | Jackson via `JsonSerializable` | Forbidden |
| Event | Jackson via `JsonSerializable` | Forbidden |
| State | Jackson via `JsonSerializable` + `@JsonCreator` when needed | Forbidden |
| Run | Jackson via `JsonSerializable` | Forbidden |
| `object *Internal` | none | Forbidden |
| `object *Table` JSON column ADTs | Jackson via `JsonSerialization.toJsonString` / `fromJsonString` | Forbidden |
| `impl.enums.*` | Jackson string value via `StringEnumCompanion` (+ map-key stubs in specs) | Legacy only during migration |

Do not keep parallel spray and Jackson schemas on the same type.

`impl.enums.*` is separate from aggregate journal ADTs: sealed traits extend `StringEnum`, companions extend `StringEnumCompanion`, serialize as plain `underlying` strings, and own gRPC + Slick helpers. See `impl-enums-string-enum.md`.

## Colocated serialization (SteyCrs / SteyWo pattern)

- Put Jackson annotations and any custom serializer/deserializer on the **same companion** as the ADT (command/event/state/table nested object).
- Do **not** add a centralized `serialization/` package, bridge objects, or shared cross-tier codecs.
- Legacy journal replay uses JsonNode readers inside custom deserializers — not spray fallback.
- Map-key codecs and other test-only registration belong in `*JacksonSpec` files, not on production ADT companions.

## Required sealed ADT shape

### Aggregate Command / Event / State (journal + cluster transport)

```scala
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME)
@JsonSubTypes(Array(
  new JsonSubTypes.Type(value = classOf[Foo.Bar]),
  new JsonSubTypes.Type(value = classOf[Foo.Baz.type])
))
sealed trait Foo extends Product with Serializable
```

**Do not** on aggregate-owned ADTs:

- `include = JsonTypeInfo.As.PROPERTY` or `property = "_type"` on `@JsonTypeInfo`
- `name = "..."` on `new JsonSubTypes.Type(...)`
- Slick `implicit def columnMapper` / `MappedColumnType` (belongs on `object *Table` or `impl.enums.*` when the type is stored as a typed column)

Those belong on **table JSON column** ADTs only (see below).

### Table JSON column ADTs (Slick `TEXT` / persisted read-model JSON)

- Use `@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.PROPERTY, property = "_type")`.
- Register variants with `@JsonSubTypes` and explicit `name = "snake_case"` for stable stored JSON.
- Variants stay plain case classes or case objects.
- Prefer trait-level subtype registration over `@JsonTypeName` discovery.
- Keep each ADT on the tier that owns it. Redefine per event/command/state/table companion — never reference another tier's nested ADT (e.g. `ReservationAddonItemUpdateEvent` must not use `ReservationAddonItemAddEvent.AddonItemUnitPriceFormula`).

## Case objects

Add a targeted nested singleton deserializer inside the case object itself to avoid illegal cyclic references and keep the code clean and self-contained:

```scala
@JsonDeserialize(using = classOf[NotApplicable.JacksonDeserializer])
final case object NotApplicable extends GuaranteeChargeFormula {
  final class JacksonDeserializer extends JsonDeserializer[NotApplicable.type] {
    override def deserialize(parser: JsonParser, context: DeserializationContext): NotApplicable.type = NotApplicable
  }
}
```

## Two ObjectMappers (do not merge)

| Mapper | Owner | Purpose |
|--------|-------|---------|
| Akka Jackson | `akka.serialization.jackson` via `JsonSerializable` / `CborSerializable` in `application.conf` | Persistence and remoting only — Command / Event / State / Run ser/deser |
| `JsonSerialization` | Application code | Explicit user-side JSON — table JSON columns, audit/log payloads (`cleanupPayload`), setup dummy payloads, other manual business transforms |

Same domain codecs may be registered on both (`CodeJacksonModule`, `I18nJacksonModule`, `SorterJacksonModule`, plus Scala / `JavaTime`). **Same modules, separate `ObjectMapper` instances and lifecycles** — do not share Akka's mapper for application JSON, and do not use `JsonSerialization` for journal/cluster paths. Config or module changes on one path must not silently affect the other.

## JsonSerialization helper (application / user-side)

Owns a private application `ObjectMapper` — not Akka's serializer:

```scala
object JsonSerialization {

  /** Application / user-side ObjectMapper — not Akka's serializer.
    * Table JSON columns, cleanupPayload, and other call-site business JSON.
    * Akka owns the JsonSerializable / CborSerializable mapper separately.
    * Shared modules (Code / I18n / Sorter + Scala / JavaTime); separate instances.
    */
  private lazy val objectMapper: ObjectMapper = new ObjectMapper()
    .registerModule(DefaultScalaModule)
    .registerModule(new JavaTimeModule)
    .registerModule(CodeJacksonModule)
    .registerModule(I18nJacksonModule)
    .registerModule(SorterJacksonModule)

  def toJsonString[T](value: T): String = objectMapper.writeValueAsString(value)
  def fromJsonString[T](json: String, clazz: Class[T]): T = objectMapper.readValue(json, clazz)
  def toCompactString[T](value: T): String = toJson(value)
  def cleanupPayload(value: Any, ...): String = ...
}
```

Import the matching impl dependencies before registration:

- `com.stey.common` %% `stey-common-code-jackson`
- `com.stey.common` %% `stey-common-i18n-jackson`
- `com.stey.common` %% `stey-common-sorter-jackson`

Register the same three modules on Akka's Jackson config when journal/cluster payloads need those codecs — still a separate mapper from `JsonSerialization`.

Table column mappers call `JsonSerialization.toJsonString` / `fromJsonString` — they do not instantiate `new ObjectMapper()` at call sites (only `JsonSerialization` owns the app-side instance).

## Tier decoupling greps

Within aggregate sources, each tier owns its ADTs:

```bash
# SteyCrs canonical (legacy: aggregates/)
rg 'ConfigState\.|ReservationState\.' aggregate/command aggregate/event
rg 'import com\..*\.aggregate\.state' aggregate/event
rg 'ReservationAddonItemAddEvent\.' aggregate/event   # when UpdateEvent should own its shape
```

SteyCrs ships `scripts/audit_command_no_state.sh` and `scripts/audit_event_no_state.sh` as CI gates.

## Migration checklist

### 1. Side features

- Replace `event.toJson` / `convertTo` usage on aggregate paths.
- `ProcessorLog`: use `JsonSerialization.cleanupPayload(...)`.
- `SetupManager`: use `JsonSerialization.toCompactString(SetupDummyEvent(...))`.
- Register `CodeJacksonModule`, `I18nJacksonModule`, and `SorterJacksonModule` on the **application** mapper in `JsonSerialization`, and separately on Akka Jackson when needed for journal/cluster codecs.
- Tests: round-trip through Jackson, not spray.

### 2. Aggregate models

- Remove aggregate-tier `implicit val format`, `RootJsonFormat`, and `jsonFormatN`.
- Remove aggregate spray imports from `Command.scala`, `Event.scala`, and `state/**`.
- Keep `@JsonCreator` only for replay/schema evolution.
- Use explicit `@JsonSerialize` / `@JsonDeserialize` only when annotation-only Jackson is insufficient.
- Redefine nested ADTs per owning companion; eliminate cross-event or cross-command references.

### 3. Table models (SteyCrs pattern)

- Add `_type` + `@JsonSubTypes` on table companion sealed traits.
- Replace spray `columnMapper` with `JsonSerialization.toJsonString` / `fromJsonString`.
- Remove per-table `JacksonSerializer` classes when annotation-based Jackson suffices.
- Keep table ADTs storage-only — no gRPC converters on the companion.

### 4. Internal tier

- Remove all spray, Jackson, and DB-string serializers from `object *Internal`.
- Gate with `InternalTierSpec` or `audit_internal_no_serialization.sh`.

### 5. Verification

```bash
sbt "<svc>-impl/compile" "<svc>-impl/test"
# SteyCrs: aggregate/ ; legacy services: aggregates/
rg 'jsonFormat|RootJsonFormat|implicit val format' <svc>-impl/src/main/scala/**/aggregate/
rg 'spray\.json' <svc>-impl/src/main/scala/**/aggregate/
bash scripts/audit_missing_jackson.sh   # when present in repo
```

## Review checklist

- [ ] `JsonSerializable` binding points to the expected Akka Jackson binding.
- [ ] Aggregate `Command`, `Event`, and `State` use Jackson only.
- [ ] Aggregate `Command`, `Event`, and `State` nested sealed ADTs use `@JsonTypeInfo(use = NAME)` + `@JsonSubTypes(value = classOf[...])` only (no `include`/`property = "_type"`/`name =` on subtypes).
- [ ] No Slick `columnMapper` / `MappedColumnType` on aggregate command/event/state ADTs (table `object *Table` owns typed JSON columns).
- [ ] Table JSON column sealed ADTs use `@JsonTypeInfo(..., property = "_type")` + `@JsonSubTypes`.
- [ ] Each event/command companion owns its nested ADTs; no cross-tier references within `Command.scala` / `Event.scala` / `state/**`.
- [ ] No `.toJson` / `.convertTo` remain on aggregate paths.
- [ ] `JsonSerialization` owns a private application `ObjectMapper` (not `JacksonObjectMapperProvider` / Akka's binding).
- [ ] Application and Akka mappers both register the three common modules when those codecs are needed; instances stay separate.
- [ ] `SetupDummyEvent` re-seed uses `JsonSerialization.toCompactString`.
- [ ] Schema evolution uses Jackson (`@JsonCreator` or JsonNode bridges), not spray defaults.
- [ ] Table JSON columns use Jackson via `JsonSerialization`.
- [ ] `object *Internal` has no serializers.

## Anti-patterns

- `implicit val format` on persisted aggregate types
- `event.toJson` in projections while claiming Jackson-only aggregate models
- standalone `new ObjectMapper()` outside `JsonSerialization`
- routing application JSON (table columns, `cleanupPayload`) through Akka's mapper / `JacksonObjectMapperProvider`
- using `JsonSerialization` for Command / Event / State / Run journal or remoting ser/deser
- one shared sealed ADT reused across command, event, state, and storage tiers
- referencing another event's nested ADT instead of redefining on the owning event
- centralized `serialization/*Bridge*` or mapper objects for tier crossing
- spray or Jackson serializers on `object *Internal`
- relying on `@JsonTypeName`-only discovery for nested aggregate ADTs
- `include = JsonTypeInfo.As.PROPERTY`, `property = "_type"`, or `name =` on `@JsonSubTypes.Type` for aggregate command/event/state ADTs (table JSON columns only)
- Slick `columnMapper` / `MappedColumnType` on aggregate command/event/state ADTs

## Case study

See `../case-studies/jackson-serialization-stey-crs-refactor.md` for the full SteyCrs commit series and audit gates.
