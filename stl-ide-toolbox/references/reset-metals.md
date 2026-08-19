# Reset Metals (sbt as build server)

Hard reset when Metals/Bloop/BSP state is corrupted or you want **sbt BSP** instead of Bloop.

## Goal

1. Ensure project `.jvmopts` with **`-Xmx4G`** / **`-Xss4m`** (shared CI + local sbt / sbt-BSP heap; aligned with `stl-arch-cicd`)
2. **Delete project-root `.sbtopts` if present** (its `-J-Xmx…` overrides `.jvmopts`)
3. Force-stop any live Bloop daemon
4. Delete Metals / Bloop / old BSP cache files
5. Prefer sbt as the build server (`metals.defaultBspToBuildTool: true`)
6. Regenerate `.bsp/sbt.json` via `sbt bspConfig`
7. In Cursor: restart Metals → **Switch build server → sbt** → Import build

## Cache paths (workspace)

Relative to the Scala project root (directory with `build.sbt`):

| Path | Why |
|---|---|
| `.metals/` | Metals workspace DB / indexes |
| `.bloop/` | Bloop config + caches |
| `.bsp/` | Wipe first, then recreate with `sbt bspConfig` as `.bsp/sbt.json` |
| `project/metals.sbt` | Metals-generated Bloop bridge (if present) |
| `project/project/metals.sbt` | Nested Metals plugin file (if present) |

## Optional global caches (`--global`)

| Path | Why |
|---|---|
| `~/.bloop` | Global Bloop daemon state |
| `~/Library/Caches/ScalaCli/bloop` | Scala CLI–managed Bloop daemon (macOS common) |
| `~/Library/Caches/org.scalameta.metals` | Metals caches (macOS) |
| `~/Library/Caches/metals` | Alternate Metals cache dir |

Do **not** delete `~/.ivy2`, `~/.cache/coursier`, or the whole sbt boot cache unless the user explicitly asks.

## Setting

In Cursor **User** settings (skill-managed):

```json
"metals.defaultBspToBuildTool": true
```

This is necessary but **not sufficient**. A live Bloop daemon still wins discovery (see Cautions).

## Project sbt heap (`.jvmopts`)

Place / update **project-root** `.jvmopts` so sbt and sbt-BSP use **4G** heap (template: [jvmopts](jvmopts)):

```
-Xmx4G
-Xss4m
```

| Situation | Action |
|---|---|
| `.jvmopts` missing | Create from template |
| `.jvmopts` exists with `-Xmx…` | Rewrite that line to `-Xmx4G` |
| `.jvmopts` exists without `-Xmx` | Append `-Xmx4G` |
| Flags `UseZGC` / `UnlockExperimentalVMOptions` / `-Xms…` | Remove them |
| `.jvmopts` listed in `.gitignore` | Remove that ignore line — file must stay tracked for CI |

**Hard rule — shared / tracked:** project-root `.jvmopts` is the CI + local sbt heap contract (`stl-arch-cicd` Track B). **Do not** gitignore it, **do not** `git rm --cached`. Prefer committing it when missing from the index. The reset script normalizes heap to 4G and strips ignore rules; it never untracks the file.

**Caution:** `.jvmopts` applies to **sbt** (and sbt BSP), not to Metals’ own JVM or to Bloop’s `metals.bloopJvmProperties`. After changing it, restart the sbt build server / re-import so BSP picks up the new heap.

### Delete `.sbtopts` (required if present)

**Hard rule:** this toolbox uses **`.jvmopts` only** for sbt/sbt-BSP JVM flags. If project-root `.sbtopts` exists, **delete it**.

sbt applies `.sbtopts` `-J-…` flags **after** `.jvmopts`, so a tracked `.sbtopts` with `-J-Xmx2048M` silently wins over `-Xmx4G` and causes long compiles / `OutOfMemoryError: Java heap space`. Move any still-needed non-heap flags (e.g. `--add-opens`, `MaxMetaspaceSize`) into `.jvmopts`, then remove `.sbtopts`. The reset script deletes it when present (uses `git rm` if tracked).

## Cautions (read before running)

1. **Live Bloop wins over the setting**  
   If Bloop is running, Metals logs `Found a Bloop server running` / `Connected to Build server: Bloop` even when `metals.defaultBspToBuildTool` is `true`.

