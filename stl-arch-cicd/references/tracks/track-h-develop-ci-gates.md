# Track H - Develop CI Gates

Read `../core-pipelines.md`.

Verify:

- Package runs on develop (`condition: succeeded()` — do **not** exclude `refs/heads/develop`) so API jar publish happens on develop pushes.
- Artifacts still skips develop (`ne(...develop)`), preserving Helm-drop-only-for-deploy.
- Docker publish stays branch-gated (`test` / `master`); never on develop.
- Conditions stay minimal and reviewable.
