# Track N - Branch Policies (Approvers + PR Pipeline)

Use when enabling Azure Repos branch protection for a **new or existing** Stey service so every PR into a protected branch:

1. Requires **at least 1 human approver**, and
2. Runs the repo’s **PR review pipeline** via Build Validation.

## ADO pipeline naming (required)

| Role | YAML path | ADO definition **name** | Examples |
|---|---|---|---|
| PR Build Validation | `azure-pipelines/pr-pipeline.yml` | **`{RepoName}(PR)`** | `SteyApiConsole(PR)`, `SteyCrs(PR)` |
| Release CI/CD | `azure-pipelines/release-pipeline.yml` | `{RepoName}` | `SteyApiConsole`, `SteyCrs` |

Always use the literal suffix `(PR)` on the PR definition — not `… PR`, `pr-pipeline`, or the bare repo name. Branch policy Build Validation must select `{RepoName}(PR)`.

YAML `pr:` alone does **not** queue Azure Repos PR builds — Branch Policy Build Validation is mandatory.

## Target branches

Apply the same policies on each branch that merges should protect (typical Stey set):

| Branch | Usual role |
|---|---|
| `develop` | integration |
| `test` | pre-prod |
| `master` | release |

Skip branches the repo does not use.

## Required policies (per protected branch)

| Policy | Setting | Why |
|---|---|---|
| **Minimum number of reviewers** | Minimum **1**; blocking; enabled | Human Approve before merge |
| Creator vote counts | **On** | Requestor Approve counts toward the minimum |
| Reset votes when new commits are pushed | **On** (recommended) | New commits need re-approval |
| Allow requestors to approve their own changes | **On** | Same as creator vote counts (`--creator-vote-counts true`) |
| **Build validation** | Pipeline = this repo’s **`{RepoName}(PR)`** definition; **Required**; trigger on each update | Runs PR-Agent + Build/Test |
| Build validation → path filter | None (whole PR) unless the repo has a documented exception | Avoid skipping review by path accident |

### Do not configure

| Policy / setting | Why |
|---|---|
| Required reviewer = Build Service / Project Collection Build Service | Auto-approve was removed; Build Service only posts comments |
| Build validation pointing at `{RepoName}` (release) / `release-pipeline.yml` | Would run Package/Deploy paths on PRs |
| PR pipeline named without `(PR)` suffix | Breaks the Stey naming convention; hard to find in Build Validation picker |
| Relying on YAML `pr:` without Build Validation | Azure Repos ignores it for queueing |

## UI setup (Azure DevOps)

Prerequisites: repo already has an ADO pipeline named **`{RepoName}(PR)`** whose YAML path is `azure-pipelines/pr-pipeline.yml` (copy from `assets/pr-pipeline.yml` first).

For each protected branch (`develop` / `test` / `master`):

1. **Repos** → **Branches** → branch → **Branch policies**.
2. **Require a minimum number of reviewers**
   - Minimum number of reviewers: **1**
   - Allow requestors to approve their own changes: **checked**
   - Prohibit the most recent pusher from approving: optional (org preference)
   - Reset all approval votes when new commits are pushed: **checked**
   - Policy requirement: **Required**
3. **Build validation** → **+**
   - Build pipeline: select **`{RepoName}(PR)`** (YAML: `azure-pipelines/pr-pipeline.yml`), **not** `{RepoName}` release
   - Trigger: Automatic; Policy requirement: **Required**
   - Display name: e.g. `{RepoName}(PR)` (may match the pipeline name)
   - Expire after / timeout: leave defaults unless the org standard differs
4. Save. Repeat for each protected branch (or use “Reuse policies” if the UI offers it for sibling branches).

## Remote / scripted setup (`az` CLI)

Use when bootstrapping a future project from the terminal (org + project + repo already exist; `az` logged in with rights to edit policies).

```bash
# Fill these for the target service
ORG_URL='https://dev.azure.com/<org>'          # or https://<org>.visualstudio.com
PROJECT='Stey'
REPO_NAME='SteyApiConsole'                     # e.g. SteyApiConsole, SteyCrs
PR_PIPELINE_NAME="${REPO_NAME}(PR)"            # REQUIRED name shape: SteyApiConsole(PR)

REPO_ID="$(az repos show \
  --org "$ORG_URL" --project "$PROJECT" --repository "$REPO_NAME" \
  --query id -o tsv)"

BUILD_DEF_ID="$(az pipelines show \
  --org "$ORG_URL" --project "$PROJECT" --name "$PR_PIPELINE_NAME" \
  --query id -o tsv)"

# Use an explicit list (zsh does not word-split unquoted vars the same as bash).
for BRANCH in develop test master; do
  # Min 1 human approver (blocking)
  az repos policy approver-count create \
    --org "$ORG_URL" --project "$PROJECT" \
    --repository-id "$REPO_ID" \
    --branch "$BRANCH" \
    --branch-match-type exact \
    --enabled true \
    --blocking true \
    --minimum-approver-count 1 \
    --creator-vote-counts true \
    --allow-downvotes true \
    --reset-on-source-push true

  # Build Validation → {RepoName}(PR) (blocking)
  az repos policy build create \
    --org "$ORG_URL" --project "$PROJECT" \
    --repository-id "$REPO_ID" \
    --branch "$BRANCH" \
    --branch-match-type exact \
    --enabled true \
    --blocking true \
    --build-definition-id "$BUILD_DEF_ID" \
    --display-name "${PR_PIPELINE_NAME}" \
    --manual-queue-only false \
    --queue-on-source-update-only true \
    --valid-duration 720
done
```

Idempotency: `create` fails if an equivalent policy already exists. List first and update/delete as needed:

```bash
az repos policy list \
  --org "$ORG_URL" --project "$PROJECT" \
  --repository-id "$REPO_ID" --branch develop -o table
```

If `az repos policy approver-count` / `build` are unavailable in your CLI version, use the UI steps above or the [Policies REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/policy/configurations) (`configurationType` ids for approver-count and build).

## New-project checklist (order)

1. Copy `assets/pr-pipeline.yml` + `assets/release-pipeline.yml` into the repo; customize IDs / `STANDARDS_FILE`.
2. Create ADO pipeline definitions: **`{RepoName}(PR)`** → `pr-pipeline.yml`, **`{RepoName}`** → `release-pipeline.yml`.
3. Link variable group (`DeepSeekApiKey`) to **`{RepoName}(PR)`**; allow `System.AccessToken`.
4. Grant Build Service **Read** + **Contribute to pull requests** on the repo (and **Read** on WikiTechnical).
5. **Configure branch policies** (this doc): min **1** approver + Build Validation → **`{RepoName}(PR)`** on each protected branch.
6. Smoke PR: Build Validation runs `{RepoName}(PR)`; merge blocked until ≥1 human Approve **and** required Build Validation succeeds (Build/Test gate).

## Verify

```bash
# After setup — expect approver-count (min 1) + build validation for each branch
az repos policy list \
  --org "$ORG_URL" --project "$PROJECT" \
  --repository-id "$REPO_ID" -o table
```

Expect rows for **Minimum number of reviewers** (or Approver count) and **Build** on each protected `refs/heads/*` branch, both enabled and blocking.

Manual smoke:

1. Open a PR into a protected branch.
2. Confirm Build Validation queues **`{RepoName}(PR)`** (not `{RepoName}` release).
3. Confirm merge stays blocked until a **human** Approve (count ≥ 1).
4. Confirm Build Service is **not** a required reviewer.

## Related

- Pipeline YAML + PR-Agent wiring: `track-n-pr-agent-azure-devops.md`
- Template: `../../assets/pr-pipeline.yml`
