# Runtime And Probes

Use this as the canonical reference for handlers, request tracing, logback, runtime request logs, and liveness behavior.

## Probe lifecycle

- `ApmProbe` is request or job scoped only.
- Use `apmManager.withProbe { ... }` to isolate work.
- Finish the transaction before `probe.close()`.
- Preserve `sentry-trace` and `baggage` across the request boundary only; never leak them to the next request.

## Error handling

- Expected business failures should be captured by the service's normal error path, not custom ad hoc wrappers.
- Unexpected failures should still reach Sentry capture.
- Avoid duplicate capture from both endpoint logic and outer handler layers.

## Logback and request logs

- `logback-prod.xml` should use `SteySentryLogbackAppender` only.
- Play services should point logging with `-Dlogger.resource=...`.
- Akka services should use `-Dlogback.configurationFile=...`.
- Runtime request logging should preserve useful request context without creating noise from health checks.

## Liveness behavior

- Liveness `GET /` should skip normal request logging.
- Liveness should avoid APM metric and transaction noise.
- Tapir liveness endpoints should prefer `serverLogicSuccess`, not `apiServerLogic`.

## Review checklist

- No reused probe instance across requests.
- No double `Sentry.init`.
- No duplicate exception capture path.
- No liveness noise in logs or metrics.
