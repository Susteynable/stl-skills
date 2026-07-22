---
name: stl-ide-toolbox
description: >-
  Personal Cursor/VS Code editor keymap, Metals/Scala IDE settings, Metals
  reset (wipe Bloop/BSP caches, prefer sbt build server), HARD RULE: project
  .jvmopts is shared/tracked (-Xmx4G, aligned with stl-arch-cicd; never
  gitignore or untrack), HARD RULE: delete project .sbtopts if present
  (.jvmopts only for heap), also exclude .superpowers/, and shortcuts for
  macOS. Use when configuring keyboard shortcuts, Bloop heap, resetting
  Metals, .jvmopts, .sbtopts, joining lines, opening files in IntelliJ IDEA,
  sidebar toggles, or when the user mentions stl-ide-toolbox, editor
  shortcuts, or keybindings.
---

# STL IDE Toolbox

## Purpose

Document and maintain personal Cursor editor keybindings and **User settings** (Metals/Scala) on **macOS**.

## Hard rule: `.jvmopts` is shared / tracked

**Keep project-root `.jvmopts` tracked** with the CI-safe heap (same contract as `stl-arch-cicd` Track B). Local Metals reset must not gitignore or untrack it — AKSHosted sbt needs the file on every clean checkout.

| Must | Must not |
|---|---|
| File exists (template → `-Xmx4G` / `-Xss4m`) | Add `.jvmopts` to `.gitignore` |
| Prefer git-tracked in Stey CI repos | `git rm --cached .jvmopts` for “IDE hygiene” |
| Strip obsolete `UseZGC` / `UnlockExperimentalVMOptions` | Commit local-only collector experiments |

Template: [references/jvmopts](references/jvmopts). Pipeline OOM at `max 1.00GB` means the shared file is missing from the checkout — restore and commit it; do not treat that as a stale agent bug.

## Hard rule: no project `.sbtopts`

**Delete project-root `.sbtopts` if present.** This toolbox uses **`.jvmopts` only** for sbt/sbt-BSP JVM flags.

`.sbtopts` `-J-Xmx…` is applied **after** `.jvmopts` and silently overrides heap (e.g. `-Xmx4G` → `-Xmx2048M` → OOM / multi-minute full compiles). On Metals reset or when touching sbt heap: remove `.sbtopts` (`git rm` if tracked); move any still-needed non-heap flags into `.jvmopts`.

## Canonical sources

| Role | Path |
|---|---|
| Skill keymap (source of truth) | `references/keymap.json` |
| Skill settings (source of truth) | `references/settings.json` |
| Reset Metals procedure | `references/reset-metals.md` |
| Project sbt `.jvmopts` template (4G) | `references/jvmopts` |
| Reset Metals script | `scripts/reset-metals.sh` |
| Applied user keybindings | `~/Library/Application Support/Cursor/User/keybindings.json` |
| Applied user settings | `~/Library/Application Support/Cursor/User/settings.json` |

## Current keymap

| Shortcut | Action | When |
|---|---|---|
| `Ctrl+Shift+J` | Join lines | Editor focused, not readonly |
| `Ctrl+G` | Add selection to next find match | Editor focused |
| `Ctrl+G` | Go to Line (default) | **Unbound** |
| `Ctrl+Cmd+G` | Select all occurrences | Editor focused |
| `Alt+Q` | Open current file in IntelliJ IDEA at cursor line | Editor focused |
| `F2` | Rename file in explorer | Files explorer focused |
| `Enter` | Rename file (default) | **Unbound** in explorer |
| `Alt+Cmd+S` | Toggle unified sidebar | Not auxiliary window |
| `Cmd+I` | Open Cursor Agent (composer) | Default |
| `Cmd+Y` | AI chat follow-up (default) | **Unbound** |
| `F1` | Go to Definition (was F12) | Editor with definition provider |
| `Alt+F1` | Peek Definition (was Alt+F12) | Editor with definition provider |
| `Cmd+F1` | Go to Implementation (was Cmd+F12) | Editor with implementation provider |
| `Shift+F1` | Go to References (was Shift+F12) | Editor with reference provider |
| `Shift+Alt+F1` | Find All References view (was Shift+Alt+F12) | Editor with reference provider |
| `F1` | Command Palette (default) | **Unbound** — use `Cmd+Shift+P` |
| `F12` / `Alt+F12` / `Cmd+F12` / `Shift+F12` / `Shift+Alt+F12` | Navigation defaults | **Unbound** |

### Join lines

Place the cursor on a line and press **Ctrl+Shift+J** to merge it with the next line (`editor.action.joinLines`).

