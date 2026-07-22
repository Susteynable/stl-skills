# Track B - sbt Launcher

Read `../core-toolchain.md`.

Verify:

- `project/build.properties` matches the repo plugin baseline.
- Launcher drift is fixed before later tracks.
- Project-root `.jvmopts` is **tracked** (not in `.gitignore`) with at least:

  ```text
  -Xmx4G
  -Xss4m
  ```

- No project-root `.sbtopts` heap override (`-J-Xmx…`) that undercuts `.jvmopts`.
- Pipeline `sbt` steps do not need `SBT_OPTS` when the committed `.jvmopts` is present; use env/`-J-Xmx` only as a fallback.

If compile CI fails with `OutOfMemoryError: Java heap space` and logs show `max 1.00GB`, restore the tracked `.jvmopts` (see `../core-toolchain.md` → sbt heap).
