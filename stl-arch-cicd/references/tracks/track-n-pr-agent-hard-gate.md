# Track N - PR-Agent Hard Gate

Use for Azure Pipelines PR Build Validation that runs PR-Agent (`describe` / `review` / `improve`) and auto-approves via the Build Service vote.

## Why

OSS PR-Agent posts **review** and **improve** as separate comments. The review template can say `No major issues detected` while **improve** still reports **High** impact (importance 9–10). Treating the review template as an approve signal lets high-impact findings through.

## Rules (pipeline-enforced)

1. Scope comments to **this run**: Build Service author + activity ≥ `System.PipelineStartTime`.
2. **Fail** the PR-Agent stage if any in-scope *PR Code Suggestions* comment has:
   - importance score **9** or **10** (`Suggestion importance[1-10]: N` or `Importance: N`), or
   - Impact text **High** (`Impact: High`, `High impact`, or a standalone `High` line)
   - Do **not** use bare `\bHigh\b` (suggestion prose often mentions “High”)
   - Ignore `No code suggestions found for the PR.`
3. **Fail** if no in-scope review comment has own-line `[APPROVED]` (after stripping fenced code).
4. **Do not** treat templated `No major issues detected` as approval.
5. Only when both gates pass: cast Build Service **vote:10**.

## TOML vs pipeline

| Layer | Role |
|---|---|
| `WikiTechnical/.ci/pr-standards/*.toml` | Prompt the model (convention criteria) |
| Pipeline inject into `pr_reviewer.extra_instructions` | Require own-line `[APPROVED]` when criteria pass |
| `azure-pipelines/pr-pipeline.yml` hard-gate step | Deterministic fail / approve (source of truth) |

Do not rely on TOML alone to fail the stage.

Inject wording must tell the model that `[APPROVED]` is **required for CI** on a passing code/doc review (not only “documents”), and that templated `No major issues detected` is not enough.

## Template

Copy-ready gate fragment: `assets/pr-agent-hard-gate.yml`.

Canonical service copies: `SteyApiConsole` and `SteyCrs` `azure-pipelines/pr-pipeline.yml`.

## Verify

```bash
rg -n "Hard-Gate and Auto-Approve|TEMPLATED_OK|No major issues detected|has_high_impact|exit\\(3\\)" \
  azure-pipelines/pr-pipeline.yml
```

Expect: hard-gate step present; `TEMPLATED_OK` / templated approve path **absent**; High-impact → exit 3; missing `[APPROVED]` → exit 2 → bash `exit 1`.
