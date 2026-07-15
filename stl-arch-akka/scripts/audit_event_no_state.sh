#!/usr/bin/env bash
# Event tier: event ADTs must not reference state-owned types.
# Event handlers may import and use state ADTs (state mutation via monocle, etc.).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

event_definition_section() {
  awk '/^object [A-Za-z0-9]+EventHandler / { exit } { print }' "$1"
}

fail=0
for f in "$AUDIT_EVENT"/*.scala; do
  [[ -f "$f" ]] || continue
  section="$(event_definition_section "$f")"

  if printf '%s\n' "$section" | rg -v '^[[:space:]]*import ' | rg -q "$AUDIT_STATE_ADT_PATTERN" 2>/dev/null; then
    echo "FAIL: $f event definition references state ADTs (handlers may use state ADTs)"
    printf '%s\n' "$section" | rg -v '^[[:space:]]*import ' | rg "$AUDIT_STATE_ADT_PATTERN" || true
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "PASS: event ADTs have no state references; handlers may import state ADTs"
