# Akka test remoting ports (dynamic `canonical.port`)

**Scope:** `src/test/**` only. **Production `application.conf` is out of scope** unless the user explicitly requests it.

**Policy:** set **`akka.remote.artery.canonical.port = 0`** once in the shared **test** `reference.conf`; remove per-spec port overrides so parallel specs bind on ephemeral ports.

## Steps

### T1 — Locate explicit test port usage

Search test Scala and resources for:

- `akka.remote.artery.canonical.port=<number>`
- `akka.remote.artery.canonical.port = <number>`
- `ConfigFactory.parseString(...)` with a fixed port in testkit config

Prioritize **`src/test/scala`** and **`src/test/resources/reference.conf`**.

### T2 — Shared dynamic port in test `reference.conf`

```hocon
akka.remote.artery.canonical.port = 0
```

Place it with other top-level Akka test overrides (Stey-style, e.g. SteyCms).

### T3 — Remove spec-level port overrides

From:

```scala
ScalaTestWithActorTestKit(
  ConfigFactory.parseString("""akka.remote.artery.canonical.port=25522""")
    .withFallback(EventSourcedBehaviorTestKit.config)
)
```

To:

```scala
ScalaTestWithActorTestKit(EventSourcedBehaviorTestKit.config)
```

Handle multi-line `ConfigFactory.parseString(...).withFallback(...)` variants — same chain **minus** the port.

### T4 — Clean imports

Remove unused **`import com.typesafe.config.ConfigFactory`** when no longer referenced.

### T5 — Verify no hard-coded test ports

Search **`src/test/scala`** for numeric `canonical.port` assignments. Expected: **no** fixed-port matches.

### T6 — Run targeted tests

Run at least one broad spec and one command-handler (or focused) spec. Confirm pass; ephemeral bind shows in remoting logs.

**Completion report:** files changed, port search result, test commands and pass/fail.

## Done checklist

- [ ] **`canonical.port = 0`** in test `reference.conf`.
- [ ] Per-spec overrides removed; imports cleaned.
- [ ] No hard-coded test remoting ports under **`src/test`**.
- [ ] Targeted tests run and reported.

## Troubleshooting

- **Port in use / flaky parallel tests:** confirm T2 (`canonical.port = 0` in test `reference.conf`); specs must not pin ports (T1, T3).
- **Wrong config in scope:** ensure test `reference.conf` is on the classpath; check `withFallback` order.
- **Production remoting issues:** out of scope here — open a dedicated production-config task.
- **Nexus / dep bumps do not fix this:** see **stl-arch-cicd** Track B.