On macOS the VS Code default is **Cmd+Shift+J**; this toolbox uses **Ctrl+Shift+J** instead.

### Add selection to next match

Select a word/region and press **Ctrl+G** to add the next occurrence to the multi-cursor selection (`editor.action.addSelectionToNextFindMatch`).

This overrides the macOS default **Go to Line** on `Ctrl+G` (still available via Command Palette).

### Select all occurrences

Select a word/region and press **Ctrl+Cmd+G** to select every matching occurrence (`editor.action.selectHighlights`).

### Open in IntelliJ IDEA

**Alt+Q** runs a terminal sequence that opens the active file at the current line in IntelliJ IDEA, then returns focus to the editor.

### F1 replaces all F12 navigation

Touch-bar / keyboard layouts that lack a reliable **F12** use **F1** for the whole F12 navigation family:

| Was | Now | Command |
|---|---|---|
| `F12` | `F1` | Go to Definition |
| `Alt+F12` | `Alt+F1` | Peek Definition |
| `Cmd+F12` | `Cmd+F1` | Go to Implementation |
| `Shift+F12` | `Shift+F1` | Go to References |
| `Shift+Alt+F12` | `Shift+Alt+F1` | Find All References (side view) |

Default **F1** Command Palette is unbound; use **Cmd+Shift+P**. Old **F12** chords are unbound so they do not conflict.

## Current Metals settings

Configure in Cursor **User** settings (not workspace `.vscode/settings.json` for machine-scoped keys).

| Setting | Key | Value |
|---|---|---|
| Bloop JVM flags | `metals.bloopJvmProperties` | `["-Xmx4G", "-Xss4m"]` |
| Apply Bloop heap to all profiles | `workbench.settings.applyToAllProfiles` | `["metals.bloopJvmProperties"]` |
| Auto-import builds | `metals.autoImportBuilds` | `initial` |
| Excluded packages | `metals.excludedPackages` | `["akka.actor.typed.javadsl"]` |
| Prefer build-tool BSP (sbt) | `metals.defaultBspToBuildTool` | `true` |

### Bloop heap

`metals.bloopJvmProperties` is **`scope: machine`** — set under **User** settings only; workspace values are ignored.

After changing Bloop heap, accept Metals’ prompt to **apply and restart Bloop**, or run **Metals: Restart build server**.

Verify: `pgrep -fl 'bloop.Bloop' | tr ' ' '\n' | grep '^\-X'` should include `-Xmx4G`.

### Reset Metals (sbt build server)

When Metals is stuck, Bloop caches are stale, or the user wants a clean **sbt BSP** import — full steps and cautions: [references/reset-metals.md](references/reset-metals.md).

**Agent:** merge `metals.defaultBspToBuildTool: true` → run `scripts/reset-metals.sh <project-root>` (`--global` only if asked).  
The script also ensures project-root `.jvmopts` with **`-Xmx4G`** (template [references/jvmopts](references/jvmopts)), removes `.jvmopts` from `.gitignore` if present, and **deletes `.sbtopts` if present**.

**User (Cmd+Shift+P), in order:**
1. **Metals: Restart server** (or Reload Window)
2. **Metals: Switch build server** → **sbt** (critical after Bloop-stuck state)
3. **Metals: Import build**

**Cautions (do not skip):**
- A live Bloop daemon overrides `defaultBspToBuildTool`; Metals reconnects to Bloop and may show `Missing valid Bloop build` after `.bloop/` was deleted.
- Always force-kill Bloop and regenerate `.bsp/sbt.json` (`sbt bspConfig`) before restart.
- Cursor may respawn Metals (and Bloop) if you kill the Metals JVM from the shell — prefer Command Palette **Switch → sbt**.
- `.jvmopts` caps **sbt/sbt-BSP** heap at 4G; it does not replace `metals.bloopJvmProperties` (Bloop) or Metals’ own JVM.
- Project-root `.jvmopts` is **shared with CI** — keep it tracked; do not gitignore or untrack.
- Delete project-root `.sbtopts` if present — its `-J-Xmx…` overrides `.jvmopts`.
- Do not delete Coursier/Ivy/sbt boot caches unless explicitly asked.

### Exclude `.superpowers/` from git

Superpowers / SDD local state under **project-root** `.superpowers/` must not be committed.

When the user asks to ignore it, or when setting up a Scala/Stey workspace that uses Superpowers:

1. Ensure the repo `.gitignore` contains a line: `.superpowers/`
2. If any paths under `.superpowers/` are already tracked:

