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
| PR-Agent never runs on Azure Repos PR | Track N — missing Build Validation on target branch |
| `SYSTEM_PULLREQUEST_PULLREQUESTID: unbound variable` | Track N — manual run / not a PR build; gate on `Build.Reason` |
| `can't open file '.../pr_agent/cli.py'` | Track N — Docker `-w` overrode image WORKDIR; mount config only |
| `Invalid URL 'org/org/_apis': No scheme supplied` | Track N — `AZURE_DEVOPS__ORG` must be full `System.CollectionUri` |
| PR-Agent comments appear as a human | Track N — still using personal PAT; switch to `System.AccessToken` |
| PR-Agent 401/403 posting comments | Track N — build service missing Contribute to pull requests |
| Harsh TDD review but build green | Expected — Track N fails only on job/agent errors, not review severity |
| `review auto_approve` runs but vote stays 0 | Expected on free OSS — use Track N scripted approve, not native auto_approve |
| Auto-approve leaves PR as is despite clean review | Track N — check dual signals (`[APPROVED]` or templated `No major issues detected` + `PR Reviewer Guide`) and PipelineStartTime scoping |
| Vote API 401/403 after approval signal | Track N — grant Contribute to pull requests to the identity that authored the comment |
| Required reviewer still blocks after green build | Track N — Build Validation ≠ Approve vote; add required Build Service reviewer policy |

Recovery flow:

1. Re-run Track A scope classification.
2. Re-check the directly responsible track and its prerequisite track.
3. Verify the final YAML or sbt evidence with explicit commands, not memory.
