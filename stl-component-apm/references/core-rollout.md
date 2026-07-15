# Core Rollout

Use this as the canonical reference for APM rollout order, version baseline, service configuration, Helm wiring, stey-env pairing, and CI upload.

## Track routing

| Request | Tracks |
|---|---|
| Full rollout | A -> B -> C -> D -> E -> F -> G -> H -> I |
| Service repo only | A -> B -> C -> D -> E |
| Helm only | A -> F -> G -> I |
| stey-env or DSN only | A -> G -> I |
| Pipeline source upload only | A -> H |
| Troubleshooting | A -> J then rerun failing tracks |

Track A always owns repo scope and `git pull --rebase` on each edited repo.

## Version baseline

- `stey-common-apm >= 4.1.2` for per-request trace isolation.
- `stey-common-apm >= 4.0.6` for Logback bootstrap behavior.
- `stey-common-apm >= 4.0.2` for Logs and Metrics env keys.
- Pin Sentry Java with `dependencyOverrides`, using `sentry` `8.42.0` unless repo policy says newer.

## Service configuration

- Keep service `application.conf` free of nested `apm.sentry` config blocks.
- Initialize in this order: Logback bootstrap, eager `ApmManager`, then `Apm.init(release, dist)`.
- Use one `Sentry.init` path only.
- `APM_SENTRY_ENVIRONMENT` feeds Sentry UI environment naming; do not substitute app runtime env keys.

## Helm and stey-env

- `deployment.yaml` must wire the full `APM_*` block from chart values into pod env.
- Every target stey-env region file must carry the same 13 `APM_*` keys as the chart contract.
- Validate Helm and stey-env together with `scripts/check_apm_env_pairing.sh`.
- Use the assets as canonical examples, not ad hoc env fragments.

## CI source upload

When source context upload is in scope:

- Keep the upload step near the build artifacts it describes.
- Ensure auth tokens and release identifiers come from canonical pipeline variables.
- Treat upload failure as actionable evidence, not a silent best effort.

## Completion gate

- Each executed track is reported as Pass, Fail, or Skipped with reason.
- Any Helm or stey-env change includes parity-script output.
- Verification includes config evidence, runtime evidence, or an explicit blocker.
