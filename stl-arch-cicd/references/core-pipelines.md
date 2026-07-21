# Core Pipelines

Use this as the canonical reference for Tracks G through L (and Track N pointers).

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

## Split pipelines (PR vs release)

- Prefer **two** definitions (templates under `assets/`):
  - `../assets/pr-pipeline.yml` → `azure-pipelines/pr-pipeline.yml` — PR-Agent + Build/Test on `AKSHosted` (Build Validation); Build `dependsOn` PRAgent
  - `../assets/release-pipeline.yml` → `azure-pipelines/release-pipeline.yml` — Build / Package / Artifacts / Deploy (no PR-Agent)
- Do not keep a combined `azure-pipelines/azure-pipelines.yml` that mixes PR-Agent with Package/Deploy.

## PR-Agent (Azure Repos / Track N)

- Out of band from develop/deploy Docker/Helm tracks: use Track N + `pr-pipeline.yml`.
- Image: `steycr.azurecr.cn/steycr/pr-agent:latest` after a one-time mirror from `codiumai/pr-agent` — AKSHosted times out on Docker Hub; do not use `ubuntu-latest` + `docker.io` for Stey services.
- Docker@2 login to the service `containerRegistry` before `docker pull`.
- Azure Repos requires Branch Policy Build Validation pointing at **pr-pipeline**; YAML `pr:` is not sufficient.
- Prefer `System.AccessToken` + build-service repo permissions over a personal PAT.
- OSS `review auto_approve` does not cast ADO votes — use Track N hard-gate vote:10.
- On each new PR pipeline run: reset prior Build Service vote to **0**, then fail on High-impact improve findings or missing templated `No major issues detected` (*PR Reviewer Guide*).
- For merge gating: required Build Service reviewer + Contribute to pull requests on that identity.
- Standards TOML: Azure Repo `WikiTechnical/.ci/pr-standards/` (master) via Items API + AccessToken — TDD/PRD/code `*-standards.toml`.

Details: `tracks/track-n-pr-agent-azure-devops.md` and `tracks/track-n-pr-agent-hard-gate.md`.
Fragments: `../assets/pr-agent-reset-vote.yml`, `../assets/pr-agent-hard-gate.yml`.

## Verification

- Use direct `rg` checks on the edited YAML.
- Report which stages still run on develop, publish Docker, or deploy after the change.
- Confirm Package is enabled on develop and Artifacts / Docker / Deploy remain gated off.
- For PR-Agent edits: confirm reset-vote step exists; templated `No major issues detected` approve path is present; High-impact / missing clean-review signal fail the stage.
