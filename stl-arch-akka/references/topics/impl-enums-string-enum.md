# `impl.enums` StringEnum convention

Use when adding or migrating domain enums under `impl.enums.*` in Stey Akka services (SteyCrs pattern). These types are **allowed shared primitives** across onion tiers — the only cross-format exception besides `I18nText`, `Code`, etc.

**Copy-paste template:** `../examples/impl-enums-string-enum-template.md` (full `Foo`/`Foos` kit, subpackage variant, multiline `all`, backtick names, `MiscSpec` snippet).

## Placement

- Package: `impl.enums` and subpackages (`impl.enums.steyfinance`, `impl.enums.steyprofile`, …).
- Shared traits: `impl.enums.StringEnum` and `impl.enums.StringEnumCompanion` (one file per service).
- Subpackage enum files import `{StringEnum, StringEnumCompanion}` from the parent `impl.enums` package.

## Two-object layout

Each enum kit uses **two companions**:

| Object | Role |
|--------|------|
| `Foo` (same name as sealed trait) | `StringEnumCompanion` — `def all`, `fromValue`, Jackson/key serializer **stubs**, gRPC `toGrpc`/`fromGrpc`, Slick `columnMapper` |
| `Foos` / `FooTypes` / … (plural holder) | **Case objects only** — no `all`, no serializers, no gRPC |

Case objects stay in the holder so call sites keep stable names (`ReservationTypes.Hotel`, `AmountBases.Base`). `def all` lives on the main companion and lists every case object with the holder prefix. See `../examples/impl-enums-string-enum-template.md` for the full copy-paste file.

```scala
// shape only — full template in ../examples/impl-enums-string-enum-template.md
object ReservationType extends StringEnumCompanion[ReservationType] {
  def all: Seq[ReservationType] = Seq(ReservationTypes.Apartment, ReservationTypes.Hotel)
  class JacksonSerializer   extends super.JacksonSerializer
  // ... JacksonDeserializer, JsonKeySerializer, JsonKeyDeserializer
  // toGrpc / fromGrpc / columnMapper on this object
}
object ReservationTypes {
  case object Apartment extends ReservationType { @JsonValue override def underlying: String = "tenant" }
  case object Hotel     extends ReservationType { @JsonValue override def underlying: String = "hotel_guest" }
}
```

## `StringEnum` / `StringEnumCompanion`

- `StringEnum[E]` — `underlying: String`, `widen: E`; extends `Product with Serializable`.
- `StringEnumCompanion[E]` — `def all`, `def fromValue` (case-insensitive `underlying` match), Jackson value + map-key serializer **implementations** in the trait.
- **`fromValue` is a plain `def`, not `implicit`** — use explicit case objects for Slick `O.Default(...)` and similar defaults (`BillingPartyTypes.Guest.widen`, not implicit `fromValue`).
- **`columnMapper` stays per enum** on the main companion — do not lift into `StringEnumCompanion`; generic `MappedColumnType.base[E, String]` causes Slick diverging-implicit expansion.

## Jackson

- Annotate the **sealed trait** with `@JsonSerialize` / `@JsonDeserialize` pointing at `classOf[Foo.JacksonSerializer]` / `JacksonDeserializer`.
- On `object Foo`, declare four **empty stub classes** `extends super.*` — required so `classOf[Foo.JacksonSerializer]` resolves to a concrete class with a no-arg constructor (trait implementations alone break Jackson registration and serialization tests).
- Case objects use `@JsonValue override def underlying` (or `val`) for the persisted string.
- Map-key codecs: register `JsonKeySerializer` / `JsonKeyDeserializer` in `*JacksonSpec` when enums appear as JSON object keys; stubs must exist on the companion.

Enums serialize as **plain strings** (`underlying`), not as `_type` discriminated JSON. Do not apply aggregate sealed-ADT `@JsonTypeInfo` rules to `impl.enums.*`.

## gRPC boundary (only allowed cross-format helpers)

- `implicit def toGrpc` / `fromGrpc` on the main companion only — inline `match` per variant.
- Do not add shared `*Mapping` objects or companion `to*Grpc` helpers outside `impl.enums.*`.

## Slick

- One `implicit def columnMapper` per enum on the main companion.
- Storage uses `underlying` strings; reads use `Foo.fromValue`.
- Project-config and plain `String` columns: prefer `.underlying` on write and `Foo.fromValue(...)` on read instead of custom JSON bridges on the enum.

## Naming

- Sealed trait: singular domain name (`ReservationType`, `BillStatus`, `AmountBasis`).
- Holder object: plural or conventional suffix (`ReservationTypes`, `BillStatuses`, `AmountBases`, `AddonItemTypeTypes` when the trait name already ends in `Type`).
- Holder name may differ from trait name when history requires it (e.g. trait `BillStatus`, holder `BillStatuses` in `steyfinance`).

## Review checklist

- [ ] `def all` is on `object Foo`, not on the holder; every case object appears in `all`.
- [ ] Holder object contains case objects only (no `all`, serializers, or gRPC).
- [ ] Main companion has four `extends super.Jackson*` stub classes.
- [ ] `fromValue` is not `implicit`.
- [ ] `columnMapper` is concrete per enum, not in `StringEnumCompanion`.
- [ ] gRPC converters live on main companion; no mapper package.
- [ ] Tests and coverage specs use `Foo.all`, not `Foos.all` (`MiscSpec` pattern).
- [ ] No spray `format` / `RootJsonFormat` on enum types.

## Anti-patterns

- `def all` delegating to `Foos.all` (duplicate definition on holder).
- Removing Jackson stub classes and relying on trait inner classes (breaks `classOf[Foo.JacksonSerializer]`).
- `implicit def fromValue` (breaks explicit Slick defaults and implicit ambiguity).
- Generic `columnMapper` in `StringEnumCompanion`.
- gRPC or table JSON converters on the holder object.
- Sharing one enum ADT across command/event/state tiers instead of `impl.enums.*`.

## Related

- **Template:** `../examples/impl-enums-string-enum-template.md`
- Aggregate Jackson tiers: `aggregate-json-serialization.md` (enums are not aggregate journal ADTs).
- Track O serialization audit: `../tracks/track-o-aggregate-serialization.md`.
