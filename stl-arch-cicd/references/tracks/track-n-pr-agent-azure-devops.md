# Track N - PR-Agent On Azure DevOps

Use for wiring Qodo/Codium PR-Agent as an Azure Repos Build Validation job (TDD / PRD / code review), including scripted auto-approval.

## Copy-ready templates

| Template | Copy to | Role |
|---|---|---|
| `../../assets/pr-pipeline.yml` | `azure-pipelines/pr-pipeline.yml` | Build Validation: PR-Agent + Build/Test |
| `../../assets/release-pipeline.yml` | `azure-pipelines/release-pipeline.yml` | Branch CI/CD: Build / Package / Artifacts / Deploy |

Both are the SteyApiConsole reference definitions. Customize service IDs, module names, and chart paths. (`assets/pr-agent-azure-pipelines.yml` is a deprecated pointer only.)

## Scope

- YAML-only pipeline + Azure DevOps project settings.
- Does not replace Tracks G–L service CI/CD gates (those live in `release-pipeline.yml`).
- Target branch is usually `master` or `develop` (whatever branch policies protect).

## Preferred layout (Stey services)

**Prefer two pipeline definitions** (split PR validation from release CI/CD):

| File | Purpose |
|---|---|
| `azure-pipelines/pr-pipeline.yml` | Build Validation: PR-Agent review + Build/Test |
| `azure-pipelines/release-pipeline.yml` | Branch CI/CD: Build / Package / Artifacts / Deploy — **no** PR-Agent |

| Concern | Rule |
|---|---|
| Pool | `pool.name: AKSHosted` — no `vmImage` / `poolVmImage` (Track L) |
| Image | `steycr.azurecr.cn/steycr/pr-agent:latest` — **not** `docker.io/codiumai/pr-agent` |
| Auth to ACR | `Docker@2` login with the service `containerRegistry` connection before `docker pull` |
| When PR-Agent / PR Build runs | `condition: eq(variables['Build.Reason'], 'PullRequest')` on `pr-pipeline.yml` stages |
| Stage order | `Build` **dependsOn** `PRAgent` with `and(succeeded(), …)` — tests run only after review succeeds |
| Release CI | Lives only in `release-pipeline.yml` (branch triggers); never Package/Deploy from Build Validation |
| Variable groups | `pr-pipeline.yml` → `azure-pipeline-credentials`; `release-pipeline.yml` → `sentry-credentials` (etc.) |
| Clean-review match | Templated `No major issues detected` in *PR Reviewer Guide*; strip markdown/HTML fenced code before scan |

### Why not Docker Hub / `ubuntu-latest`

`AKSHosted` agents commonly **cannot reach** `registry-1.docker.io` (`dial tcp … i/o timeout`). Microsoft-hosted `ubuntu-latest` is not the Stey default pool. Mirror once into China ACR, then pull from `steycr.azurecr.cn`.

One-time mirror (from a host that can reach both docker.io and steycr):

```bash
docker pull codiumai/pr-agent:latest
docker tag codiumai/pr-agent:latest steycr.azurecr.cn/steycr/pr-agent:latest
az acr login --name steycr   # or: docker login steycr.azurecr.cn
docker push steycr.azurecr.cn/steycr/pr-agent:latest
```

Pipeline variable:

```yaml
- name: prAgentImage
  value: 'steycr.azurecr.cn/steycr/pr-agent:latest'
```

## Standards TOML by repo type

Source of truth: Azure Repo **WikiTechnical** (project `Stey`), path `.ci/pr-standards/` on branch `master`.

Fetch via the ADO Git Items API with `Authorization: Bearer $(System.AccessToken)` (not GitHub raw). Grant the build service **Read** on WikiTechnical.

| Repo type | `STANDARDS_FILE` (under `.ci/pr-standards/`) |
|---|---|
| TDD / RFC / architecture docs | `tdd-standards.toml` |
| PRD / product requirements | `prd-standards.toml` |
| Application / service code | `code-standards.toml` |

URL shape (constructed in YAML from `System.CollectionUri` + `System.TeamProject`):

```text
{CollectionUri}/{Project}/_apis/git/repositories/WikiTechnical/items?path=/.ci/pr-standards/{STANDARDS_FILE}&versionDescriptor.version=master&versionDescriptor.versionType=branch&download=true&api-version=7.1
```

The asset / `pr-pipeline.yml` comments list all three files; uncomment the matching `STANDARDS_FILE` (service code repos → `code-standards.toml`).

## Important: OSS auto-approve does not cast ADO votes

