# Track B - Controller DSL

Read `../controller-patterns.md`.
For converters / Tapir schemas / Play formats, read `../implicits-converters-schemas.md`.

Verify:

- Controller extends `ApiEndpointController`.
- `apiEndpointBuilder` is the first constructor dependency.
- Endpoint starts from the correct builder and uses `.apiPath` unless intentionally custom.
- Envelope APIs use `apiRequestBody[...]` / `apiResponseBody[...]`.
- Logic uses `.apiServerLogic`.
- `def endpoints` lists every endpoint; `def apiGroup` is set when needed.
- DTOs live in the same package and have Play JSON formats (no Jackson annotations or serdes).
- No local elementary `String <-> UUID|BigDecimal|LocalDate|LocalTime` implicits; rely on `Converters` / `import converters._`.
- Shared leaf Tapir schemas live under `implicits/*Schema` and arrive via `Schemas` (or `import schemas._` / a specific member such as `paginationSchema`).
- Request/response DTOs declare `implicit val schema: Schema[T] = Schema.derived[T]` (or `derivedEnumeration` for string enums) on the companion—do not use `SchemaDerivation` on `Schemas` or companions.
- New `*Converter` / `*Schema` / `*JsonFormat` traits are wired into the matching aggregate in `implicits/package.scala`.
- String enums / polymorphic ADTs use Play JSON + Tapir Schema only; ADT discriminator is `_type`.
