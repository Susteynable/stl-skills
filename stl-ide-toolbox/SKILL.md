---
name: stl-ide-toolbox
description: >-
  Personal Cursor/VS Code editor keymap, Metals/Scala IDE settings, and
  shortcuts for macOS. Use when configuring keyboard shortcuts, Bloop heap,
  join lines, opening files in IntelliJ IDEA, sidebar toggles, or when the
  user mentions stl-ide-toolbox, editor shortcuts, or keybindings.
---

# STL IDE Toolbox

## Purpose

Document and maintain personal Cursor editor keybindings and **User settings** (Metals/Scala) on **macOS**.

## Canonical sources

| Role | Path |
|---|---|
| Skill keymap (source of truth) | `references/keymap.json` |
| Skill settings (source of truth) | `references/settings.json` |
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

## Current Metals settings

Configure in **Cursor User settings** (not workspace `.vscode/settings.json` for machine-scoped keys).

| Setting | Key | Value |
|---|---|---|
| Bloop JVM flags | `metals.bloopJvmProperties` | `["-Xmx8G", "-Xss4m", "-XX:+UseZGC"]` |
| Apply Bloop heap to all profiles | `workbench.settings.applyToAllProfiles` | `["metals.bloopJvmProperties"]` |
| Auto-import builds | `metals.autoImportBuilds` | `initial` |
| Excluded packages | `metals.excludedPackages` | `["akka.actor.typed.javadsl"]` |

### Bloop heap

`metals.bloopJvmProperties` is **`scope: machine`** — set under **User** settings only; workspace values are ignored.

After changing Bloop heap, accept Metals’ prompt to **apply and restart Bloop**, or run **Metals: Restart build server**.

Verify: `pgrep -fl 'bloop.Bloop' | tr ' ' '\n' | grep '^\-X'`

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

## Activation keywords

`stl-ide-toolbox`, `keybinding`, `keyboard shortcut`, `join lines`, `Ctrl+Shift+J`, `Ctrl+G`, `Ctrl+Cmd+G`, `add selection`, `select all occurrences`, `IntelliJ`, `Alt+Q`, `Cursor shortcuts`, `Metals`, `Bloop`, `metals.bloopJvmProperties`.
