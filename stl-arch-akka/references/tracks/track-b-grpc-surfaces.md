# Track B - gRPC Surfaces

Read:

- `../topics/grpc-surface-delegate-extraction.md`
- `../topics/inline-boundary-remap.md`
- Delegate coding style (private helpers, assign-then-yield, Internal orchestration): skill **`stl-convention`**
- `../case-studies/grpc-surface-steycrs-case-study.md` when handling large extraction work.

Checklist:

- [ ] Large `*ServiceImpl` classes are wiring shells or have a planned delegate extraction.
- [ ] Each extracted RPC has one delegate object/file.
- [ ] Delegates use capability-typed `SurfaceContext`; no implicit `SurfaceContext`.
- [ ] Delegate capability type `C` matches actual `ctx.*` usage.
- [ ] Request-scoped values (`ActorSystem`, `ApmManager`, metadata-derived user principal, transactions, execution context, logger) remain implicit or method-local; they are not fields on `SurfaceContext`.
- [ ] Shared service dependencies are wired once through `SurfaceContext`.
- [ ] Delegate extraction does not rewrite business logic during the move.
- [ ] Delegate coding shape follows **`stl-convention`** (private helpers, assign-then-yield, write-path via `*Internal`).
- [ ] Read/write RPC mapping is inline in delegates or `*ServiceImpl`; no table/state companion `to*Grpc`/`from*Grpc`/`optTo*Grpc` helpers or other shared cross-tier converters.
