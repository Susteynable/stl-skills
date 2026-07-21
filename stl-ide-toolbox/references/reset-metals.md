# Reset Metals (sbt as build server)

Hard reset when Metals/Bloop/BSP state is corrupted or you want **sbt BSP** instead of Bloop.

## Goal

1. Ensure project `.jvmopts` with **`-Xmx8G`** (sbt / sbt-BSP heap)
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

Place / update **project-root** `.jvmopts` so sbt and sbt-BSP use up to **8G** heap (template: [jvmopts](jvmopts)):

```
-Xms100m
-Xmx8G
-Xss4m
-XX:+UnlockExperimentalVMOptions
-XX:+UseZGC
```

`-XX:+UnlockExperimentalVMOptions` must precede `-XX:+UseZGC` on JDKs that still mark ZGC experimental (e.g. JDK 11). Harmless on newer JDKs where ZGC is production.

| Situation | Action |
|---|---|
| `.jvmopts` missing | Create from template |
| `.jvmopts` exists with `-Xmx…` | Rewrite that line to `-Xmx8G` (keep other flags) |
| `.jvmopts` exists without `-Xmx` | Append `-Xmx8G` |
| `.jvmopts` has `UseZGC` but no unlock | Insert `-XX:+UnlockExperimentalVMOptions` immediately before `UseZGC` |

**Hard rule — local only:** `.jvmopts` must stay on disk and out of git. Ensure `.gitignore` has `.jvmopts`. If tracked (common after rebase onto older commits), `git rm --cached .jvmopts` — **never** delete the working-tree file. Verify with `git check-ignore -v .jvmopts` and `test -f .jvmopts`. Do not commit heap flags. The reset script enforces ignore + untrack.

**Caution:** `.jvmopts` applies to **sbt** (and sbt BSP), not to Metals’ own JVM or to Bloop’s `metals.bloopJvmProperties`. After changing it, restart the sbt build server / re-import so BSP picks up the new heap.

### Delete `.sbtopts` (required if present)

**Hard rule:** this toolbox uses **`.jvmopts` only** for sbt/sbt-BSP JVM flags. If project-root `.sbtopts` exists, **delete it**.

sbt applies `.sbtopts` `-J-…` flags **after** `.jvmopts`, so a tracked `.sbtopts` with `-J-Xmx2048M` silently wins over `-Xmx8G` and causes long compiles / `OutOfMemoryError: Java heap space`. Move any still-needed non-heap flags (e.g. `--add-opens`, `MaxMetaspaceSize`) into `.jvmopts`, then remove `.sbtopts`. The reset script deletes it when present (uses `git rm` if tracked).

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

Script sequence: ensure `.jvmopts` (`-Xmx8G`) → delete `.sbtopts` if present → force-kill Bloop → delete workspace caches → `sbt bspConfig` → print Cursor follow-ups.

4. Confirm before handing off:
   - `.jvmopts` contains `-Xmx8G`
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
| `.jvmopts` | contains `-Xmx8G` |
| `.sbtopts` | **absent** at project root |
| Processes | no lingering `BloopServer` required for the workspace |
| Editor | opening a `.scala` file shows diagnostics / completions after import |
| sbt worker heap | process args show `-Xmx8G` and **no** later `-Xmx2048M` |

## Failure triage

| Symptom | Likely cause | Action |
|---|---|---|
| `Missing valid Bloop build …/.bloop` | Still connected to Bloop after wipe | Kill Bloop; **Switch build server → sbt**; Import |
| Log: `Found a Bloop server running` | Daemon still up / Metals relaunched it | Force-kill Bloop again; Switch → sbt immediately |
| No sbt option in Switch build server | Missing `.bsp/sbt.json` | Run `sbt bspConfig` in project root, Restart, Switch |
| Import hangs / empty targets on Bloop | Wrong build server | Switch → sbt; do not regenerate `.bloop` unless intentional |
| Full compile OOM / worker stuck at 2G | `.sbtopts` `-J-Xmx…` overriding `.jvmopts` | Delete `.sbtopts`; restart build server; verify `-Xmx8G` |
