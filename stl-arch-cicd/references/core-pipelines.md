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

## Split pipelines (PR vs release)

- Prefer **two** definitions (templates under `assets/`):
  - `../assets/pr-pipeline.yml` → `azure-pipelines/pr-pipeline.yml` — PR-Agent + Build/Test on `AKSHosted` (Build Validation); Build `dependsOn` PRAgent
  - `../assets/release-pipeline.yml` → `azure-pipelines/release-pipeline.yml` — Build / Package / Artifacts / Deploy (no PR-Agent)
- Do not keep a combined `azure-pipelines/azure-pipelines.yml` that mixes PR-Agent with Package/Deploy.

## PR-Agent (Azure Repos)

- Out of band from develop/deploy Docker/Helm tracks: use Track N + `pr-pipeline.yml`.
- Image: `steycr.azurecr.cn/steycr/pr-agent:latest` after a one-time mirror from `codiumai/pr-agent` — AKSHosted times out on Docker Hub; do not use `ubuntu-latest` + `docker.io` for Stey services.
- Docker@2 login to the service `containerRegistry` before `docker pull`.
- Azure Repos requires Branch Policy Build Validation pointing at **pr-pipeline**; YAML `pr:` is not sufficient.
- Prefer `System.AccessToken` + build-service repo permissions over a personal PAT.
- OSS `review auto_approve` does not cast ADO votes — use Track N scripted dual-signal vote:10.
- Match `[APPROVED]` only as its **own line** (strip fenced/HTML code) to avoid false positives from cited pipeline YAML.
- For merge gating: required Build Service reviewer + Contribute to pull requests on that identity.
- Standards TOML: Azure Repo `WikiTechnical/.ci/pr-standards/` (master) via Items API + AccessToken — TDD/PRD/code `*-standards.toml`.

## Verification

- Use direct `rg` checks on the edited YAML.
- Report which stages still run on develop, publish Docker, or deploy after the change.
- Confirm Package is enabled on develop and Artifacts / Docker / Deploy remain gated off.
