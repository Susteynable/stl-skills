#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

if rg -n 'spray\.json|RootJsonFormat|JsonFormat\[|readDbString|writeDbString|JacksonSerializer|JacksonDeserializer|JsonSerializable' "$AUDIT_INTERNAL" 2>/dev/null; then
  echo "FAIL: internal tier defines serialization on *Internal companions"
  exit 1
fi

echo "PASS: internal tier has no spray/Jackson serialization"
