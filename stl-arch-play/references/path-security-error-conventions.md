# Path, Security, and Error Conventions

Use this when the task is about endpoint mode, manual-path exceptions, or error/decode behavior rather than full architecture.

## Path

- Prefer `.apiPath`; it owns the runtime path for normal APIs.
- Use manual paths only for explicit callback or external-contract endpoints.
- Package folders are camelCase; endpoint vals provide the final path segment.
- Legacy nested segments should move into subpackages, not long endpoint val names.

## Security modes

| Mode | Builder | Auth |
|---|---|---|
| Public | `unsecuredEndpoint` | none |
| Secured | `securedEndpoint(permissions)` | bearer required |
| User-aware | `userAwareEndpoint(...)` | bearer optional |

## Error handling

- Throw `I18nBusinessException` for business failures.
- Let `ApiErrorHandler` map auth failures to 401 and permission failures to 403.
- Let `ApiDecodeFailureHandler` map malformed input to 400.
- Avoid manual `try/catch` inside `.apiServerLogic` unless the endpoint deliberately bypasses the normal envelope contract.
