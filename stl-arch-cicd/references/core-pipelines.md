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

## PR-Agent (Azure Repos)

- Out of band from develop/deploy Docker/Helm tracks: use Track N.
- Azure Repos requires Branch Policy Build Validation; YAML `pr:` is not sufficient.
- Prefer `System.AccessToken` + build-service repo permissions over a personal PAT.
- OSS `review auto_approve` does not cast ADO votes — use Track N scripted dual-signal vote:10.
- For merge gating: required Build Service reviewer + Contribute to pull requests on that identity.
- Standards TOML (`GLOBAL_CONFIG_URL`): TDD → `tdd-standards.toml`, PRD → `prd-standards.toml`, code → `code-standards.toml` under `Susteynable/stl-pr-standards`.
- Template: `../assets/pr-agent-azure-pipelines.yml`.

## Verification

- Use direct `rg` checks on the edited YAML.
- Report which stages still run on develop, publish Docker, or deploy after the change.
- Confirm Package is enabled on develop and Artifacts / Docker / Deploy remain gated off.