Free `codiumai/pr-agent` ignores `review auto_approve` for Azure DevOps — it never posts `vote: 10`.

Do **not** rely on PR-Agent native auto-approve. Use the template’s OSS **hard-gate** workaround (details: `track-n-pr-agent-hard-gate.md`):

1. **At pipeline start:** reset any prior Build Service vote on the PR to `0` (stale Approve from an earlier commit must not satisfy branch policy).
2. Run `describe` / `review` / `improve` (plain `review`, not `review auto_approve`).
3. **Fail the job** if this run’s *PR Code Suggestions* show Impact **High** / importance ≥ 9.
4. **Fail the job** if this run has no templated `No major issues detected` in a Build Service *PR Reviewer Guide*.
5. Only when clean-review signal is present and High impact is absent: cast `vote: 10` via the Reviewers API with `System.AccessToken`.

| Signal (this run) | Action |
|---|---|
| Prior Build Service vote ≠ 0 | Reset to **0** at start |
| High-impact improve suggestion | **Fail** PR-Agent stage |
| No templated `No major issues detected` in *PR Reviewer Guide* | **Fail** PR-Agent stage |
| Templated `No major issues detected` + *PR Reviewer Guide* and no High impact | Cast **vote:10** |

Only Build Service comments with activity at/after `System.PipelineStartTime` count for the approve/hard-gate scan. Reviewer id comes from the matching comment author — do not call `connectionData` (often 400). Strip fenced code before matching so cited YAML/docs cannot fake the clean-review signal.

## Enablement process

### 1. Repo files

1. Copy `assets/pr-pipeline.yml` → `azure-pipelines/pr-pipeline.yml` and `assets/release-pipeline.yml` → `azure-pipelines/release-pipeline.yml`.
2. Customize service-specific variables (registry, k8s connections, sbt module, chart path, `STANDARDS_FILE`).
3. Ensure `Build` `dependsOn: PRAgent` with `condition: and(succeeded(), eq(variables['Build.Reason'], 'PullRequest'))`.
4. Remove any obsolete combined `azure-pipelines/azure-pipelines.yml` that mixed both.
5. Keep the vote-reset step and Hard-Gate + Auto-Approve steps unless voting is intentionally disabled.
6. Do not rely on YAML `pr:` for Azure Repos Git — Branch Policy Build Validation is mandatory.

### 2. Variable group

1. Pipelines → Library → Variable group (example: `azure-pipeline-credentials`).
2. Add secret `DeepSeekApiKey` (or the LLM key your model requires).
3. Grant the **pr-pipeline** definition permission to use the group.
4. Prefer `System.AccessToken` for Azure DevOps API auth. Do **not** require a personal `AdoPat` unless you intentionally want comments attributed to a human.

### 3. Pipeline definitions

1. Create/retarget a **PR** pipeline → Existing YAML → `azure-pipelines/pr-pipeline.yml`.
2. Create/retarget a **release** pipeline → Existing YAML → `azure-pipelines/release-pipeline.yml` (branch triggers).
3. Under the PR pipeline → Settings / Options, ensure job authorization can use `System.AccessToken`.
4. Retire obsolete definitions that pointed at deleted combined/`pr-agent` YAML paths.

### 4. Branch policy — Build Validation (mandatory for Azure Repos)

Azure Repos ignores YAML `pr:` triggers. Configure:

1. Repos → Branches → target branch (`master` / `develop`) → Branch policies.
2. Build validation → add the **pr-pipeline** definition (not release).
3. Set Required if merge must wait for PR-Agent to finish running.
4. Note: a critical review comment does **not** fail the build by itself; failure means the agent/job errored.

### 5. Branch policy — required Build Service reviewer (for auto-approve merge)

Build Validation only proves “the agent ran.” To block merge until the scripted Approve vote lands:

1. Branch policies → Require a minimum number of reviewers / Automatically included reviewers.
2. Add the identity that posts comments and casts votes — usually one of:
   - `{Project} Build Service ({Org})` — e.g. `Stey Build Service (steycode)`
   - `Project Collection Build Service ({Org})` — e.g. `Project Collection Build Service (steycode)` when job auth is collection-scoped
3. Mark that reviewer required.
4. Optional: enable auto-complete on smoke PRs so a clean review + vote:10 can finish the merge.

Human Approve does **not** replace a required build-service reviewer vote.

### 6. Build service permissions

Comments and votes use the pipeline identity (`System.AccessToken`).

Grant on the target repo (Project Settings → Repositories → Security):

