# Track E - Path, Security, Errors

Read `../path-security-error-conventions.md`.

Verify:

- Public endpoints use `unsecuredEndpoint`.
- Authenticated endpoints use `securedEndpoint(...)`.
- Optional-auth endpoints use `userAwareEndpoint(...)`.
- Manual paths exist only for deliberate callback or external-contract cases.
- Business failures are `I18nBusinessException`.
- Auth, permission, and decode failures rely on the standard handlers.
