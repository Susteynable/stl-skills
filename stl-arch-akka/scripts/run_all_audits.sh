#!/usr/bin/env bash
# Run all architecture audit gates. Exit non-zero on first failure unless AUDIT_CONTINUE=1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
shopt -s nullglob
scripts=( "$SCRIPT_DIR"/audit_*.sh )
shopt -u nullglob

skip=( audit_lib.sh run_all_audits.sh )
fail=0

for s in "${scripts[@]}"; do
  base="$(basename "$s")"
  for sk in "${skip[@]}"; do
    [[ "$base" == "$sk" ]] && continue 2
  done
  echo "=== $base ==="
  if ! bash "$s"; then
    fail=1
    [[ "${AUDIT_CONTINUE:-0}" == 1 ]] || exit 1
  fi
  echo
done

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "All architecture audits passed."
