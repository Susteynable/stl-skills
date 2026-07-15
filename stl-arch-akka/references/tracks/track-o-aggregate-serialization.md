# Track O - Aggregate Serialization

Read:

- `../topics/aggregate-json-serialization.md`
- `../topics/impl-enums-string-enum.md`
- `../topics/jackson-sealed-adt-audit.md`
- `../topics/jackson-sealed-adt-template.md`
- `../case-studies/jackson-sealed-adt-stey-crm-examples.md`
- `../case-studies/jackson-serialization-stey-crs-refactor.md`

Checklist:

- [ ] `JsonSerializable` binding in `application.conf` points to the expected Akka Jackson binding.
- [ ] Command/Event/State aggregate tiers use Jackson only; owned sealed ADTs use `@JsonTypeInfo(use = JsonTypeInfo.Id.NAME)` + `@JsonSubTypes(value = classOf[...])` only — no `include`, `property = "_type"`, or `name =` on subtypes.
- [ ] Table ADT parent traits use `@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.PROPERTY, property = "_type")` with explicit `name =` on `@JsonSubTypes.Type`.
- [ ] Each command/event/state companion owns its nested ADTs; no cross-tier references within aggregate sources.
- [ ] Custom serializers/deserializers are colocated on the owning companion; legacy replay uses JsonNode bridges, not spray fallback.
- [ ] Case objects use targeted singleton `@JsonDeserialize` when annotation-only Jackson is insufficient.
- [ ] Map-key codecs and test-only Jackson registration live in `*JacksonSpec`, not on production ADT companions.
- [ ] `JsonSerialization` uses `JacksonObjectMapperProvider` with the same binding name as Akka persistence; table column mappers use `toJsonString` / `fromJsonString`.
- [ ] `impl.enums.*` kits follow `StringEnum` / `StringEnumCompanion`: `def all` on main companion, case objects in holder, four `extends super.Jackson*` stubs, per-enum `columnMapper`, non-implicit `fromValue`.
- [ ] Impl build imports the three common Jackson artifacts: `stey-common-code-jackson`, `stey-common-i18n-jackson`, and `stey-common-sorter-jackson`.
- [ ] `JsonSerialization` registers `CodeJacksonSupport`, `I18nJacksonSupport`, and `SorterJacksonSupport` on the shared mapper and the Akka mapper it returns.
- [ ] No `.toJson` / `.convertTo` / `RootJsonFormat` remains on aggregate Command/Event/State paths.
- [ ] `object *Internal` has no spray, Jackson, or DB-string serializers.
- [ ] `scripts/audit_missing_jackson.sh` passes for known sealed ADT hotspots when present in repo.
