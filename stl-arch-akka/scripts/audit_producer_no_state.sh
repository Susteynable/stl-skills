#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

if [[ ! -d "$AUDIT_PRODUCER" ]]; then
  echo "PASS: producer tier gate skipped (no projection/producer directory)"
  exit 0
fi

if rg -n 'import com\.stey\..*\.impl\.aggregate\.state|import com\.stey\..*\.aggregate\.state' "$AUDIT_PRODUCER" -g'*.scala' 2>/dev/null; then
  echo "FAIL: projection/producer must not import aggregate.state"
  exit 1
fi

echo "PASS: producer tier has no state imports"
