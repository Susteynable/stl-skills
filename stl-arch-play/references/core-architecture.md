# Core Architecture

Use this as the canonical reference for Play + Tapir boot, DSL ownership, auto-routing, and error flow.

## Target shape

```text
application.conf
  play.application.loader = com.stey.api.<service>.ApplicationLoader
        |
        v
ApplicationLoader.load(context)
        |
        v
ApplicationComponents(context).application
  |- component traits (APM, Redis, OSS, I18n, ...)
  |- gRPC client vals
  |- wire[ApiEndpointBuilder]
  |- wire[Controller] x N
  |- controllers.flatMap(_.taggedEndpoints)
  |- Router.from(ApiEndpointInterpreter.interpret(env, endpoints))
  |- httpFilters
  `- httpErrorHandler
```

Tapir APIs do not use `Router.scala`, `resources/routes`, or a Guice `Module` for endpoint wiring.

## Boot and wiring

- `application.conf` sets `play.application.loader = com.stey.api.<service>.ApplicationLoader`.
- `ApplicationLoader` configures logging, sets JVM boot concerns such as timezone if needed, and returns `new ApplicationComponents(context).application`.
- `ApplicationComponents` owns shared traits, gRPC client vals, `ApiEndpointBuilder`, controller wiring, router construction, filters, and error handler.
- Controllers may keep `@Inject()` on constructors, but dependency resolution is Macwire from `ApplicationComponents` scope.

### Wiring checklist

- `build.sbt` includes Macwire macros in `provided` scope.
- gRPC clients are `val`s on `ApplicationComponents`, not providers or Guice bindings.
- `val apiEndpointBuilder = wire[ApiEndpointBuilder]` is shared.
- Each controller is `wire[..., Controller]` and added to `controllers: List[ApiEndpointController]`.
- Router is `Router.from(ApiEndpointInterpreter.interpret(env = env, endpoints = controllers.flatMap(_.taggedEndpoints)))`.
- `httpFilters` and `httpErrorHandler` live on `ApplicationComponents`.

### Remove on Tapir migration

- `Router.scala extends SimpleRouter`
- `src/main/resources/routes`
- Guice `Module.scala` or provider files for gRPC/Redis/OSS
- `play.modules.enabled += ...Module`
- `play.http.filters = ...Filters`
- `play.http.errorHandler = ...ErrorHandler`
- `routesImport` in `build.sbt` when no Play routes file remains

## DSL file map

Typical DSL ownership under `.../dsl/`:

| File | Purpose |
|---|---|
| `ApiTapirDSL.scala` | Adds `.apiServerLogic` / `.fileDownloadLogic`; owns tracing, i18n context injection, and error mapping |
| `ApiEndpointBuilder.scala` | Base endpoint builders: `unsecuredEndpoint`, `securedEndpoint(...)`, `userAwareEndpoint(...)` |
| `ApiEndpointController.scala` | Base trait for controllers, schema derivation, common helpers, `taggedEndpoints` |
| `ApiEndpointInterpreter.scala` | Interprets endpoints to a router and owns Swagger UI path prefix |
| `ApiRequest*.scala` / `ApiResponse*.scala` | Envelope models and marker traits |
| `ApiError*.scala` | Error model, exception handler, decode failure handler |
| `ApiRequestContext.scala` | `Unsecured`, `Secured`, `UserAware` request contexts |
| `ApiFileDownloadResponse.scala` | File-download response DTO |

## Auto-routing

`.apiPath` derives the URL from package segments plus endpoint val name.

- Strip only `com`, `stey`, and `controllers` from the package.
- Keep service prefixes such as `api`, `web`, and `console`.
- Kebab-case every remaining package segment.
- Kebab-case the endpoint val and append it as the final path segment.
- Multi-word folders must be camelCase so kebab-case expansion is correct.
- Legacy nested path segments belong in subpackages, not long endpoint val names.

Examples:

| Package | Endpoint val | Result |
|---|---|---|
| `...controllers.wo.allWorkOrders` | `search` | `/api/console/wo/all-work-orders/search` |
| `...controllers.iotv2.cabinetLockTemplate.device` | `create` | `/api/console/iotv2/cabinet-lock-template/device/create` |

## Security and error flow

Security modes:

| Mode | Builder | Context |
|---|---|---|
| Public | `unsecuredEndpoint` | `UnsecuredApiRequestContext` |
| Secured | `securedEndpoint(permissions)` | `SecuredApiRequestContext` |
| User-aware | `userAwareEndpoint(...)` | `UserAwareApiRequestContext` |

Handling rules:

- Business failures are thrown as `I18nBusinessException` and mapped to `ApiError` by the DSL.
- Auth failures propagate to `ApiErrorHandler` and become HTTP 401.
- Permission failures become HTTP 403.
- Decode failures go through `ApiDecodeFailureHandler` and become HTTP 400 without noisy Sentry reports.
- Unexpected failures are captured by the APM/Sentry path and returned as generic 500 errors.

## File downloads

- Use `.fileDownloadLogic` for download endpoints.
- Return `ApiFileDownloadResponse`.
- Cross-origin clients that need the filename must see `Content-Disposition` in `play.filters.cors.exposedHeaders`.
- Swagger path prefixes remain owned by `ApiEndpointInterpreter`, not the `interpret(...)` call site.

## Audit red flags

- `class Router extends SimpleRouter`
- `bind[Stey*ServiceClient].toProvider[...]`
- `ApiEndpointInterpreter.interpret(..., pathPrefix = ...)`
- New controller not added to the `controllers` list
- Manual hard-coded paths where `.apiPath` should own the route
