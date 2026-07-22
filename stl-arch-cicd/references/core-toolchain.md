# Core Toolchain

Use this as the canonical reference for Tracks B through F.

## Track routing

| Need | Tracks |
|---|---|
| Toolchain baseline only | A -> B -> C -> D |
| Nexus discovery and dependency bumps | A -> E -> F |
| Full build-side maintenance | A -> B -> C -> D -> E -> F |

## sbt launcher

- `project/build.properties` must stay compatible with the repo's plugin set.
- Fix launcher drift before debugging pipeline behavior.

## sbt heap (`.jvmopts`)

AKSHosted / Azure Pipelines run bare `sbt` with a clean checkout. Without a project-root `.jvmopts`, the sbt JVM defaults to ~1G and OOMs on large codegen modules (e.g. gRPC `*/api` with ~900+ sources).

**Contract (commit and keep tracked):**

```text
-Xmx4G
-Xss4m
```

Copy-ready template: `assets/jvmopts`.

| Do | Do not |
|---|---|
| Commit project-root `.jvmopts` with `-Xmx4G` / `-Xss4m` | Gitignore or `git rm --cached` the shared file for local IDE hygiene |
| Prefer `.jvmopts` over `.sbtopts` for heap | Put `-J-Xmx…` in `.sbtopts` (applied after `.jvmopts` and can silently override) |
| Keep flags minimal — heap + stack only | Commit local-only collectors (`UseZGC`) or `UnlockExperimentalVMOptions` |
| Raise heap via pipeline `SBT_OPTS` only if a service cannot share 4G | Rely on agent image defaults or assume a prior workspace still has `.jvmopts` |

`checkout: self` + `clean: true` means deleted/gitignored `.jvmopts` is gone on every job — CI OOM after untracking is expected, not a stale-agent bug.

## aether publish plugin

- Prefer `aether-deploy >= 0.30.0`.
- Remove legacy shim logic once the plugin is upgraded.
- Keep publish behavior explicit and reviewable.

## Build versioning

- `ThisBuild / version` is the source of truth.
- Preserve postfix conventions already used by the repo.
- Verify with `show version` or the repo's publish-target commands rather than guessing.

## Nexus metadata discovery

- Use the script path, not hand-built Nexus URLs.
- Respect repo credentials and resolvers already configured in sbt.
- Keep Scala binary version alignment explicit when reading latest artifacts.
- For `maven-releases` metadata, prefer `<release>` over `<latest>` because Nexus may leave `<latest>` stale.

## Stey dependency bumps

- Use the Nexus discovery flow for Stey dependencies only.
- Exclude Akka and Slick from this bump path.
- Prefer a compact summary table of before and after versions when reporting.
