---
name: stl-arch-cicd
description: >-
  Use for Stey Scala CI and CD maintenance across sbt launcher, aether publish,
  build versioning, Nexus dependency bumps, Azure Pipelines gates, Docker
  publish, Helm deploy arguments, AKSHosted pool fixes, and PR-Agent Azure
  DevOps Build Validation with Track N hard-gate auto-approve.
---

# Stey CI/CD Architecture

## Purpose

Keep Stey service build and deployment changes ordered across sbt, Nexus, pipeline gates, Docker publish, Helm deploy, agent pool wiring, and PR-Agent Azure DevOps setup.

## Workflow

1. Read Track A first for mandatory sync and scope classification.
2. Select the minimum track set from `references/tracks/track-index.md`.
3. Use `references/core-toolchain.md` for sbt, aether, versioning, Nexus, and dependency rules.
4. Use `references/core-pipelines.md` for develop, deploy, Docker, Helm, and pool rules.
5. Use Track N + copy-ready `assets/pr-pipeline.yml` / `assets/release-pipeline.yml` for the split Azure Pipelines layout (PR-Agent + Build/Test vs release CI/CD).
6. Keep edits within the selected track set unless a prerequisite track is required.
7. Finish with Track M evidence or troubleshooting notes.

## Guardrails

- Do not skip Track A.
- Do not invent Nexus URLs, credentials, or latest versions.
- Do not use the Stey dependency workflow to bump Akka or Slick.
- Keep YAML-only scope unless the user explicitly expands it.
- Develop publishes the API artifact (`*/publish` in Package); still no pipeline Artifacts drop, deploy, or Docker publish on develop.
- Deploy gates require both Build and Artifacts to be `Succeeded`; `Skipped` must not unlock deploy.
- `AKSHosted` is a named self-hosted pool with no `vmImage` or `poolVmImage`.
- Helm deploys use `--timeout 5m`, not `--atomic`.
- Prefer split pipelines from `assets/pr-pipeline.yml` + `assets/release-pipeline.yml` (PR-Agent + Build/Test vs release CI/CD; Build `dependsOn` PRAgent).
- PR-Agent image must be `steycr.azurecr.cn/steycr/pr-agent:latest` (ACR mirror); do not pull `codiumai/pr-agent` from Docker Hub on AKSHosted.
- Azure Repos PR-Agent requires Branch Policy Build Validation; YAML `pr:` alone is not enough.
- PR-Agent ADO auth should use `System.AccessToken` (build service), not a personal PAT, unless attribution to a human is intentional.
- Free OSS PR-Agent does not cast ADO Approve votes; use Track N’s scripted hard-gate vote:10 path, not `review auto_approve`.
- PR-Agent: on each run reset prior Build Service vote to 0; fail the stage on High-impact suggestions; auto-approve on templated `No major issues detected` (*PR Reviewer Guide*); do not require `[APPROVED]`.
- PR-Agent standards come from Azure Repo `WikiTechnical/.ci/pr-standards/` (master) via ADO Items API + `System.AccessToken`: TDD → `tdd-standards.toml`, PRD → `prd-standards.toml`, code → `code-standards.toml`.

## Tracks

| Track | Focus |
|---|---|
| A | Git sync and scope |
| B | sbt launcher |
| C | aether publish plugin |
| D | build versioning |
| E | Nexus metadata discovery |
| F | Stey dependency bumps |
| G | pipeline scope classification |
| H | develop CI gates |
| I | deploy stage gates |
| J | Docker publish gates |
| K | Helm deploy normalization |
| L | AKSHosted agent pool |
| M | verification and troubleshooting |
| N | PR-Agent Azure DevOps + hard-gate auto-approve |

## Reference Index

| When you need... | Read |
|---|---|
| Track order and common sequences | `references/tracks/track-index.md` |
| sbt, aether, versioning, Nexus, dependency bump rules | `references/core-toolchain.md` |
| Pipeline scope, gates, Docker, Helm, and pool rules | `references/core-pipelines.md` |
| PR-Agent enablement + hard-gate approve | `references/tracks/track-n-pr-agent-azure-devops.md` |
| Hard-gate signal details (High impact / `[APPROVED]` / vote reset) | `references/tracks/track-n-pr-agent-hard-gate.md` |
| Full PR pipeline template (PR-Agent + Build/Test) | `assets/pr-pipeline.yml` |
| Full release pipeline template (no PR-Agent) | `assets/release-pipeline.yml` |
| Symptoms, checks, and fallback routing | `references/troubleshooting.md` |
| Copy-ready YAML templates / fragments | `assets/` |
| Nexus discovery script | `scripts/fetch_stey_nexus_latest.sh` |

## Activation Keywords

`sbt`, `aether`, `Nexus`, `fetch_stey_nexus_latest.sh`, `libraryDependencies`, `Azure Pipelines`, `develop CI`, `docker:publish`, `HelmDeploy`, `AKSHosted`, `poolVmImage`, `PR-Agent`, `pr-agent`, `hard gate`, `Build Validation`, `System.AccessToken`, `DeepSeek`, `auto-approve`, `[APPROVED]`, `vote:10`, `WikiTechnical`, `.ci/pr-standards`, `tdd-standards`, `prd-standards`, `code-standards`, `steycr`, `prAgentImage`, `docker.io`, `codiumai/pr-agent`, `pr-pipeline.yml`, `release-pipeline.yml`.
