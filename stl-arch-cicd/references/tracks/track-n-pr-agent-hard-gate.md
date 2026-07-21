# Track N - PR-Agent Hard Gate

Use for Azure Pipelines PR Build Validation that runs PR-Agent (`describe` / `review` / `improve`) and auto-approves via the Build Service vote.

## Why

OSS PR-Agent posts **review** and **improve** as separate comments. The review template can say `No major issues detected` while **improve** still reports **High** impact (importance 9–10). Treating the review template as an approve signal lets high-impact findings through.

## Rules (pipeline-enforced)

1. **At pipeline start** (after checkout): clear any non-zero Build Service vote on the PR (`vote: 0`). A prior run may have approved an earlier commit; later commits must not keep that Approve.
2. **Before improve:** delete prior Build Service *PR Code Suggestions* comments on the PR so historical High text cannot fail a later run.
3. Scope comments to **this run**: Build Service author + activity ≥ `System.PipelineStartTime`.
4. **Fail** the PR-Agent stage if any in-scope *PR Code Suggestions* comment has:
   - importance score **9** or **10** (`Suggestion importance[1-10]: N` or `Importance: N`), or
   - Impact text **High** (`Impact: High`, `High impact`, or a standalone `High` line)
   - Do **not** use bare `\bHigh\b` (suggestion prose often mentions “High”)
   - Ignore `No code suggestions found for the PR.`
5. **Fail** if no in-scope review comment has own-line `[APPROVED]` (after stripping fenced code).
6. **Do not** treat templated `No major issues detected` as approval.
7. Only when both gates pass: cast Build Service **vote:10**.

## TOML vs pipeline

| Layer | Role |
|---|---|
| `WikiTechnical/.ci/pr-standards/*.toml` | Prompt the model (convention criteria) |
| Pipeline inject into `pr_reviewer.extra_instructions` | Require own-line `[APPROVED]` when criteria pass |
| `azure-pipelines/pr-pipeline.yml` hard-gate step | Deterministic fail / approve (source of truth) |

Do not rely on TOML alone to fail the stage.

Inject wording must tell the model that `[APPROVED]` is **required for CI** on a passing code/doc review (not only “documents”), and that templated `No major issues detected` is not enough.

## Template

| Fragment | When |
|---|---|
| `assets/pr-agent-reset-vote.yml` | After checkout — clear stale Build Service vote |
| `assets/pr-agent-purge-suggestions.yml` | After reset-vote — delete prior Code Suggestions |
| `assets/pr-agent-hard-gate.yml` | After `describe` / `review` / `improve` — hard gate + vote:10 |

Canonical copies: `SteyApiConsole`, `SteyCrs`, and `WikiTechnical` PR pipelines.

## Verify

```bash
rg -n "Reset prior Build Service PR vote|Purge prior PR Code Suggestions|Hard-Gate and Auto-Approve|TEMPLATED_OK|has_high_impact|exit\\(3\\)" \
  azure-pipelines/pr-pipeline.yml
```

Expect: reset-vote step before PR-Agent; hard-gate step present; `TEMPLATED_OK` absent; High-impact → exit 3; missing `[APPROVED]` → exit 2 → bash `exit 1`.
