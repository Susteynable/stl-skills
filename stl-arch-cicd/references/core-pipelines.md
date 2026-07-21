# Core Pipelines

Use this as the canonical reference for Tracks G through L.

## Scope classification

Canonical backend pipelines treat `develop` as **CI + API publish**.

| On `develop` | Action |
|---|---|
| Build / Test | Run |
| Package (`stey-*-api/publish` / Nexus jar) | Run |
| Artifacts (pipeline `drop` for Helm) | Skip |
| Docker publish | Skip |
| Deploy | Skip |

- Scope classification should happen before editing individual conditions.

## Develop and deploy gates

- **Package** must run on develop with `condition: succeeded()` (or equivalent that does **not** exclude `refs/heads/develop`) so dependent services can consume the published API jar from develop pushes.
- **Artifacts** should skip develop with `succeeded()`-style gating that excludes `refs/heads/develop` (Helm drop is only needed for deploy branches).
- Deploy approval must require both Build and Artifacts to be `Succeeded`.
- `Skipped` must never be enough to unlock deployment.

## Docker publish

- Publish Docker only on the intended long-lived branches, normally `test` and `master`.
- Keep Docker conditions in sync with upstream build and artifact state.
- Do **not** Docker-publish on develop even when Package runs.

## Helm deploy

- Normalize deploy arguments to `--timeout 5m`.
- Remove `--atomic` unless the repo has an explicit exception.
- Keep argument changes isolated from unrelated stage logic.

## AKSHosted pool

- Use `pool.name: AKSHosted`.
- Remove `vmImage` or `poolVmImage` when the job runs on that named pool.

## PR-Agent hard gate (Track N)

PR Build Validation runs PR-Agent then a **pipeline** hard gate (not TOML-only):

| Signal | Action |
|---|---|
| New PR pipeline run starts | Reset Build Service vote to **0** (clear stale Approve) |
| This run: *PR Code Suggestions* with Impact **High** or importance **≥ 9** | **Fail** PR-Agent stage |
| This run: no own-line `[APPROVED]` in review | **Fail** PR-Agent stage |
| Templated `No major issues detected` alone | **Not** an approve signal |
| `[APPROVED]` present and no High impact | Cast vote:10 |

Details: `tracks/track-n-pr-agent-hard-gate.md`. Template: `../assets/pr-agent-hard-gate.yml`.

## Verification

- Use direct `rg` checks on the edited YAML.
- Report which stages still run on develop, publish Docker, or deploy after the change.
- Confirm Package is enabled on develop and Artifacts / Docker / Deploy remain gated off.
- For PR-Agent edits: confirm `TEMPLATED_OK` / templated approve path is gone and High-impact / missing `[APPROVED]` fail the stage.