| Permission | Required |
|---|---|
| Read | Yes |
| Contribute to pull requests | Yes (comments + reviewer vote) |
| Contribute | No (not needed for describe/review/improve) |

Apply the grant to whichever Build Service identity actually appears on PR comments after the first smoke run. If comments show Collection Build Service, grant that identity — not only the project-scoped one.

### 7. Smoke test

1. Open a PR into the protected branch with a small change.
2. Confirm Build Validation queues with `Build.Reason=PullRequest`.
3. Confirm `pr-pipeline` runs `PRAgent` then Build/Test (Build waits on PRAgent success); release pipeline does not run on the PR.
4. Confirm `docker pull` uses `steycr.azurecr.cn/...` (not docker.io).
5. Confirm `describe` / `review` / `improve` post as the build service identity.
6. Confirm Hard-Gate + Auto-Approve either:
   - finds templated `No major issues detected` in *PR Reviewer Guide*, no High-impact suggestions, and casts `vote: 10`, or
   - **fails the job** when High impact is present or the templated clean-review signal is missing.
7. Push a second commit on the same PR after an Approve and confirm the next run resets vote to 0 before re-gating.
8. Optional: enable auto-complete + delete source branch on the smoke PR.

## Runtime rules (must hold in YAML)

1. Gate PR-Agent and approve steps with `condition: eq(variables['Build.Reason'], 'PullRequest')`.
2. Pass `PULL_REQUEST_ID: $(System.PullRequest.PullRequestId)` explicitly.
3. Set `AZURE_DEVOPS__ORG` from `System.CollectionUri` (full URL, no trailing slash), never the bare org name.
4. Set `AZURE_DEVOPS__PROJECT` from `System.TeamProject`.
5. Do **not** set Docker `-w` to `$(Build.SourcesDirectory)` — image entrypoint needs `/app`.
6. Mount only `.pr_agent.toml` into `/app/.pr_agent.toml:ro`.
7. Put `CONFIG__FALLBACK_MODELS` in the step `env:` block as a JSON array string, e.g. `'["deepseek/deepseek-v4-flash"]'`.
8. Model prefix must match the LiteLLM router (`deepseek/...` for official DeepSeek).
9. Set `CONFIG__CUSTOM_MODEL_MAX_TOKENS=1000000` for `deepseek/deepseek-v4-flash` (not in the image MAX_TOKENS table yet).
10. Scope approval to this run with `PIPELINE_START_TIME: $(System.PipelineStartTime)`.
11. Vote with `Authorization: Bearer $(System.AccessToken)` and body `{"vote":10}`.
12. Missing templated `No major issues detected` or High-impact suggestions must **fail** the job (not exit 0); scan/vote API errors must also fail the job.
12a. Reset prior Build Service vote to 0 at the start of every PR pipeline run.
13. Use `pool.name: AKSHosted` and `prAgentImage: steycr.azurecr.cn/steycr/pr-agent:latest` — Docker login before pull; never `codiumai/pr-agent:latest` on AKSHosted.
14. Keep PR validation in `pr-pipeline.yml` and release CI/CD in `release-pipeline.yml` (no PR-Agent on release).
15. Match templated `No major issues detected` only inside a *PR Reviewer Guide* body after stripping fenced/HTML code blocks.
16. `Build` stage must `dependsOn: PRAgent` and require `succeeded()` before tests.

## Failure vs review quality vs approve vote

| Outcome | Build result | Merge impact |
|---|---|---|
| Config curl fails, Docker fails, LLM key invalid, ADO 401/403, PR-Agent exception | Failed | Required Build Validation blocks merge |
| High-impact improve suggestion, or no templated clean-review signal | Failed | Required Build Validation blocks merge; prior Build Service vote already reset to 0 |
| Templated `No major issues detected` + no High impact + scripted vote:10 | Succeeded | Required build-service reviewer satisfied |

Required Build Validation blocks merge on hard-gate failure (not only agent/infrastructure errors).

## Verify

- `pr-pipeline.yml` and `release-pipeline.yml` paths match the ADO pipeline definitions.
- Variable group linked on **pr-pipeline**; `DeepSeekApiKey` present; `prAgentImage` points at steycr ACR.
- Build Validation exists on the target branch for the **pr-pipeline** definition.
- Repo security grants Read + Contribute to pull requests to the Build Service identity that posts comments.
- If auto-approve should gate merge: that same identity is a required reviewer.
- Smoke PR: vote reset runs first; `PRAgent` Succeeded with templated `No major issues detected` and no High impact; comments show the build service author; clean review produces `vote: 10`.
- Confirm approve path uses templated `No major issues detected`.
