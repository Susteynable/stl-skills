# Display-only tags and logs

Tags and log artifacts are **display / search / audit surfaces**. They must not drive write-path business decisions.

## Scope

| Kind | Typical names | Allowed uses | Forbidden uses |
|------|---------------|--------------|----------------|
| Tags | `*Tag`, `*Tags`, `reservationTags`, `*TagSetEvent` / `*TagUnsetEvent`, space/config tags | UI badges, search filters, list/detail projection, Kafka display fields | Command-handler guards, inventory/rate/availability decisions, billing, status transitions, interceptors that branch on tag membership |
| Logs | `*LogCreateEvent`, `*log` / `*_log` projection tables, reservation/rate-change log search | Auditing, history timelines, read-path search APIs | Aggregate validation, command orchestration, rebuild/setup source of truth, write-path lookups that decide whether a command may proceed |

## Rules

1. **Business facts live on first-class state.** Prefer dedicated fields/flags (e.g. `isRoomTypePaidUpgraded`, `isRoomTypeUpgraded`) over tag membership (`reservationTags.contains(RoomTypePaidUpgraded)`).
2. **Handlers may emit tag/log events as side effects** after the real decision is made from domain state. Emitting a display tag does not make that tag a business source of truth.
3. **Never read tags or log tables to validate or branch** in command handlers, run handlers, interceptors, internal write orchestration, or setup/rebuild loaders.
4. **Log events are projection-bound.** Prefer no-op (or audit-only) state handlers; do not fold log payloads into aggregate state used by later commands.
5. **When a UI label and a business rule coincide**, keep both: mutate the domain flag/field for logic, and optionally set/unset the matching tag for display/search — never reverse that dependency.

## Review greps

```text
reservationTags\.contains|tags\.contains|TagTypes\.
\*LogCreateEvent|from.*[Ll]og|join.*_log|SteyCrs.*Log
```

Fail the review when a match appears inside command-handler validation, interceptor predicates, or write-path internal methods (emit-only sites are fine).

## Checklist

- [ ] No command/interceptor/run/internal write path branches on tag membership.
- [ ] No write path reads `*log` tables or log-event payloads to decide outcomes.
- [ ] Domain flags/fields exist for any rule that also has a display tag.
- [ ] Tag/log events are emit-only after the domain decision; comments may note `display/search tag only` when the pairing is non-obvious.
