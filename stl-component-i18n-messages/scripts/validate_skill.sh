#!/usr/bin/env bash
# Validates stl-component-i18n-messages skill.
set -euo pipefail
SKILL_DIR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "ERROR: $*" >&2; exit 1; }
[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
"$SCRIPT_DIR/../../_shared/scripts/validate_skill_base.sh" "$SKILL_DIR"
for ref in references/core-patterns.md references/tracks/track-index.md   references/tracks/track-a-scope-and-storage.md references/tracks/track-b-message-resources.md   references/tracks/track-c-code-resolution.md references/tracks/track-d-api-wiring.md   references/tracks/track-e-db-catalog-removal.md references/tracks/track-f-verification.md; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing: $ref"
done
echo "OK: stl-component-i18n-messages references present"
