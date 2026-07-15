---
name: stl-component-apm
description: >-
  Use when wiring, auditing, or troubleshooting Stey JVM APM and Sentry across
  service config, logback, Helm APM env, stey-env pairing, source upload, or
  empty Logs and Metrics in Sentry UI.
---

# Stey Component APM

## Purpose

Keep Stey JVM APM changes ordered across service repo, Helm chart, stey-env, and optional CI upload without dropping required runtime or trace-isolation rules.

## Workflow

1. Classify scope with `references/tracks/track-index.md`.
2. Read Track A first for repo scope and mandatory git sync.
3. Run only the applicable tracks in order and report skipped tracks with a reason.
4. Use `references/core-rollout.md` for baseline wiring and env rules.
5. Use `references/runtime-and-probes.md` for probe lifecycle, handlers, logback, and liveness rules.
6. When Helm or stey-env changes, run `scripts/check_apm_env_pairing.sh`.
7. Finish with verification or troubleshooting evidence.

## Guardrails

- No `apm { sentry { ... } }` block in service `application.conf`.
- `APM_SENTRY_ENVIRONMENT` is the Sentry environment source.
- Chart and all stey-env region files must carry the same 13 `APM_*` keys.
- Keep `stey-common-apm` and Sentry versions aligned before runtime fixes.
- `ApmProbe` is request or job scoped only; do not reuse probes across requests.
- `logback-prod.xml` uses `SteySentryLogbackAppender` only.
- Liveness `GET /` must avoid normal request logging and metrics.
- No pod restart unless the user asks.

## Tracks

| Track | Focus |
|---|---|
| A | Scope and git sync |
| B | Library and version baseline |
| C | Service configuration |
| D | Logback and runtime logs |
| E | Error and probe lifecycle |
| F | Helm env wiring |
| G | stey-env pairing |
| H | CI source upload |
| I | Verification and rollout |
| J | Troubleshooting |

## Reference Index

| When you need... | Read |
|---|---|
| Track order and scope routing | `references/tracks/track-index.md` |
| Baseline rollout, versions, service config, Helm, stey-env, CI upload | `references/core-rollout.md` |
| Probe lifecycle, handlers, logback, request logs, liveness behavior | `references/runtime-and-probes.md` |
| Symptoms and recovery routes | `references/troubleshooting.md` |
| Canonical chart env block | `assets/deployment-apm-env.yaml` |
| Canonical stey-env block | `assets/stey-env-apm-block.yaml` |
| Chart/stey-env parity check | `scripts/check_apm_env_pairing.sh` |

## Activation Keywords

`Sentry`, `APM_SENTRY`, `stey-common-apm`, `logback-prod`, `sentry-cli`, `stey-env`, `APM_SENTRY_ENVIRONMENT`, `ApmProbe`, `sentry-trace`, `baggage`, `empty metrics`, `trace leak`.
