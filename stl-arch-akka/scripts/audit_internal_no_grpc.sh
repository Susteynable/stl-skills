#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

if rg -q "$AUDIT_GRPC_IMPORT" "$AUDIT_INTERNAL" 2>/dev/null; then
  echo "FAIL: aggregate/internal must not import service grpc API package"
  rg "$AUDIT_GRPC_IMPORT" "$AUDIT_INTERNAL"
  exit 1
fi

if rg -q 'def fromRequest' "$AUDIT_INTERNAL" 2>/dev/null; then
  echo "FAIL: fromRequest must not exist on internal companions"
  rg 'def fromRequest' "$AUDIT_INTERNAL"
  exit 1
fi

if rg -q 'def apply\(in: com\.stey\..*\.api\.grpc' "$AUDIT_INTERNAL" 2>/dev/null; then
  echo "FAIL: grpc apply overloads must not exist on internal companions"
  exit 1
fi

echo "PASS: internal tier is proto-free"
