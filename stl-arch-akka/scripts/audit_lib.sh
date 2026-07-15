#!/usr/bin/env bash
# Shared path/config loader for stl-arch-akka architecture audit scripts.
# Copy scripts/ and audit.env.example → repo scripts/audit.env, then run from repo root.
#
# Optional env overrides (set in scripts/audit.env or export before running):
#   AUDIT_REPO_ROOT          — repo root (default: parent of scripts/)
#   AUDIT_IMPL_MODULE        — sbt impl module (e.g. stey-crs-impl)
#   AUDIT_IMPL_PKG_PATH      — main sources under module (e.g. com/stey/crs/impl)
#   AUDIT_GRPC_IMPORT        — ripgrep pattern for forbidden internal grpc imports
#   AUDIT_ENTITY_IMPORT      — ripgrep pattern for forbidden state→entity imports
#   AUDIT_STATE_ADT_PATTERN  — state ADT refs forbidden on command/event definitions
#   AUDIT_INTERNAL_STATE_IMPORT — state package imports forbidden in aggregate/internal
#   AUDIT_INTERNAL_FLAT_PARAM_PATTERN — optional; skip flat-param gate when empty
#   AUDIT_SERIALIZATION_SPEC_DIR — test dir for serialization tier specs (relative to repo root)
#   AUDIT_FORBIDDEN_REL_PATHS — space-separated paths relative to AUDIT_MAIN
#   AUDIT_STATE_SUBDIR_ALLOWLIST — "subdir:File1.scala,File2.scala" (optional extra-file gate)

audit_load_config() {
  local script_dir="${1:-}"
  [[ -n "$script_dir" ]] || script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  : "${AUDIT_REPO_ROOT:=$(cd "$script_dir/.." && pwd)}"

  if [[ -f "$script_dir/audit.env" ]]; then
    # shellcheck source=/dev/null
    source "$script_dir/audit.env"
  elif [[ -z "${AUDIT_IMPL_MODULE:-}" || -z "${AUDIT_IMPL_PKG_PATH:-}" ]]; then
    echo "FAIL: missing scripts/audit.env (copy audit.env.example from stl-arch-akka/scripts/ and set AUDIT_IMPL_MODULE + AUDIT_IMPL_PKG_PATH)"
    exit 1
  fi

  AUDIT_MAIN="${AUDIT_REPO_ROOT}/${AUDIT_IMPL_MODULE}/src/main/scala/${AUDIT_IMPL_PKG_PATH}"
  AUDIT_AGGREGATE="${AUDIT_MAIN}/aggregate"
  AUDIT_COMMAND="${AUDIT_AGGREGATE}/command"
  AUDIT_EVENT="${AUDIT_AGGREGATE}/event"
  AUDIT_STATE="${AUDIT_AGGREGATE}/state"
  AUDIT_INTERNAL="${AUDIT_AGGREGATE}/internal"
  AUDIT_PRODUCER="${AUDIT_MAIN}/projection/producer"
  AUDIT_ENTITY="${AUDIT_MAIN}/entity"

  : "${AUDIT_GRPC_IMPORT:=com\\.stey\\..*\\.api\\.grpc}"
  : "${AUDIT_ENTITY_IMPORT:=com\\.stey\\..*\\.impl\\.entity}"
  : "${AUDIT_STATE_ADT_PATTERN:=[A-Za-z0-9]+State\\.}"
  : "${AUDIT_INTERNAL_STATE_IMPORT:=com\\.stey\\..*\\.impl\\.aggregate\\.state}"
  : "${AUDIT_INTERNAL_FLAT_PARAM_PATTERN:=}"
  : "${AUDIT_SERIALIZATION_SPEC_DIR:=${AUDIT_IMPL_MODULE}/src/test/scala/${AUDIT_IMPL_PKG_PATH}/serialization}"
  : "${AUDIT_FORBIDDEN_REL_PATHS:=}"
  : "${AUDIT_STATE_SUBDIR_ALLOWLIST:=}"

  if [[ ! -d "$AUDIT_MAIN" ]]; then
    echo "FAIL: AUDIT_MAIN not found: $AUDIT_MAIN"
    echo "Set AUDIT_IMPL_MODULE and AUDIT_IMPL_PKG_PATH in scripts/audit.env (see audit.env.example)."
    exit 1
  fi
}

audit_repo_root() {
  audit_load_config "${1:-}"
  printf '%s\n' "$AUDIT_REPO_ROOT"
}
