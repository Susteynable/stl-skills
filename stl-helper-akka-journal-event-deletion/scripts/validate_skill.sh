#!/usr/bin/env bash
# Validates stl-helper-akka-journal-event-deletion skill.
set -euo pipefail
SKILL_DIR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "ERROR: $*" >&2; exit 1; }
[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
"$SCRIPT_DIR/../../_shared/scripts/validate_skill_base.sh" "$SKILL_DIR"
for ref in references/core-retirement.md references/tracks/track-index.md   references/tracks/track-a-ownership-and-scope.md references/tracks/track-b-safety-and-diagnostics.md   references/tracks/track-c-code-retirement.md references/tracks/track-d-evolution-cleanup-sql.md   references/tracks/track-e-verification-and-handoff.md; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing: $ref"
done
echo "OK: stl-helper-akka-journal-event-deletion references present"
