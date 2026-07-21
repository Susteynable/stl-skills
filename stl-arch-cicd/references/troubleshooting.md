# Troubleshooting

Use this for symptom-first routing.

| Symptom | Check first |
|---|---|
| sbt fails before pipeline logic matters | Tracks B and C |
| Latest Stey dependency cannot be found | Track E script path, resolver, credentials |
| Script reports an older version than Nexus release metadata | Track E parser order: prefer `<release>` over stale `<latest>` |
| Develop does not publish API jar (Package skipped) | Tracks G and H — Package must not exclude develop |
| Develop packages Docker / Artifacts drop / deploys | Tracks G, H, J, I — only Package(+Build) should run on develop |
| Deploy approval unlocks when upstream stages are skipped | Track I |
| Docker publish runs on the wrong branch | Track J |
| Helm deploy arguments drift | Track K |
| Pipeline uses image selection with AKSHosted | Track L |
| Wrong standards applied (TDD rules on code PR, etc.) | Track N — set `STANDARDS_FILE` to matching WikiTechnical `.ci/pr-standards` file (tdd / prd / code) |
| PR-Agent never runs on Azure Repos PR | Track N — missing Build Validation on target branch |
| `registry-1.docker.io` / Docker Hub i/o timeout pulling `codiumai/pr-agent` | Track N — AKSHosted cannot reach docker.io; mirror to `steycr.azurecr.cn/steycr/pr-agent:latest`, Docker@2 login, set `prAgentImage` |
| `docker pull` not-found for `steycr.../pr-agent` | Track N — one-time mirror not pushed yet (see Track N mirror commands) |
| PR Build Validation runs Package/Deploy | Track N — Build Validation must point at `pr-pipeline.yml`, not `release-pipeline.yml` |
| Branch CI missing after split | Track N/G — copy `assets/release-pipeline.yml` and retarget the release pipeline definition |
| Build/Test runs before PR-Agent finishes | Track N — `Build` must `dependsOn: PRAgent` with `and(succeeded(), …)` |
| Build Validation still points at old `azure-pipelines.yml` | Track N — retarget policy to `pr-pipeline.yml` |
| `SYSTEM_PULLREQUEST_PULLREQUESTID: unbound variable` | Track N — manual run / not a PR build; gate on `Build.Reason` |
| `can't open file '.../pr_agent/cli.py'` | Track N — Docker `-w` overrode image WORKDIR; mount config only |
| `Invalid URL 'org/org/_apis': No scheme supplied` | Track N — `AZURE_DEVOPS__ORG` must be full `System.CollectionUri` |
| PR-Agent comments appear as a human | Track N — still using personal PAT; switch to `System.AccessToken` |
| PR-Agent 401/403 posting comments | Track N — build service missing Contribute to pull requests |
| PR auto-approved despite High-impact suggestions | Track N — fail stage on High impact even if review template is clean |
| PR-Agent stage green without templated clean review | Track N — require `No major issues detected` in *PR Reviewer Guide* |
| PR-Agent stage fails on every PR after hard gate | Track N — confirm review emits templated `No major issues detected` when clean |
| Later commit keeps Approve from earlier pipeline run | Track N — reset Build Service vote to 0 at pipeline start |
| `review auto_approve` runs but vote stays 0 | Expected on free OSS — use Track N scripted approve, not native auto_approve |
| Auto-approve stage fails despite clean review | Track N — require `No major issues detected` + *PR Reviewer Guide* and PipelineStartTime scoping |
| Vote API 401/403 after approval signal | Track N — grant Contribute to pull requests to the identity that authored the comment |
| Required reviewer still blocks after green build | Track N — Build Validation ≠ Approve vote; add required Build Service reviewer policy |

Recovery flow:

1. Re-run Track A scope classification.
2. Re-check the directly responsible track and its prerequisite track.
3. Verify the final YAML or sbt evidence with explicit commands, not memory.
