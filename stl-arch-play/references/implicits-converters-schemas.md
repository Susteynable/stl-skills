# Implicits: Converters, Schemas, Formats

Canonical layout for shared Tapir / Play implicits under `.../implicits/`. Keep elementary conversions and Tapir schemas out of controller bodies and out of `dsl/` except via mixin on `ApiEndpointController`.

## Package shape

```text
implicits/
|- package.scala          # aggregates: extensions, jsonFormats, schemas, converters
|- *Converter.scala       # String -> T (+ asX helpers)
|- PrimitiveStringConverter.scala  # T -> String for elementary types
|- *Schema.scala          # Tapir Schema[T] for shared leaf types
|- *JsonFormat.scala      # Play Format[T]
`- *Extension.scala       # convenience ops
```

`package.scala` exposes both an object (import site) and a trait (mixin site):

| Aggregate | Object (import) | Trait (mixin) |
|---|---|---|
| Converters | `implicits.converters` | `Converters` |
| Schemas | `implicits.schemas` | `Schemas` |
| JsonFormats | `implicits.jsonFormats` | `JsonFormats` |
| Extensions | `implicits.extensions` | `Extensions` |

## Converter rules

- Put `String -> T` on the matching `*Converter` trait next to the `asX` helper:

```scala
trait UUIDConverter {
  implicit class UUIDStringHelper(value: String) {
    def asUUID: UUID = ...
  }
  implicit def stringToUUID(value: String): UUID = value.asUUID
}
```

- Put elementary `T -> String` only on `PrimitiveStringConverter` (UUID, BigDecimal, LocalDate, LocalTime). Do not scatter `uuidToString`-style implicits across controllers.
- Mix `Converters` (which includes `PrimitiveStringConverter`) into `ApiEndpointController` so controller code can convert without local implicits.
- Prefer `import implicits.converters._` in DTOs / helpers that need conversions without extending the controller base.

## Schema rules

### Shared leaf schemas (`implicits/`)

- Put shared Tapir `Schema[T]` in a dedicated `*Schema` trait under `implicits/` (e.g. `TimeZoneSchema`, `FiniteDurationSchema`, `LocalTimeSchema`, `PaginationSchema`).
- Aggregate them on `Schemas`; mix `Schemas` into `ApiEndpointController`.
- For response/request companions outside controllers that need a leaf schema, import the specific member (e.g. `import com.stey.api.app.implicits.schemas.paginationSchema`) or `import schemas._`.
- Do not define shared primitive schemas inside `dsl/ApiEndpointController` or ad-hoc in one controller.

### Explicit DTO schemas (required)

- **Do not** mix `sttp.tapir.generic.auto.SchemaDerivation` into `Schemas` / `ApiEndpointController`, and **do not** `extends SchemaDerivation` on DTO companions.
- Global `SchemaDerivation` + global `PrimitiveStringConverter` (`UUID => String`, etc.) poisons Magnolia derivation and can crash the Scala compiler (`AssertionError: assertion failed: new deprecated()`, often in phase `superaccessors`)—especially on types with `@deprecated` fields.
- Prefer explicit companion schemas:

```scala
import sttp.tapir.Schema
import sttp.tapir.generic.auto._

object CreateRequest {
  implicit val format: OFormat[CreateRequest] = Json.format[CreateRequest]
  implicit val schema: Schema[CreateRequest]  = Schema.derived[CreateRequest]
}
```

- String enums (`underlying: String` + `fromValue`): `Schema.derivedEnumeration[T](encode = Some(_.underlying))`.
- Sealed ADTs with case-class payloads: `Schema.derived[T]` (not `derivedEnumeration`).
- Place parent `Schema.derived` **after** nested case classes / companions are defined (Magnolia forward-ref).
- Never put `implicit val schema` inside a `new OFormat[T] { ... }` body—it is not a companion member and Magnolia will not see it.
- When a DTO field uses `Text` / `AbsoluteFile` / `Locale`, import `com.stey.common.i18n.api.implicits._` in that companion. For `Code`, import `com.stey.common.code.api.implicits._`.
- Do **not** redefine `Schema[JsValue]`; `TapirJsonPlay` already provides `schemaForPlayJsValue`. A second `Schema[JsValue]` in `Schemas` makes WebSocket / JSON codecs ambiguous.

## Json format rules

- Shared Play `Format[T]` for primitives live in `*JsonFormat` traits under `implicits/`, aggregated by `JsonFormats`.
- Import with `import com.stey.api.app.implicits.jsonFormats._` at DTO sites that need them.

## Controller base mixin

`ApiEndpointController` should mix the aggregates, not redefine them:

```scala
trait ApiEndpointController
    extends ...
    with Converters
    with Schemas {
  ...
}
```

Controllers that extend `ApiEndpointController` inherit converter and shared leaf schema implicits. Do not re-declare `stringToUUID` / `timeZoneSchema` locally unless intentionally shadowing.

`Schemas` = shared leaf schemas only. Request/response `Schema[T]` lives on each DTO companion.

## Anti-patterns

- Elementary `implicit def stringToUUID` / `uuidToString` inside a controller or DTO companion
- Mixing `SchemaDerivation` globally (or on a companion) while `PrimitiveStringConverter` is also global
- Relying on auto-derived `Schema[T]` for `ApiRequestData` / `ApiResponseData` instead of companion `Schema.derived`
- Using `Schema.derivedEnumeration` on ADTs that have case-class subtypes
- Shared Tapir schemas left in `dsl/` when they belong under `implicits/`
- Adding a new primitive converter/schema without wiring it into `Converters` / `Schemas` in `package.scala`
- Mixing only one direction (`String -> T` without the matching `T -> String` when controllers need both)
- Duplicate `Schema[JsValue]` alongside `TapirJsonPlay`
