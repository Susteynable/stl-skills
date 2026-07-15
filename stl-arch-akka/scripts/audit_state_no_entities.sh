#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

if rg -n "import ${AUDIT_ENTITY_IMPORT}" "$AUDIT_STATE" -g'*.scala' 2>/dev/null; then
  echo "FAIL: aggregate/state must not import entity tier"
  exit 1
fi

echo "PASS: state tier has no entity imports"
