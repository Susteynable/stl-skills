# Track B - Controller DSL

Read `../controller-patterns.md`.

Verify:

- Controller extends `ApiEndpointController`.
- `apiEndpointBuilder` is the first constructor dependency.
- Endpoint starts from the correct builder and uses `.apiPath` unless intentionally custom.
- Envelope APIs use `apiRequestBody[...]` / `apiResponseBody[...]`.
- Logic uses `.apiServerLogic`.
- `def endpoints` lists every endpoint; `def apiGroup` is set when needed.
- DTOs live in the same package and have Play JSON formats.
