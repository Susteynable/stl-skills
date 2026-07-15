#!/usr/bin/env bash
# Verify APM env keys match across reference.conf, service chart deployment.yaml,
# and stey-env values files.
#
# Usage:
#   check_apm_env_pairing.sh --reference-conf PATH [--deployment PATH] [--stey-env PATH ...]
#
# Exit 0 if all provided targets agree on the APM_* key set; exit 1 otherwise.

set -euo pipefail

REFERENCE_CONF=""
DEPLOYMENT=""
STEY_ENVS=()

usage() {
  sed -n '2,6p' "$0" | tail -n +2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reference-conf) REFERENCE_CONF="${2:-}"; shift 2 ;;
    --deployment) DEPLOYMENT="${2:-}"; shift 2 ;;
    --stey-env) STEY_ENVS+=("${2:-}"); shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

[[ -n "$REFERENCE_CONF" ]] || { echo "ERROR: --reference-conf is required" >&2; exit 2; }
[[ -f "$REFERENCE_CONF" ]] || { echo "ERROR: not found: $REFERENCE_CONF" >&2; exit 1; }

canonical_from_reference() {
  {
    grep -E '^[[:space:]]*# Env: APM_' "$REFERENCE_CONF" \
      | sed -E 's/.*# Env: (APM_[A-Z0-9_]+).*/\1/'
    grep -oE '\$\{\?APM_[A-Z0-9_]+\}' "$REFERENCE_CONF" \
      | sed 's/\${?//;s/}//'
  } | sort -u
}

keys_from_deployment() {
  [[ -n "$DEPLOYMENT" && -f "$DEPLOYMENT" ]] || return 0
  grep -E 'key: APM_' "$DEPLOYMENT" | sed -E 's/.*key: (APM_[A-Z0-9_]+).*/\1/' | sort -u
}

keys_from_stey_env_file() {
  local file="$1"
  grep -E '^      APM_' "$file" | sed -E 's/^      (APM_[A-Z0-9_]+):.*/\1/' | sort -u
}

stey_env_uniform_blocks() {
  local file="$1"
  awk '
    /^    [a-z0-9-]+:/ {
      if (svc != "") counts[svc] = n
      svc = $1
      gsub(/:/, "", svc)
      n = 0
      next
    }
    /^      APM_/ { n++; next }
    END {
      if (svc != "") counts[svc] = n
      ref = -1
      for (s in counts) {
        if (ref < 0) ref = counts[s]
        else if (counts[s] != ref) {
          printf "ERROR: uneven APM key counts in %s — %s has %d, expected %d per service block\n",
            FILENAME, s, counts[s], ref > "/dev/stderr"
          exit 1
        }
      }
    }
  ' "$file"
}

CANONICAL=$(canonical_from_reference)
CANONICAL_FILE=$(mktemp)
echo "$CANONICAL" > "$CANONICAL_FILE"
trap 'rm -f "$CANONICAL_FILE"' EXIT

ERR=0

report_diff() {
  local label="$1"
  local other="$2"
  local missing extra
  missing=$(comm -23 "$CANONICAL_FILE" <(echo "$other"))
  extra=$(comm -13 "$CANONICAL_FILE" <(echo "$other"))
  if [[ -n "$missing" ]]; then
    echo "MISSING in $label (expected from reference.conf):"
    echo "$missing" | sed 's/^/  /'
    ERR=1
  fi
  if [[ -n "$extra" ]]; then
    echo "EXTRA in $label (not in reference.conf):"
    echo "$extra" | sed 's/^/  /'
    ERR=1
  fi
}

echo "Canonical APM keys from reference.conf:"
echo "$CANONICAL" | sed 's/^/  /'

if [[ -n "$DEPLOYMENT" ]]; then
  if [[ ! -f "$DEPLOYMENT" ]]; then
    echo "ERROR: not found: $DEPLOYMENT" >&2
    exit 1
  fi
  DEP_KEYS=$(keys_from_deployment)
  echo ""
  echo "Chart: $DEPLOYMENT"
  report_diff "chart deployment.yaml" "$DEP_KEYS"
fi

for env_file in "${STEY_ENVS[@]}"; do
  if [[ ! -f "$env_file" ]]; then
    echo "ERROR: not found: $env_file" >&2
    exit 1
  fi
  ENV_KEYS=$(keys_from_stey_env_file "$env_file")
  echo ""
  echo "stey-env: $env_file"
  report_diff "$env_file" "$ENV_KEYS"
  if ! stey_env_uniform_blocks "$env_file"; then
    ERR=1
  fi
done

if [[ "$ERR" -eq 0 ]]; then
  echo ""
  echo "OK: APM env pairing check passed."
else
  echo ""
  echo "FAIL: fix chart and/or stey-env — see references/operations/apm-env-pairing.md"
  exit 1
fi
