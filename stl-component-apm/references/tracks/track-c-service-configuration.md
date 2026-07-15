# Track C - Service Configuration

Read `../core-rollout.md`.

Verify:

- `application.conf` has no forbidden nested APM config.
- Init order is correct.
- `ApmManager` wiring is eager where required.
