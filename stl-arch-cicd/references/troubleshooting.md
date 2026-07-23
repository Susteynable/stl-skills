# Troubleshooting

Use this for symptom-first routing.

| Symptom | Check first |
|---|---|
| sbt fails before pipeline logic matters | Tracks B and C |
| Compile OOM / GC thrash with `Heap: … max 1.00GB` on AKSHosted | Track B — missing tracked `.jvmopts` (`-Xmx4G`); do not gitignore it; not a stale checkout of a deleted local file |
| Compile OOM despite `.jvmopts` `-Xmx4G` | Track B — project `.sbtopts` `-J-Xmx…` overriding heap, or agent memory too small for 4G |
| Latest Stey dependency cannot be found | Track E script path, resolver, credentials |
| Script reports an older version than Nexus release metadata | Track E parser order: prefer `<release>` over stale `<latest>` |
| Develop does not publish API jar (Package skipped) | Tracks G and H — Package stage must be `condition: succeeded()`; do not put `ne(...develop)` on the stage |
| Develop packages Docker / Artifacts drop / deploys | Tracks G, H, J, I — Package(+Build) may run on develop; Docker login/publish and Artifacts/Deploy must stay gated |
| Deploy approval unlocks when upstream stages are skipped | Track I |
| Docker publish runs on the wrong branch | Track J |
| Helm deploy arguments drift | Track K |
| Pipeline uses image selection with AKSHosted | Track L |
| Wrong standards applied (TDD rules on code PR, etc.) | Track N — set `STANDARDS_FILE` to matching WikiTechnical `.ci/pr-standards` file (tdd / prd / code) |
| PR-Agent never runs on Azure Repos PR | Track N — missing Build Validation on target branch |
| PR-Agent skipped on develop↔test↔master PR | Expected — promotion path Direct-Approves; feature branches still get full review |
| Promotion PR not auto-approved | Track N — confirm detect sets `isPromotionPr=true`; Build Service on reviewers (or connectionData fallback); Contribute to pull requests |
| `registry-1.docker.io` / Docker Hub i/o timeout pulling `codiumai/pr-agent` | Track N — AKSHosted cannot reach docker.io; mirror to `steycr.azurecr.cn/steycr/pr-agent:latest`, Docker@2 login, set `prAgentImage` |
| `docker pull` not-found for `steycr.../pr-agent` | Track N — one-time mirror not pushed yet (see Track N mirror commands) |
| PR Build Validation runs Package/Deploy | Track N — Build Validation must point at `pr-pipeline.yml`, not `release-pipeline.yml` |
| Branch CI missing after split | Track N/G — copy `assets/release-pipeline.yml` and retarget the release pipeline definition |
| Build/Test runs before PR-Agent finishes | Track N — `Build` must `dependsOn: PRAgent` with `and(succeeded(), …)` |
| Build Validation still points at old `azure-pipelines.yml` | Track N — retarget policy to `pr-pipeline.yml` |
| Auto-approve from quoted `MARKER = "[APPROVED]"` in review | Track N — require own-line `[APPROVED]` and strip fenced/HTML code before match |
| `SYSTEM_PULLREQUEST_PULLREQUESTID: unbound variable` | Track N — manual run / not a PR build; gate on `Build.Reason` |
| `can't open file '.../pr_agent/cli.py'` | Track N — Docker `-w` overrode image WORKDIR; mount config only |
| `Invalid URL 'org/org/_apis': No scheme supplied` | Track N — `AZURE_DEVOPS__ORG` must be full `System.CollectionUri` |
| PR-Agent comments appear as a human | Track N — still using personal PAT; switch to `System.AccessToken` |
| PR-Agent 401/403 posting comments | Track N — build service missing Contribute to pull requests |
| PR auto-approved despite High-impact suggestions | Track N — drop templated `No major issues detected` approve path; fail on High impact |
| PR-Agent stage green without `[APPROVED]` | Track N — convention gate must fail the stage |
| PR-Agent stage fails on every PR after hard gate | Track N — confirm review emits own-line `[APPROVED]` when standards pass |
| Later commit keeps Approve from earlier pipeline run | Track N — reset Build Service vote to 0 at pipeline start |
| Auto-approve fails on historical High after fix push | Track N — ensure purge step runs before improve; only this run's suggestions are gated |
| `review auto_approve` runs but vote stays 0 | Expected on free OSS — use Track N scripted approve, not native auto_approve |
| Auto-approve leaves PR as is / stage fails despite clean review | Track N — require own-line `[APPROVED]` (templated clean text is not enough) and PipelineStartTime scoping |
| Vote API 401/403 after approval signal | Track N — grant Contribute to pull requests to the identity that authored the comment |
| Required reviewer still blocks after green build | Track N — Build Validation ≠ Approve vote; add required Build Service reviewer policy |

Recovery flow:

1. Re-run Track A scope classification.
2. Re-check the directly responsible track and its prerequisite track.
3. Verify the final YAML or sbt evidence with explicit commands, not memory.
