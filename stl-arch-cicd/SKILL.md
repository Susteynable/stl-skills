---
name: stl-arch-cicd
description: >-
  Use for Stey Scala CI and CD maintenance across sbt launcher, aether publish,
  build versioning, Nexus dependency bumps, Azure Pipelines gates, Docker
  publish, Helm deploy arguments, and AKSHosted pool fixes.
---

# Stey CI/CD Architecture

## Purpose

Keep Stey service build and deployment changes ordered across sbt, Nexus, pipeline gates, Docker publish, Helm deploy, and agent pool wiring.

## Workflow

1. Read Track A first for mandatory sync and scope classification.
2. Select the minimum track set from `references/tracks/track-index.md`.
3. Use `references/core-toolchain.md` for sbt, aether, versioning, Nexus, and dependency rules.
4. Use `references/core-pipelines.md` for develop, deploy, Docker, Helm, and pool rules.
5. Keep edits within the selected track set unless a prerequisite track is required.
6. Finish with Track M evidence or troubleshooting notes.

## Guardrails

- Do not skip Track A.
- Do not invent Nexus URLs, credentials, or latest versions.
- Do not use the Stey dependency workflow to bump Akka or Slick.
- Keep YAML-only scope unless the user explicitly expands it.
- Develop publishes the API artifact (`*/publish` in Package); still no pipeline Artifacts drop, deploy, or Docker publish on develop.
- Deploy gates require both Build and Artifacts to be `Succeeded`; `Skipped` must not unlock deploy.
- `AKSHosted` is a named self-hosted pool with no `vmImage` or `poolVmImage`.
- Helm deploys use `--timeout 5m`, not `--atomic`.

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

## Reference Index

| When you need... | Read |
|---|---|
| Track order and common sequences | `references/tracks/track-index.md` |
| sbt, aether, versioning, Nexus, dependency bump rules | `references/core-toolchain.md` |
| Pipeline scope, gates, Docker, Helm, and pool rules | `references/core-pipelines.md` |
| Symptoms, checks, and fallback routing | `references/troubleshooting.md` |
| Copy-ready YAML fragments | `assets/` |
| Nexus discovery script | `scripts/fetch_stey_nexus_latest.sh` |

## Activation Keywords

`sbt`, `aether`, `Nexus`, `fetch_stey_nexus_latest.sh`, `libraryDependencies`, `Azure Pipelines`, `develop CI`, `docker:publish`, `HelmDeploy`, `AKSHosted`, `poolVmImage`.
