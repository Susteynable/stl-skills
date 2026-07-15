# Track D - DTO Naming

Read `../controller-patterns.md`.
Run after Track C whenever endpoint vals or packages move.

Verify:

- DTO simple names mirror the endpoint val in PascalCase.
- DTOs live in the same package as the controller.
- Package context replaces redundant domain prefixes.
- Shared enums and common types stay in the parent package when reused.
- Upstream gRPC types are aliased on import instead of renamed.

Examples:

| Endpoint val | Request | Response |
|---|---|---|
| `create` | `CreateRequest` | `CreateResponse` |
| `search` | `SearchRequest` when body exists | `SearchResponse` |
| `list` | none | `ListResponse` |
| `delete` | only if needed | `ApiResponseData.Empty` |
