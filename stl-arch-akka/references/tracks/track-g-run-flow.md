# Track G - Run Flow

Read:

- `../topics/run-pattern.md`
- `../examples/aggregate-architecture-templates.md`

Checklist:

- [ ] `*EventInterceptor` and command result support are colocated in one `interceptors/` file.
- [ ] `ResultSupport` and `ResultWithRunSupport` are defined and used through `intercept(...).reply(replyTo)`.
- [ ] `Run.scala` (or `runhandlers/Run.scala` if split), `RunDispatcher.scala`, and `runhandlers/RunHandler.scala` are present where runs exist.
- [ ] `SetupModes.Off` uses default run dispatcher/handler; non-`Off` setup modes use no-op run wiring.
- [ ] Each new `Run` type is routed in dispatcher and handler.
- [ ] Run handlers do not persist aggregate events or write projections.
