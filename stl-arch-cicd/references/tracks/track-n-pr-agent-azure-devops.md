# Track N - PR-Agent On Azure DevOps

Use for wiring Qodo/Codium PR-Agent as an Azure Repos Build Validation job (TDD / PRD / code review). The agent only posts comments — no scripted Approve votes, hard gates, or auto-approval. Review is best-effort and must not fail the PRAgent stage or block Build/Test.

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
| Stage order | `Build` **dependsOn** `PRAgent` but runs on Succeeded / SucceededWithIssues / Failed — review is best-effort |
| Release CI | Lives only in `release-pipeline.yml` (branch triggers); never Package/Deploy from Build Validation |
| Variable groups | `pr-pipeline.yml` → `azure-pipeline-credentials`; `release-pipeline.yml` → `sentry-credentials` (etc.) |
| Approval | Humans approve merges — do **not** add vote reset, `[APPROVED]` inject, hard-gate, or `vote:10` steps |

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

## What PR-Agent does (and does not)

On each PR Build Validation run:

1. Fetch WikiTechnical standards into `.pr_agent.toml` (warn + continue on failure).
2. Run `describe` / `review` / `improve` best-effort (plain `review`, not `review auto_approve`); command failures warn and `exit 0` — they must not fail the stage.
3. Post comments as the Build Service identity when the agent succeeds.

Do **not** add:

- Reset prior Build Service vote
- Purge prior PR Code Suggestions
- `[APPROVED]` injection into `extra_instructions`
- Hard-gate scans (High impact / missing `[APPROVED]`)
- Scripted `vote:10` or required Build Service reviewer for auto-merge
- `review auto_approve` (OSS ignores it on ADO anyway)

Build Validation only proves the agent and Build/Test stages ran successfully. Merge approval stays with humans.

## Enablement process

### 1. Repo files

1. Copy `assets/pr-pipeline.yml` → `azure-pipelines/pr-pipeline.yml` and `assets/release-pipeline.yml` → `azure-pipelines/release-pipeline.yml`.
2. Customize service-specific variables (registry, k8s connections, sbt module, chart path, `STANDARDS_FILE`).
3. Ensure `Build` `dependsOn: PRAgent` and still runs when PRAgent is Succeeded / SucceededWithIssues / Failed.
4. Remove any obsolete combined `azure-pipelines/azure-pipelines.yml` that mixed both.
5. Remove any leftover vote-reset, purge-suggestions, `[APPROVED]` inject, or Hard-Gate + Auto-Approve steps from older templates.
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

### 4. Branch policies — min 1 approver + PR Build Validation (mandatory)

Azure Repos ignores YAML `pr:` triggers. For each protected branch (`develop` / `test` / `master` as used), configure **both**:

1. **Minimum number of reviewers = 1** (blocking; human Approve; creator vote should not count; reset votes on new pushes).
2. **Build validation** → this repo’s **pr-pipeline** definition (Required; not `release-pipeline`).

Do **not** add Build Service as a required reviewer. Full UI + `az repos policy` recipes for future projects: `track-n-branch-policies.md`.

Note: PR-Agent comment/command failures must **not** fail the stage; Build/Test is the pipeline gate. Merge still needs the human Approve.

### 5. Build service permissions

Comments use the pipeline identity (`System.AccessToken`).

Grant on the target repo (Project Settings → Repositories → Security):

| Permission | Required |
|---|---|
| Read | Yes |
| Contribute to pull requests | Yes (comments) |
| Contribute | No (not needed for describe/review/improve) |

Apply the grant to whichever Build Service identity actually appears on PR comments after the first smoke run. If comments show Collection Build Service, grant that identity — not only the project-scoped one.

### 6. Smoke test

1. Open a PR into the protected branch with a small change.
2. Confirm Build Validation queues with `Build.Reason=PullRequest`.
3. Confirm `pr-pipeline` runs `PRAgent` then Build/Test (Build still runs if review warns/fails); release pipeline does not run on the PR.
4. Confirm `docker pull` uses `steycr.azurecr.cn/...` (not docker.io).
5. Confirm `describe` / `review` / `improve` post as the build service identity.
6. Confirm there is **no** vote-reset, hard-gate, or Approve vote step in the run.
7. Confirm merge stays blocked until ≥1 human Approve (branch policy).
8. Confirm Build Validation points at pr-pipeline, not release.

## Runtime rules (must hold in YAML)

1. Gate PR-Agent with `condition: eq(variables['Build.Reason'], 'PullRequest')`.
2. Pass `PULL_REQUEST_ID: $(System.PullRequest.PullRequestId)` explicitly.
3. Set `AZURE_DEVOPS__ORG` from `System.CollectionUri` (full URL, no trailing slash), never the bare org name.
4. Set `AZURE_DEVOPS__PROJECT` from `System.TeamProject`.
5. Do **not** set Docker `-w` to `$(Build.SourcesDirectory)` — image entrypoint needs `/app`.
6. Mount only `.pr_agent.toml` into `/app/.pr_agent.toml:ro`.
7. Put `CONFIG__FALLBACK_MODELS` in the step `env:` block as a JSON array string, e.g. `'["deepseek/deepseek-v4-flash"]'`.
8. Model prefix must match the LiteLLM router (`deepseek/...` for official DeepSeek).
9. Set `CONFIG__CUSTOM_MODEL_MAX_TOKENS=1000000` for `deepseek/deepseek-v4-flash` (not in the image MAX_TOKENS table yet).
10. Use `pool.name: AKSHosted` and `prAgentImage: steycr.azurecr.cn/steycr/pr-agent:latest` — Docker login before pull; never `codiumai/pr-agent:latest` on AKSHosted.
11. Keep PR validation in `pr-pipeline.yml` and release CI/CD in `release-pipeline.yml` (no PR-Agent on release).
12. `Build` stage must `dependsOn: PRAgent` but must still run when PRAgent is Succeeded / SucceededWithIssues / Failed.
13. PR-Agent fetch + describe/review/improve steps are best-effort (`continueOnError` / warn + `exit 0`); do not fail the stage on review errors.
14. Do not add auto-approve, vote reset, purge-suggestions, `[APPROVED]` inject, or hard-gate steps.

## Failure vs review quality

| Outcome | PRAgent stage | Merge impact |
|---|---|---|
| Config curl / docker pull / LLM / ADO / PR-Agent command error | Succeeded (warnings) | Build/Test still runs; humans decide from comments |
| Agent posts review comments (any severity) | Succeeded | Humans review comments and approve |
| Build/Test fails | n/a | Required Build Validation blocks merge |

Required Build Validation is gated by Build/Test, not by PR-Agent review success.

## Verify

- `pr-pipeline.yml` and `release-pipeline.yml` paths match the ADO pipeline definitions.
- Variable group linked on **pr-pipeline**; `DeepSeekApiKey` present; `prAgentImage` points at steycr ACR.
- Branch policies on each protected branch: **min 1 reviewer** + **Build Validation → pr-pipeline** (see `track-n-branch-policies.md`).
- Repo security grants Read + Contribute to pull requests to the Build Service identity that posts comments.
- Smoke PR: `PRAgent` runs describe/review/improve; Build/Test follows even if review warns; no scripted Approve vote is cast.
- Confirm vote-reset / Hard-Gate / Auto-Approve / `[APPROVED]` inject steps are absent from `pr-pipeline.yml`.
- Confirm Run PR-Agent uses `continueOnError` / warn + `exit 0` (does not fail the stage).
- Confirm merge blocked until a human Approve (count ≥ 1).
