# API layer — protobuf pattern

**Rule:** No reusable domain messages under `com/stey/<service>/api/grpc/models/`. Each RPC file and each outbound event message owns nested types.

Load this file when editing `stey-*-api` protos, `*ServiceImpl`, or `*EventProducer` — not for pure aggregate-internal refactors.

## Where nested messages live

| Location | Pattern | Generated Scala (ScalaPB) |
|----------|---------|---------------------------|
| RPC request | `message ProjectCreateRequest { message Address { ... } }` | `ProjectCreateRequest.Address` |
| RPC response | `message ProjectGetResponse { message Address { ... } }` | `ProjectGetResponse.Address` |
| Search/list item | Under item message | `ProjectSearchResponse.Project.Address` |
| Outbound event | `message ProjectCreate { message Address { ... } }` in `cms_*_event.proto` | `cmspropertyevent.ProjectCreate.Address` |

**Do not** import `grpc/models/foo.proto` from multiple RPC files. Duplicate the nested `message` in each file (consistent fields per copy).

## Allowed shared API content

- `grpc/enums/*`
- `com.stey.common.*.grpc.*` (`I18nText`, `RelativeFile`, timestamps)
- Service metadata (`TopicNameProto`, etc.)

**Not** aggregate domain shapes in `grpc/models/`.

## Removed anti-patterns

- `project_address.proto`, `room_type_amenity.proto`, `space_extended_info.proto`, `space_facility.proto` as shared imports
- `import com.stey.*.api.grpc.models.*` in impl
- `fromGrpc` / `toGrpc` on `impl.models` bridging to shared API protos

## Proto example

```protobuf
// project_get_response.proto — NOT grpc/models/project_address.proto
message ProjectGetResponse {
  com.stey.common.i18n.grpc.I18nText title = 1;
  Address address = 2;

  message Address {
    com.stey.common.i18n.grpc.I18nText title = 1;
    com.stey.common.i18n.grpc.I18nRelativeFile mapPath = 2;
    string latitude = 3;
    string longitude = 4;
  }
}
```

Duplicate `Address` (aligned fields) in `project_create_request.proto`, `project_search_response.proto` (`Project.Address`), `cms_property_event.proto` (`ProjectCreate.Address`, `ProjectUpdate.Address`), etc.

## Service remap

```scala
// Write: request nested proto → Internal
val addr = in.getAddress
Internal.Address(
  title = addr.getTitle,
  mapPath = addr.getMapPath,
  latitude = BigDecimal(addr.latitude),
  longitude = BigDecimal(addr.longitude)
)

// Read: entity → this RPC’s nested proto
ProjectGetResponse.Address(
  title = Some(row.title),
  mapPath = Some(row.mapPath),
  latitude = row.latitude.toString,
  longitude = row.longitude.toString
)
```

## Producer remap

```scala
cmspropertyevent.HotelRoomTypeCreate.Amenity(
  categories = amenity.categories.map { c =>
    cmspropertyevent.HotelRoomTypeCreate.Amenity.Category(
      title = Some(c.title),
      items = c.items.map(i =>
        cmspropertyevent.HotelRoomTypeCreate.Amenity.Category.Item(title = Some(i.title))
      )
    )
  }
)
```

Use the nested type on **that** event message (`HotelRoomTypeUpdate.Amenity`, `SpaceCreate.ExtendedInfo`, …) — never `com.stey.*.api.grpc.models.*`.

## SteyCms API paths

- RPC: `stey-cms-api/.../grpc/property/*_request.proto`, `*_response.proto`
- Events: `stey-cms-api/.../grpc/property/cms_property_event.proto`
