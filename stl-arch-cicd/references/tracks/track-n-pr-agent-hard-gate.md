# Track N - PR-Agent Hard Gate

Use for Azure Pipelines PR Build Validation that runs PR-Agent (`describe` / `review` / `improve`) and auto-approves via the Build Service vote.

## Why

OSS PR-Agent posts **review** and **improve** as separate comments. The review template can say `No major issues detected` while **improve** still reports **High** impact (importance 9–10). Treating the review template as an approve signal lets high-impact findings through.

## Rules (pipeline-enforced)

1. **At pipeline start** (after checkout): clear any non-zero Build Service vote on the PR (`vote: 0`). A prior run may have approved an earlier commit; later commits must not keep that Approve.
2. Scope comments to **this run**: Build Service author + activity ≥ `System.PipelineStartTime`.
3. **Fail** the PR-Agent stage if any in-scope *PR Code Suggestions* comment has:
   - importance score **9** or **10** (`Suggestion importance[1-10]: N` or `Importance: N`), or
   - Impact text **High** (`Impact: High`, `High impact`, or a standalone `High` line)
   - Do **not** use bare `\bHigh\b` (suggestion prose often mentions “High”)
   - Ignore `No code suggestions found for the PR.`
4. **Approve signal:** Build Service *PR Reviewer Guide* containing templated `No major issues detected` (after stripping fenced code). Do **not** require `[APPROVED]`.
5. **Fail** if that templated clean-review signal is missing from this run.
6. Only when clean-review signal is present and High impact is absent: cast Build Service **vote:10**.

## TOML vs pipeline

| Layer | Role |
|---|---|
| `WikiTechnical/.ci/pr-standards/*.toml` | Prompt the model (convention criteria) |
| Pipeline inject into `pr_reviewer.extra_instructions` | Require own-line `[APPROVED]` when criteria pass |
| `azure-pipelines/pr-pipeline.yml` hard-gate step | Deterministic fail / approve (source of truth) |

Do not rely on TOML alone to fail the stage.

Approve via PR-Agent’s templated `No major issues detected` in *PR Reviewer Guide*; do not inject or require `[APPROVED]`.

## Template

| Fragment | When |
|---|---|
| `assets/pr-agent-reset-vote.yml` | After checkout — clear stale Build Service vote |
| `assets/pr-agent-hard-gate.yml` | After `describe` / `review` / `improve` — hard gate + vote:10 |

Canonical copies: `SteyApiConsole`, `SteyCrs`, and `WikiTechnical` PR pipelines.

## Verify

```bash
rg -n "Reset prior Build Service PR vote|Hard-Gate and Auto-Approve|TEMPLATED_OK|has_high_impact|exit\\(3\\)" \
  azure-pipelines/pr-pipeline.yml
```

Expect: reset-vote step before PR-Agent; hard-gate step present; templated `No major issues detected` approve path present; High-impact → exit 3; missing clean-review signal → exit 2 → bash `exit 1`.
