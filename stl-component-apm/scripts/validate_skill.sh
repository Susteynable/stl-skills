#!/usr/bin/env bash
# Validates stl-component-apm skill.
set -euo pipefail
SKILL_DIR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo "ERROR: $*" >&2; exit 1; }
[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
"$SCRIPT_DIR/../../_shared/scripts/validate_skill_base.sh" "$SKILL_DIR"
for ref in references/core-rollout.md references/runtime-and-probes.md references/troubleshooting.md   references/tracks/track-index.md references/tracks/track-a-scope-and-git-sync.md   references/tracks/track-b-library-and-version-baseline.md references/tracks/track-c-service-configuration.md   references/tracks/track-d-logback-and-runtime-logs.md references/tracks/track-e-error-and-probe-lifecycle.md   references/tracks/track-f-helm-chart-env-wiring.md references/tracks/track-g-stey-env-values-and-region-pairing.md   references/tracks/track-h-ci-source-context-upload.md references/tracks/track-i-verification-and-rollout.md   references/tracks/track-j-troubleshooting.md; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing: $ref"
done
echo "OK: stl-component-apm references present"
