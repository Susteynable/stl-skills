#!/usr/bin/env bash
# Internal tier: must not import aggregate.state (write-path ADTs live on object *Internal).
# Command imports are allowed for askWithStatus construction inside method bodies.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

: "${AUDIT_INTERNAL_STATE_IMPORT:=com\\.stey\\..*\\.impl\\.aggregate\\.state}"

if [[ ! -d "$AUDIT_INTERNAL" ]]; then
  echo "SKIP: no aggregate/internal directory at $AUDIT_INTERNAL"
  exit 0
fi

if rg -q "$AUDIT_INTERNAL_STATE_IMPORT" "$AUDIT_INTERNAL" 2>/dev/null; then
  echo "FAIL: aggregate/internal must not import aggregate.state (define write-path ADTs on object *Internal)"
  rg "$AUDIT_INTERNAL_STATE_IMPORT" "$AUDIT_INTERNAL"
  exit 1
fi

echo "PASS: internal tier has no aggregate.state imports"
