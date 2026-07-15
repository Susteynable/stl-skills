#!/usr/bin/env bash
# Validates stl-arch-play skill.
set -euo pipefail
SKILL_DIR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "ERROR: $*" >&2; exit 1; }
[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
"$SCRIPT_DIR/../../_shared/scripts/validate_skill_base.sh" "$SKILL_DIR"
for ref in references/core-architecture.md references/controller-patterns.md   references/path-security-error-conventions.md references/cors-exposed-headers.md   references/tracks/track-index.md references/tracks/track-a-application-wiring.md   references/tracks/track-b-controller-dsl.md references/tracks/track-c-auto-route-package-naming.md   references/tracks/track-d-request-response-naming.md references/tracks/track-e-path-security-errors.md   references/tracks/track-f-cors-and-downloads.md; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing: $ref"
done
echo "OK: stl-arch-play references present"
