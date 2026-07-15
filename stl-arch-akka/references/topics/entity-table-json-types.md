# Entity table JSON types

Use when adding or moving JSON-column or column-pair storage types in `entity/*Table.scala`.

## Core rule

- `object *Table` owns storage-only table models.
- `object *Internal` owns write-path internal models.
- `object *Repository` owns `rows` only.

Do not conflate these tiers.

## File shape

```text
entity/SteyCrsHotelRoomTypeTable.scala   # SteyCrs canonical
├── trait SteyCrsHotelRoomTypeTable
│   ├── object SteyCmsHotelRoomTypeRepository   # rows only
│   ├── case class SteyCmsHotelRoomTypeEntity
│   └── class SteyCmsHotelRoomType
└── object SteyCmsHotelRoomTypeTable
    ├── final case class RoomTypeAmenity
    ├── nested storage ADTs
    ├── Jackson annotations + column mappers
    └── domain helpers (getUnitPrice, etc.)
```

## Table model vs internal model

| | Table model | Internal model |
|---|------------|----------------|
| Lives on | `object *Table` | `object *Internal` |
| Purpose | data stored in this table's columns | write-path input to `class *Internal` |
| Used by | entity, Slick `Rep`, Processor, Service read path | `*ServiceImpl`, consumers, actors |

If a type is not stored in the table's columns, it is not a table model.

## What belongs on `object *Table`

- persisted JSON / TEXT case classes
- nested storage ADTs
- `@JsonTypeInfo` / `@JsonSubTypes` on sealed storage traits (`property = "_type"` on table tier)
- `MappedColumnType` / column mappers using `JsonSerialization.toJsonString` / `fromJsonString`
- singleton `@JsonDeserialize` for case objects when needed
- storage/domain helpers that stay inside the table tier (`empty`, column interpretation, `getUnitPrice`, etc.)

Table companions do **not** expose gRPC/event-proto converters. Use Jackson via `JsonSerialization` column mappers — not spray.

## Forbidden

- write-path DTOs on `object *Table`
- gRPC / event-proto / request-response converters (`toGetResponseGrpc`, `fromCreateRequestGrpc`, `optTo*Grpc`, `toEventGrpc`, etc.)
- shared cross-tier mapper objects used by Processor, delegates, producers, or rebuild
- table models on `object *Internal`
- JSON types on `object *Repository`
- shared aggregate shapes under `impl.models`
- cross-tier type aliases on the table companion
- command/event/state/internal types used directly in Slick column types
- per-table `JacksonSerializer` classes when annotation-based Jackson + shared mapper suffices

## Processor boundary

Processor maps event companions to table companions inline:

```scala
SteyCmsHotelRoomTypeTable.RoomTypeAmenity(
  categories = amenity.categories.map(...)
)
```

Never write `Event.*` or `State.*` directly into JSON columns.

## Service read path

Read from entity rows and map inline to that RPC's nested response proto at the delegate call site. Do not add table-companion `to*Grpc` helpers or other shared converters. See `inline-boundary-remap.md`.

## Column mapper pattern (SteyCrs)

```scala
implicit def columnMapper(implicit profile: JdbcProfile): JdbcType[UnitPriceFormula] = {
  import profile.api._
  MappedColumnType.base[UnitPriceFormula, String](
    v => JsonSerialization.toJsonString(v),
    s => JsonSerialization.fromJsonString(s, classOf[UnitPriceFormula])
  )
}
```

## Spray init rule (legacy migration)

When spray remains during migration, do not put `jsonFormat1(Foo.apply)` inside `object Foo` when the object and case class share the same name. Define nested formats first and place the parent format on the table companion or use a safe constructor lambda.

## Checklist

- [ ] Case class, Jackson annotations, and column mapper live on `object *Table`.
- [ ] `object *Repository` holds `rows` only.
- [ ] Entity and `Rep[...]` types reference `*Table.<Type>`.
- [ ] Processor maps `Event.* -> *Table.<Type>` inline.
- [ ] Service read maps entity -> response proto inline.
- [ ] No new aggregate shapes were added under `impl.models`.
- [ ] No write-path DTO was placed on `object *Table`.
- [ ] No gRPC or cross-tier converter methods on the table companion.
- [ ] Mutable entities still follow audit-column rules from `entity-table-constraints.md`.

## Case study

See `../case-studies/jackson-serialization-stey-crs-refactor.md` for table Jackson migration and `TableJacksonSpec` coverage.
