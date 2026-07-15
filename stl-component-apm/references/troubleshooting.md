# Troubleshooting

Use this for symptom-first routing.

| Symptom | Check first |
|---|---|
| Events reach Sentry Errors but Logs or Metrics are empty | Env keys, version baseline, logback appender, liveness noise |
| Trace IDs appear to leak between requests | Probe scoping and close order |
| Sentry environment is wrong | `APM_SENTRY_ENVIRONMENT` source and Helm/stey-env pairing |
| Source bundle upload missing | CI upload track and token/release wiring |
| Runtime has no APM env vars | Chart wiring and stey-env parity |

Recovery flow:

1. Reconfirm scope and edited repos.
2. Re-run the failing track plus its prerequisite track.
3. Check chart and stey-env parity when env behavior is wrong.
4. Separate config defects from runtime defects before changing code.
