#!/usr/bin/env bash
# Validates stl-helper-service-src-navigator skill.
set -euo pipefail
SKILL_DIR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "ERROR: $*" >&2; exit 1; }
[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
"$SCRIPT_DIR/../../_shared/scripts/validate_skill_base.sh" "$SKILL_DIR"
for ref in references/dictionary.md assets/service-resolution-report.md; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing: $ref"
done
echo "OK: stl-helper-service-src-navigator references present"
