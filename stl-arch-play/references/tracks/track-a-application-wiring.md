# Track A - Application Wiring

Read `../core-architecture.md`.

Verify:

- Service boots through `ApplicationLoader` -> `ApplicationComponents`.
- No `Router.scala`, Play `routes`, or Guice `Module` owns API wiring.
- gRPC clients are `val`s on `ApplicationComponents`.
- `apiEndpointBuilder = wire[ApiEndpointBuilder]` is shared.
- Each controller is wired and included in `controllers: List[ApiEndpointController]`.
- Router comes from `ApiEndpointInterpreter.interpret(env, endpoints)`.
