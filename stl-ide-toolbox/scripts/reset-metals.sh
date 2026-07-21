#!/usr/bin/env bash
# Wipe Metals / Bloop / BSP workspace caches so Metals can reimport with sbt BSP.
# Usage: reset-metals.sh [project-root] [--global]
set -euo pipefail

ROOT="${1:-.}"
GLOBAL=0
if [[ "${1:-}" == "--global" ]]; then
  ROOT="."
  GLOBAL=1
elif [[ "${2:-}" == "--global" ]]; then
  GLOBAL=1
fi

ROOT="$(cd "$ROOT" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JVMOPTS_TEMPLATE="${SCRIPT_DIR}/../references/jvmopts"

ensure_jvmopts() {
  local dest="$ROOT/.jvmopts"
  echo "Ensuring project sbt JVM heap (.jvmopts → -Xmx8G)…"
  if [[ ! -f "$dest" ]]; then
    if [[ -f "$JVMOPTS_TEMPLATE" ]]; then
      cp "$JVMOPTS_TEMPLATE" "$dest"
    else
      cat >"$dest" <<'EOF'
-Xms100m
-Xmx8G
-Xss4m
-XX:+UnlockExperimentalVMOptions
-XX:+UseZGC
EOF
    fi
    echo "  created $dest"
  else
    # Preserve other flags; force max heap to 8G.
    if grep -qE '^-Xmx' "$dest"; then
      # portable in-place: rewrite via temp
      local tmp
      tmp="$(mktemp)"
      sed -E 's/^-Xmx.*/-Xmx8G/' "$dest" >"$tmp"
      mv "$tmp" "$dest"
      echo "  updated -Xmx to 8G in $dest"
    else
      printf '\n-Xmx8G\n' >>"$dest"
      echo "  appended -Xmx8G to $dest"
    fi

    # JDK 11 (and some builds) require unlock before UseZGC.
    if grep -qE '^-XX:\+UseZGC' "$dest" && ! grep -qE '^-XX:\+UnlockExperimentalVMOptions' "$dest"; then
      local tmp
      tmp="$(mktemp)"
      sed -E 's/^-XX:\+UseZGC$/-XX:+UnlockExperimentalVMOptions\
-XX:+UseZGC/' "$dest" >"$tmp"
      mv "$tmp" "$dest"
      echo "  inserted -XX:+UnlockExperimentalVMOptions before UseZGC in $dest"
    fi
  fi

  # Hard rule: machine-local heap config — keep on disk, never commit.
  local gi="$ROOT/.gitignore"
  if [[ -f "$gi" ]] && ! grep -qxF '.jvmopts' "$gi"; then
    printf '\n.jvmopts\n' >>"$gi"
    echo "  appended .jvmopts to $gi"
  elif [[ ! -f "$gi" ]]; then
    printf '.jvmopts\n' >"$gi"
    echo "  created $gi with .jvmopts"
  else
    echo "  .jvmopts already ignored in $gi"
  fi

  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$ROOT" ls-files --error-unmatch .jvmopts >/dev/null 2>&1; then
      git -C "$ROOT" rm --cached --quiet .jvmopts
      echo "  untracked .jvmopts from git index (local file kept)"
    fi
  fi
}

# .sbtopts -J-Xmx… is applied after .jvmopts and silently overrides heap (e.g. 8G → 2G).
# This toolbox uses .jvmopts only — delete project-root .sbtopts if present.
remove_sbtopts() {
  local dest="$ROOT/.sbtopts"
  if [[ -f "$dest" ]]; then
    echo "Removing project .sbtopts (conflicts with .jvmopts heap)…"
    if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
      && git -C "$ROOT" ls-files --error-unmatch .sbtopts >/dev/null 2>&1; then
      git -C "$ROOT" rm --quiet .sbtopts
      echo "  git-rm $dest (was tracked)"
    else
      rm -f "$dest"
      echo "  removed $dest"
    fi
  else
    echo "No project .sbtopts (ok — .jvmopts is sole heap source)"
  fi
}

ensure_jvmopts
remove_sbtopts

echo "Stopping Bloop (if running)…"
# Metals will reconnect to any live Bloop daemon and ignore sbt unless Bloop is gone.
pkill -9 -f 'bloop\.Bloop' 2>/dev/null || true
pkill -9 -f 'BloopServer' 2>/dev/null || true
pkill -9 -f 'ScalaCli/bloop' 2>/dev/null || true
sleep 1
if pgrep -fl 'bloop\.Bloop|BloopServer' >/dev/null 2>&1; then
  echo "  WARN: Bloop still running — kill leftover PIDs before restarting Metals"
  pgrep -fl 'bloop\.Bloop|BloopServer' || true
else
  echo "  Bloop stopped"
fi

echo "Removing workspace Metals/Bloop caches under: $ROOT"
# Keep regenerating .bsp via sbt bspConfig below; wipe old BSP first.
for path in \
  "$ROOT/.metals" \
  "$ROOT/.bloop" \
  "$ROOT/.bsp" \
  "$ROOT/project/metals.sbt" \
  "$ROOT/project/project/metals.sbt"
do
  if [[ -e "$path" ]]; then
    rm -rf "$path"
    echo "  removed $path"
  else
    echo "  skip (missing) $path"
  fi
done

if [[ "$GLOBAL" -eq 1 ]]; then
  echo "Removing global Bloop/Metals caches…"
  for path in \
    "$HOME/.bloop" \
    "$HOME/Library/Caches/ScalaCli/bloop" \
    "$HOME/Library/Caches/org.scalameta.metals" \
    "$HOME/Library/Caches/metals"
  do
    if [[ -e "$path" ]]; then
      rm -rf "$path"
      echo "  removed $path"
    else
      echo "  skip (missing) $path"
    fi
  done
fi

echo "Generating sbt BSP connection (.bsp/sbt.json)…"
if command -v sbt >/dev/null 2>&1; then
  (cd "$ROOT" && sbt -batch 'bspConfig')
  if [[ -f "$ROOT/.bsp/sbt.json" ]]; then
    echo "  wrote $ROOT/.bsp/sbt.json"
  else
    echo "  WARN: .bsp/sbt.json missing after bspConfig"
  fi
else
  echo "  WARN: sbt not on PATH — skip bspConfig"
fi

echo "Done. Next in Cursor Command Palette (this order):"
echo "  1) Metals: Restart server  (or Developer: Reload Window)"
echo "  2) Metals: Switch build server → sbt   ← critical if previously on Bloop"
echo "  3) Metals: Import build"
echo ""
echo "Cautions:"
echo "  - metals.defaultBspToBuildTool=true is required but NOT enough if Bloop is running"
echo "  - 'Missing valid Bloop build' means still connected to Bloop after .bloop wipe → Switch to sbt"
echo "  - Cursor may respawn Metals/Bloop if you kill Metals from the shell; use Switch build server"
echo "  - Verify: .metals/metals.log contains 'Connected to Build server: sbt'"
