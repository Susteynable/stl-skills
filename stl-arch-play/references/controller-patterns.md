# Controller Patterns

Use this as the canonical reference for controller structure, DTO naming, and common endpoint shapes.

## Controller checklist

- Controller extends `ApiEndpointController`.
- Constructor takes `apiEndpointBuilder: ApiEndpointBuilder` first; service clients are injected, not created inline.
- Endpoint starts from `unsecuredEndpoint`, `securedEndpoint(...)`, or `userAwareEndpoint(...)`.
- Use `.apiPath` unless the endpoint is an intentional manual callback path.
- Chain the HTTP verb on the builder result.
- Envelope APIs use `apiRequestBody[T]` / `apiResponseBody[T]` with `T <: ApiRequestData` / `ApiResponseData`.
- Logic uses `.apiServerLogic { implicit context => ... }`, not raw `.serverLogic`.
- `def endpoints` lists all endpoint vals; `def apiGroup` is set when grouping is wanted.
- DTOs live in the same package and provide Play JSON `Format` / `OFormat` (no Jackson).
- Throw `I18nBusinessException` for business failures; avoid manual endpoint-level wrappers.
- Do not declare elementary `String <-> UUID|BigDecimal|LocalDate|LocalTime` implicits in the controller; they come from `ApiEndpointController` via `Converters`.
- Shared Tapir schemas / Play formats for primitives live under `implicits/` (`Schemas`, `JsonFormats`); import those aggregates in DTO companions when not on a controller.
- Sealed string enums: Play `Format` + Tapir `Schema.derivedEnumeration`; no `@JsonValue` / Jackson serdes.
- Polymorphic ADTs: Play `OFormat` with `_type` discriminator (pattern: `RoomAvailability`, `LoginOption`).

## DTO naming

DTO simple names mirror the endpoint val in PascalCase in the same package.

| Endpoint val | Request | Response |
|---|---|---|
| `create` | `CreateRequest` | `CreateResponse` |
| `update` | `UpdateRequest` | `UpdateResponse` |
| `get` | none or query params | `GetResponse` |
| `list` | none | `ListResponse` |
| `search` | `SearchRequest` only when a request body exists | `SearchResponse` |
| `delete` | `DeleteRequest` only when needed | `ApiResponseData.Empty` or no body |

Rules:

- Do not prefix DTOs with domain nouns the package already conveys.
- Keep DTOs next to the controller package that owns the endpoint.
- Identical simple names across different subpackages are fine when each matches its local endpoint val.
- Do not rename upstream gRPC types; alias them on import when needed.

## Route-shape rules

- Multi-word route folders use camelCase package names so `.apiPath` emits kebab-case correctly.
- Nested legacy path segments belong in subpackages with short endpoint vals such as `device.create`, not `deviceCreate`.
- When Track C changes endpoint vals or subpackages, Track D must rename and move DTOs to match.

## Templates

### Unsecured POST with body

```scala
class Controller(
    apiEndpointBuilder: ApiEndpointBuilder,
    someServiceClient: SomeServiceClient
)(implicit
    ec: ExecutionContext,
    langs: Langs,
    apmManager: ApmManager
) extends ApiEndpointController {

  private val create = apiEndpointBuilder.unsecuredEndpoint.apiPath.post
    .in(apiRequestBody[CreateRequest])
    .out(apiResponseBody[CreateResponse])
    .apiServerLogic { implicit context =>
      { case CreateRequest(name) =>
        for {
          result <- someServiceClient.doSomething(name)
        } yield CreateResponse(result.id)
      }
    }

  override def apiGroup: Option[String] = Some("MyFeature")

  def endpoints: List[ServerEndpoint[AkkaStreams with capabilities.WebSockets, Future]] = List(create)
}
```

### Secured GET

```scala
private val get = apiEndpointBuilder.securedEndpoint().apiPath.get
  .in(query[String]("id"))
  .out(apiResponseBody[GetResponse])
  .apiServerLogic { implicit context =>
    { case id =>
      someService.getThing(id).map(GetResponse.apply)
    }
  }
```

### User-aware endpoint

```scala
private val view = apiEndpointBuilder.userAwareEndpoint().apiPath.get
  .out(apiResponseBody[ViewResponse])
  .apiServerLogic { implicit context =>
    val maybeUserId = context.userIdentity.map(_.userPrincipal)
    contentService.getContent(maybeUserId).map(ViewResponse.apply)
  }
```

### File download endpoint

```scala
private val download = apiEndpointBuilder.securedEndpoint().apiPath.get
  .in(query[String]("reportId"))
  .fileDownloadLogic { implicit context =>
    { case reportId =>
      reportService.generateReport(reportId).map { case (stream, filename) =>
        ApiFileDownloadResponse(filename = filename, fileExt = "pdf", data = stream)
      }
    }
  }
```

### Empty response

```scala
private val delete = apiEndpointBuilder.securedEndpoint().apiPath.delete
  .in(query[String]("id"))
  .out(apiResponseBody[ApiResponseData.Empty])
  .apiServerLogic { implicit context =>
    { case id =>
      someService.delete(id).map(_ => ApiResponseData.Empty)
    }
  }
```

## Wiring reminder

After adding a controller or moving packages:

1. Add any new gRPC client val to `ApplicationComponents`.
2. `wire[...]` the controller in `ApplicationComponents`.
3. Append it to `controllers`.
4. Compile so missing implicits and schema issues surface immediately.
