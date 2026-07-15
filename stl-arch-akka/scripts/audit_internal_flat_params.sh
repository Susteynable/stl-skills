#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

if [[ -z "$AUDIT_INTERNAL_FLAT_PARAM_PATTERN" ]]; then
  echo "PASS: internal flat-params gate skipped (set AUDIT_INTERNAL_FLAT_PARAM_PATTERN in audit.env to enable)"
  exit 0
fi

if rg -q "$AUDIT_INTERNAL_FLAT_PARAM_PATTERN" "$AUDIT_INTERNAL" 2>/dev/null; then
  echo "FAIL: internal methods must use flat parameters, not request case classes"
  rg "$AUDIT_INTERNAL_FLAT_PARAM_PATTERN" "$AUDIT_INTERNAL"
  exit 1
fi

echo "PASS: internal tier uses flat parameters"
