#!/usr/bin/env bash
# Validates stl-arch-akka skill.
set -euo pipefail

SKILL_DIR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
"$SCRIPT_DIR/../../_shared/scripts/validate_skill_base.sh" "$SKILL_DIR"

required_dirs=(
  references/tracks
  references/topics
  references/examples
  references/case-studies
  scripts
)
for dir in "${required_dirs[@]}"; do
  [[ -d "$SKILL_DIR/$dir" ]] || die "Missing directory: $dir"
done

required_tracks=(
  references/tracks/track-index.md
  references/tracks/track-a-api-contracts.md
  references/tracks/track-b-grpc-surfaces.md
  references/tracks/track-c-application-internal-services.md
  references/tracks/track-d-command-model.md
  references/tracks/track-e-command-handlers.md
  references/tracks/track-f-aggregate-wiring.md
  references/tracks/track-g-run-flow.md
  references/tracks/track-h-event-model.md
  references/tracks/track-i-event-handling-and-state.md
  references/tracks/track-j-state-model.md
  references/tracks/track-k-processor-and-read-model.md
  references/tracks/track-l-producer-and-integrations.md
  references/tracks/track-m-entity-tables.md
  references/tracks/track-n-setup-and-rebuild.md
  references/tracks/track-o-aggregate-serialization.md
  references/tracks/track-p-kafka-consumers.md
  references/tracks/track-q-tests-and-documentation.md
)
for ref in "${required_tracks[@]}"; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing track file: $ref"
done

required_topics=(
  references/topics/api-protobuf-pattern.md
  references/topics/architecture-audit-scripts.md
  references/topics/aggregate-json-serialization.md
  references/topics/entity-table-constraints.md
  references/topics/entity-table-json-types.md
  references/topics/folder-layout.md
  references/topics/grpc-surface-delegate-extraction.md
  references/topics/internal-boundary-types.md
  references/topics/jackson-sealed-adt-audit.md
  references/topics/jackson-sealed-adt-template.md
  references/topics/kafka-consumer-template.md
  references/topics/kafka-projection-consumers.md
  references/topics/onion-boundary-rules.md
  references/topics/onion-model.md
  references/topics/run-pattern.md
  references/topics/setup-process.md
  references/topics/test-akka-remoting-ports.md
)
for ref in "${required_topics[@]}"; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing topic file: $ref"
done

required_case_studies=(
  references/case-studies/grpc-surface-steycrs-case-study.md
  references/case-studies/jackson-sealed-adt-stey-crm-examples.md
  references/case-studies/jackson-serialization-stey-crs-refactor.md
)
for ref in "${required_case_studies[@]}"; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing case study: $ref"
done

required_examples=(
  references/examples/aggregate-architecture-templates.md
)
for ref in "${required_examples[@]}"; do
  [[ -f "$SKILL_DIR/$ref" ]] || die "Missing example file: $ref"
done

[[ -x "$SKILL_DIR/scripts/audit_lib.sh" ]] || die "Missing executable: scripts/audit_lib.sh"
[[ -f "$SKILL_DIR/scripts/audit.env.example" ]] || die "Missing: scripts/audit.env.example"
[[ -x "$SKILL_DIR/scripts/run_all_audits.sh" ]] || die "Missing executable: scripts/run_all_audits.sh"

audit_scripts=(
  audit_command_no_state.sh
  audit_event_no_state.sh
  audit_command_dispatcher_coverage.sh
  audit_event_handler_coverage.sh
  audit_internal_no_grpc.sh
  audit_internal_no_cross_tier.sh
  audit_internal_no_serialization.sh
  audit_internal_flat_params.sh
  audit_missing_jackson.sh
  audit_serialization_colocated.sh
  audit_serialization_spec_tiers.sh
  audit_state_no_entities.sh
  audit_producer_no_state.sh
)
for script in "${audit_scripts[@]}"; do
  [[ -x "$SKILL_DIR/scripts/$script" ]] || die "Missing executable: scripts/$script"
done

if find "$SKILL_DIR" -name .DS_Store -print -quit | grep -q .; then
  die "Remove .DS_Store files from skill"
fi

for old in references/review-tracks.md references/review-checklist.md; do
  [[ ! -e "$SKILL_DIR/$old" ]] || die "Remove old flat track file: $old"
done

grep -q "track-q-tests-and-documentation.md" "$SKILL_DIR/references/tracks/track-index.md" || die "track-index.md missing Track Q"
grep -q "references/tracks/track-index.md" "$SKILL_DIR/SKILL.md" || die "SKILL.md missing track index pointer"
grep -q "references/topics/jackson-sealed-adt-template.md" "$SKILL_DIR/scripts/audit_missing_jackson.sh" || die "audit_missing_jackson.sh points at old template path"

echo "OK: stl-arch-akka standard layout valid; tracks A-Q present"
