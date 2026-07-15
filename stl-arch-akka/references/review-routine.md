# Review routine

Use this procedure whenever the skill is active. Goal: no silent track skipping.

## 1. Classify scope

| Scope | Tracks to run |
|-------|---------------|
| Full | A-Q |
| API / surface | A, B, C |
| Command implementation | C, D, E, F, G |
| Event / state implementation | H, I, J, O |
| Read model / producer | K, L, M |
| Setup / rebuild | D, E, H, I, N, O |
| Serialization | D, H, J, O, Q |
| Kafka consumers | P, M, Q |

When unsure, use **Full**.

## 2. Run tracks

For each track in scope:

1. Open `references/tracks/track-index.md`.
2. Open the selected `references/tracks/track-*.md`.
3. Load only the linked topic/example/case-study files.
4. Walk the checklist and record Pass, Fail, or N/A with file:line on failures.
5. Record track status: Pass, Fail, or Skipped with reason.

## 3. Completion gate

### Full review

- [ ] Tracks A-Q all appear in the report.
- [ ] Every track has Pass, Fail, or Skipped status.
- [ ] Every fail includes remediation or follow-up.

### Partial review

- [ ] Executed tracks are listed in order.
- [ ] Deferred tracks are listed with reasons.
- [ ] The user is told deferred areas remain unchecked.

## 4. Report shape

- Start with scope and package.
- List passed, failed, and skipped tracks.
- Give one section per executed track with status and findings.
- For partial reviews, add a deferred-tracks section.
- For any fail, include remediation or follow-up.

## 5. Implement vs audit

| Mode | Routine |
|------|---------|
| Audit / PR review | Run tracks and report only. |
| Implement / refactor | Run touched tracks before and after changes. Re-run failed tracks until Pass or documented exception. |
