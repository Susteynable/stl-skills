# Track C - Auto Route

Read `../core-architecture.md`.
Run Track D after any endpoint-val rename.

Verify:

- `.apiPath` path matches package segments plus endpoint val.
- Only `com`, `stey`, and `controllers` are stripped from the package.
- Multi-word route folders use camelCase package names.
- Nested legacy segments move into subpackages, not long endpoint val names.
- Generated paths are checked against legacy route expectations when migrating.

Examples:

| Package | Endpoint val | Result |
|---|---|---|
| `...controllers.wo.allWorkOrders` | `search` | `/api/console/wo/all-work-orders/search` |
| `...controllers.iotv2.cabinetLockTemplate.device` | `create` | `/api/console/iotv2/cabinet-lock-template/device/create` |
