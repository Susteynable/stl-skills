#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

HANDLER="$AUDIT_AGGREGATE/EventDispatcher.scala"

missing=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  if ! grep -q "${name}" "$HANDLER"; then
    echo "FAIL: EventDispatcher missing case for ${name}"
    missing=1
  fi
done < <(rg '^final case class ([A-Za-z0-9]+)' "$AUDIT_EVENT" -or '$1' --no-filename 2>/dev/null | sort -u)

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "PASS: EventDispatcher covers all event case classes"
