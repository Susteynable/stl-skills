# Track N - PR-Agent On Azure DevOps

Use for wiring Qodo/Codium PR-Agent as an Azure Repos Build Validation pipeline (TDD / PRD / code review), including scripted auto-approval.

Copy-ready YAML: `../../assets/pr-agent-azure-pipelines.yml`.

## Scope

- YAML-only pipeline + Azure DevOps project settings.
- Does not replace Tracks G–L service CI/CD gates.
- Target branch is usually `master` (or `main` if that is the default).

## Standards TOML by repo type

Set `GLOBAL_CONFIG_URL` to exactly one raw URL from `Susteynable/stl-pr-standards` (never a GitHub `/blob/` HTML page):

| Repo type | `GLOBAL_CONFIG_URL` |
|---|---|
| TDD / RFC / architecture docs | `https://raw.githubusercontent.com/Susteynable/stl-pr-standards/main/tdd-standards.toml` |
| PRD / product requirements | `https://raw.githubusercontent.com/Susteynable/stl-pr-standards/main/prd-standards.toml` |
| Application / service code | `https://raw.githubusercontent.com/Susteynable/stl-pr-standards/main/code-standards.toml` |

The template defaults to `tdd-standards.toml`; comment/uncomment the matching line for PRD or code repos.

## Important: OSS auto-approve does not cast ADO votes

Free `codiumai/pr-agent` ignores `review auto_approve` for Azure DevOps — it never posts `vote: 10`.

Do **not** rely on PR-Agent native auto-approve. Use the template’s OSS workaround:

1. Inject an `[APPROVED]` instruction into `pr_reviewer.extra_instructions`.
2. Run `describe` / `review` / `improve` (plain `review`, not `review auto_approve`).
3. Scan PR threads from **this** pipeline run for a Build Service approval signal.
4. Cast `vote: 10` via the Reviewers API with `System.AccessToken`.

Approval signals (either counts):

| Signal | When it appears |
|---|---|
| Exact token `[APPROVED]` | Model followed the injected instruction |
| Templated `No major issues detected` **and** `PR Reviewer Guide` | PR-Agent clean-review template (freeform `[APPROVED]` is often dropped from the published body) |

Only Build Service comments with activity at/after `System.PipelineStartTime` count. Reviewer id comes from the matching comment author — do not call `connectionData` (often 400).

## Enablement process

### 1. Repo files

1. Copy `assets/pr-agent-azure-pipelines.yml` to the repo (default: `azure-pipelines/azure-pipelines.yml`).
2. Set `GLOBAL_CONFIG_URL` from the **Standards TOML by repo type** table (TDD / PRD / code).
3. Keep `trigger: none`. Do not rely on YAML `pr:` for Azure Repos Git.
4. Keep the `[APPROVED]` inject step and the Conditional Auto-Approve step unless you intentionally disable voting.

### 2. Variable group

1. Pipelines → Library → Variable group (example: `azure-pipeline-credentials`).
2. Add secret `DeepSeekApiKey` (or the LLM key your model requires).
3. Grant the pipeline permission to use the group.
4. Prefer `System.AccessToken` for Azure DevOps API auth. Do **not** require a personal `AdoPat` unless you intentionally want comments attributed to a human.

### 3. Create the pipeline

1. Pipelines → New pipeline → Azure Repos Git → select the repo.
2. Existing Azure Pipelines YAML → select the YAML path.
3. Save (run is optional; PR Build Validation is the real trigger).
4. Under pipeline → Settings / Options, ensure job authorization can use `System.AccessToken` for the project (or collection, if that is your org default).

### 4. Branch policy — Build Validation (mandatory for Azure Repos)

Azure Repos ignores YAML `pr:` triggers. Configure:

1. Repos → Branches → target branch (`master`) → Branch policies.
2. Build validation → add this pipeline.
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

1. Open a PR into the protected branch with a small TDD/RFC change.
2. Confirm Build Validation queues with `Build.Reason=PullRequest`.
3. Confirm `describe` / `review` / `improve` post as the build service identity.
4. Confirm Conditional Auto-Approve either:
   - finds `[APPROVED]` or templated clean-review text and casts `vote: 10`, or
   - exits cleanly with “Leaving PR as is” when the review is not clean.
5. Optional: enable auto-complete + delete source branch on the smoke PR.

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
12. Missing approval signal must exit 0 (leave PR as is); scan/vote API errors must fail the job.

## Failure vs review quality vs approve vote

| Outcome | Build result | Merge impact |
|---|---|---|
| Config curl fails, Docker fails, LLM key invalid, ADO 401/403, PR-Agent exception | Failed | Required Build Validation blocks merge |
| Harsh review / no approval signal | Succeeded | Required build-service reviewer stays at vote 0 → merge blocked if that reviewer is required |
| Clean review + scripted vote:10 | Succeeded | Required build-service reviewer satisfied |

Required Build Validation blocks merge on job failure, not on review severity.

## Verify

- Pipeline definition path matches the YAML in git.
- Variable group linked; `DeepSeekApiKey` present.
- Build Validation exists on the target branch for this definition.
- Repo security grants Read + Contribute to pull requests to the Build Service identity that posts comments.
- If auto-approve should gate merge: that same identity is a required reviewer.
- Smoke PR build is `Succeeded`, comments show the build service author, and a clean review produces `vote: 10`.