```bash
git rm -r --cached .superpowers
```

3. Confirm: `git check-ignore -v .superpowers/` prints the `.gitignore` rule.
4. Do **not** commit `.gitignore` unless the user asks (or they explicitly want the ignore rule shared with the team).

## Agent workflow

### Keybindings

When the user asks to add, change, or remove a shortcut:

1. Read `references/keymap.json` and `~/Library/Application Support/Cursor/User/keybindings.json`.
2. Update `references/keymap.json` first (canonical).
3. Merge into the user `keybindings.json`:
   - Preserve entries not managed by this skill (e.g. `_toai_managed`, other personal bindings).
   - To **unbind** a default, add `{ "key": "...", "command": "-commandName", "when": "..." }`.
   - To **override** a default, add the new binding; VS Code resolves by specificity.
4. Confirm the shortcut and whether a window reload is needed (usually not).

Do not overwrite unrelated user keybindings. Merge surgically.

### User settings

When the user asks to add, change, or remove a skill-managed setting:

1. Read `references/settings.json` and `~/Library/Application Support/Cursor/User/settings.json`.
2. Update `references/settings.json` first (canonical).
3. Merge keys from `references/settings.json` into the user `settings.json`:
   - Preserve all keys not listed in `references/settings.json`.
   - For array settings (e.g. `workbench.settings.applyToAllProfiles`), merge skill entries without removing unrelated profile keys.
4. Confirm the setting and whether a reload or **Metals: Import build** / **Metals: Restart build server** is needed.

Do not overwrite unrelated user settings. Merge surgically.

### Reset Metals

When the user asks to reset Metals / clear Bloop·BSP caches / switch to sbt as build server / reports `Missing valid Bloop build`:

1. Read [references/reset-metals.md](references/reset-metals.md) (steps + cautions + triage).
2. Merge `metals.defaultBspToBuildTool: true` into User settings if missing.
3. Run `scripts/reset-metals.sh` against the project root (use `--global` only when requested) — creates/updates `.jvmopts` to `-Xmx4G`, removes `.jvmopts` from `.gitignore` if present, and **deletes `.sbtopts` if present**. Never `git rm --cached .jvmopts`.
4. Confirm `.jvmopts` has `-Xmx4G`, exists on disk, is **not** ignored, preferably tracked, project-root `.sbtopts` is absent, `.bsp/sbt.json` exists, and `.bloop/` is gone.
5. Instruct the user Command Palette order: **Restart server** → **Switch build server → sbt** → **Import build**.
6. Verify via `.metals/metals.log`: `Connected to Build server: sbt`.

### Exclude `.superpowers/` from git

When the user asks to exclude / ignore `.superpowers/`:

1. Add `.superpowers/` to the project `.gitignore` if missing (append; do not rewrite unrelated entries).
2. If tracked: `git rm -r --cached .superpowers` (keeps files on disk).
3. Verify with `git check-ignore -v .superpowers/`.
4. Commit only if the user asks.

## Adding a binding

Template for `references/keymap.json`:

```json
{
  "key": "ctrl+shift+j",
  "command": "editor.action.joinLines",
  "when": "editorTextFocus && !editorReadonly"
}
```

Modifier keys on macOS: `cmd`, `ctrl`, `alt`, `shift`.

## Reference index

| When you need... | Read |
|---|---|
| Full binding JSON | [references/keymap.json](references/keymap.json) |
| Full managed settings JSON | [references/settings.json](references/settings.json) |
| Reset Metals / sbt BSP | [references/reset-metals.md](references/reset-metals.md) |
| Project sbt `.jvmopts` (4G) | [references/jvmopts](references/jvmopts) |
| Cache wipe script | [scripts/reset-metals.sh](scripts/reset-metals.sh) |

## Activation keywords

`stl-ide-toolbox`, `keybinding`, `keyboard shortcut`, `join lines`, `Ctrl+Shift+J`, `Ctrl+G`, `Ctrl+Cmd+G`, `add selection`, `select all occurrences`, `IntelliJ`, `Alt+Q`, `F1`, `F12`, `Go to Definition`, `Cursor shortcuts`, `Metals`, `Bloop`, `metals.bloopJvmProperties`, `reset Metals`, `Metals reset`, `sbt build server`, `defaultBspToBuildTool`, `.metals`, `.bloop`, `.bsp`, `Missing valid Bloop build`, `Switch build server`, `bspConfig`, `.jvmopts`, `.sbtopts`, `Xmx4G`, `sbt heap`, `tracked .jvmopts`, `.superpowers`, `gitignore`, `exclude from git`.
