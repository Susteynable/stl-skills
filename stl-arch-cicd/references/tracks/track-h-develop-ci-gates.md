# Track H - Develop CI Gates

Read `../core-pipelines.md`.

Verify:

- Package runs on develop (`condition: succeeded()` — do **not** exclude `refs/heads/develop`) so API jar publish / compile happens on develop pushes.
- Gate Docker at the **step** level (`ne(...develop)` on Docker login + `docker:publish`), not by skipping the whole Package stage — see `assets/release-pipeline.yml` and `assets/pipeline-develop-gates.yml`.
- Artifacts still skips develop (`ne(...develop)`), preserving Helm-drop-only-for-deploy.
- Docker publish stays off develop; normally only `test` / `master` publish images.
- Conditions stay minimal and reviewable.
