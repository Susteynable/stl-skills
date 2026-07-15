# Track M - Entity Tables

Read:

- `../topics/entity-table-json-types.md`
- `../topics/entity-table-constraints.md`
- `../case-studies/jackson-serialization-stey-crs-refactor.md`

Checklist:

- [ ] Table JSON or column ADTs live on `object *Table`.
- [ ] Table companion models are storage-only and are not used in write-path services.
- [ ] Table companions use Jackson via `JsonSerialization` column mappers with colocated `@JsonTypeInfo` / `@JsonSubTypes` (`property = "_type"` on table tier).
- [ ] Table companions do not expose JacksonSerializer classes, gRPC converters, or `to*Grpc` / `from*Grpc` / `optTo*Grpc` / other cross-tier converter methods.
- [ ] `object *Repository` holds `rows` only.
- [ ] Mutable entity tables include `createdBy`, `createdAt`, `updatedBy`, and `updatedAt`.
- [ ] Slick `def *` and `GetResult` include audit columns for mutable entities.
- [ ] Table JSON formats are not duplicated on aggregate tiers; Processor remaps event ADTs to table ADTs inline.
