#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

SPEC_DIR="${AUDIT_REPO_ROOT}/${AUDIT_SERIALIZATION_SPEC_DIR}"
failures=0

for spec in StateJacksonSpec EventJacksonSpec; do
  file="$SPEC_DIR/${spec}.scala"
  if [[ ! -f "$file" ]]; then
    echo "FAIL: ${spec}.scala missing under $SPEC_DIR"
    failures=$((failures + 1))
    continue
  fi
  if rg -q "$AUDIT_ENTITY_IMPORT" "$file" 2>/dev/null; then
    echo "FAIL: $spec imports entity tier (use TableJacksonSpec for table ADTs)"
    failures=$((failures + 1))
  fi
done

if [[ ! -f "$SPEC_DIR/TableJacksonSpec.scala" ]]; then
  echo "FAIL: TableJacksonSpec.scala missing under $SPEC_DIR"
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi

echo "PASS: serialization spec imports match tier boundaries"