2. **`Missing valid Bloop build` after wiping `.bloop`**  
   That error means Metals is still talking to Bloop with an empty/missing `.bloop/` dir. Fix: kill Bloop, ensure `.bsp/sbt.json` exists, then **Switch build server → sbt**. Do not regenerate Bloop to “fix” this unless you intentionally want Bloop again.

3. **Cursor respawns Metals**  
   Killing `scala.meta.metals.Main` from the shell is unreliable — Cursor restarts it and it may immediately relaunch Bloop. Prefer Command Palette restart / switch after the script finishes.

4. **Soft `pkill` is not enough**  
   Use `pkill -9` for `bloop.Bloop` / `BloopServer` / `ScalaCli/bloop`. Soft kills often leave the daemon up.

5. **`.bsp` must be sbt, not empty/Bloop-only**  
   After wiping caches, always run `sbt bspConfig` so `.bsp/sbt.json` exists before the user restarts Metals.

6. **Switch build server is often required**  
   Do not treat it as optional. After a Bloop-stuck workspace, **Metals: Switch build server → sbt** is the decisive step; Restart + Import alone may stay on Bloop.

7. **Do not delete dependency caches by default**  
   Coursier / Ivy / sbt boot are unrelated to this reset and are expensive to rebuild.

## Ordered steps

### A. Agent (shell)

1. Confirm project root (folder containing `build.sbt`). Use `--global` only if the user asks for a machine-wide wipe.
2. Merge User setting `"metals.defaultBspToBuildTool": true` if missing (from `references/settings.json`).
3. Run:

```bash
bash "<skill-dir>/scripts/reset-metals.sh" "<project-root>"
# optional: ... "<project-root>" --global
```

Script sequence: ensure `.jvmopts` (`-Xmx4G`) → delete `.sbtopts` if present → force-kill Bloop → delete workspace caches → `sbt bspConfig` (uses current `JAVA_HOME` / `java`) → print Cursor follow-ups.

4. Confirm before handing off:
   - `.jvmopts` contains `-Xmx4G` (and is preferably git-tracked)
   - project-root `.sbtopts` is **absent**
   - `.bsp/sbt.json` exists
   - `.bloop/` is absent (or empty)
   - Prefer no `BloopServer` process (`pgrep -fl BloopServer`); if Cursor already respawned Metals/Bloop, tell the user to switch immediately

### B. User (Command Palette — Cmd+Shift+P)

Run **in this order**:

1. **Metals: Restart server** (fallback: **Developer: Reload Window**)
2. **Metals: Switch build server** → choose **sbt** (critical if previously on Bloop)
3. **Metals: Import build**

Agents cannot reliably invoke those Metals UI commands from the shell; the human must run them in Cursor.

## Verify

| Check | Expected |
|---|---|
| `.metals/metals.log` | `Connected to Build server: sbt` (not Bloop) |
| Status bar / Metals Doctor | build server **sbt** |
| Workspace | `.bsp/sbt.json` present; no need for `.bloop/` when on sbt |
| `.jvmopts` | contains `-Xmx4G`; tracked in git when in a Stey CI repo |
| `.sbtopts` | **absent** at project root |
| Processes | no lingering `BloopServer` required for the workspace |
| Editor | opening a `.scala` file shows diagnostics / completions after import |
| sbt worker heap | process args show `-Xmx4G` and **no** later smaller `-Xmx…` |

## Failure triage

| Symptom | Likely cause | Action |
|---|---|---|
| `Missing valid Bloop build …/.bloop` | Still connected to Bloop after wipe | Kill Bloop; **Switch build server → sbt**; Import |
| Log: `Found a Bloop server running` | Daemon still up / Metals relaunched it | Force-kill Bloop again; Switch → sbt immediately |
| No sbt option in Switch build server | Missing `.bsp/sbt.json` | Run `sbt bspConfig` in project root, Restart, Switch |
| Import hangs / empty targets on Bloop | Wrong build server | Switch → sbt; do not regenerate `.bloop` unless intentional |
| Full compile OOM / worker stuck at 1–2G | Missing `.jvmopts`, or `.sbtopts` `-J-Xmx…` override | Restore tracked `-Xmx4G` `.jvmopts`; delete `.sbtopts`; restart build server |
| `Java home has been updated, do you want to restart the sbt BSP server?` | JDK on the machine changed vs `.bsp/sbt.json` | Accept restart, or `sbt bspConfig` then Restart server. Do not pin a JDK ([java-home.md](java-home.md)) |
