#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

FAIL=0

if [[ -d "$AUDIT_MAIN/serialization" ]]; then
  echo "FAIL: serialization/ package still exists under impl main"
  FAIL=1
fi

if find "$AUDIT_STATE" -name '*Jackson.scala' 2>/dev/null | grep -q .; then
  echo "FAIL: *Jackson.scala under aggregate/state"
  find "$AUDIT_STATE" -name '*Jackson.scala'
  FAIL=1
fi

if find "$AUDIT_STATE" \( -name '*Types.scala' -o -name '*Forwarders.scala' \) 2>/dev/null | grep -q .; then
  echo "FAIL: *Types.scala or *Forwarders.scala under aggregate/state"
  find "$AUDIT_STATE" \( -name '*Types.scala' -o -name '*Forwarders.scala' \)
  FAIL=1
fi

if [[ -n "$AUDIT_FORBIDDEN_REL_PATHS" ]]; then
  for rel in $AUDIT_FORBIDDEN_REL_PATHS; do
    forbidden="$AUDIT_MAIN/$rel"
    if [[ -f "$forbidden" ]]; then
      echo "FAIL: forbidden file $forbidden"
      FAIL=1
    fi
  done
fi

if [[ -n "$AUDIT_STATE_SUBDIR_ALLOWLIST" ]]; then
  for entry in $AUDIT_STATE_SUBDIR_ALLOWLIST; do
    [[ -n "$entry" ]] || continue
    subdir="${entry%%:*}"
    allow_csv="${entry#*:}"
    subdir_path="$AUDIT_STATE/$subdir"
    [[ -d "$subdir_path" ]] || continue
    IFS=',' read -r -a allowed <<< "$allow_csv"
    while IFS= read -r extra; do
      [[ -n "$extra" ]] || continue
      base="$(basename "$extra")"
      ok=0
      for a in "${allowed[@]}"; do
        [[ "$base" == "$a" ]] && ok=1 && break
      done
      if [[ "$ok" -eq 0 ]]; then
        echo "FAIL: extra file under state/$subdir/: $extra (allowed: $allow_csv)"
        FAIL=1
      fi
    done < <(find "$subdir_path" -maxdepth 1 -name '*.scala' -type f 2>/dev/null)
  done
fi

if rg -n 'writeSprayJsonAsString' "$AUDIT_MAIN" -g'*.scala' 2>/dev/null; then
  echo "FAIL: writeSprayJsonAsString still used"
  FAIL=1
fi

AGGREGATE_SCAN=("$AUDIT_COMMAND" "$AUDIT_EVENT" "$AUDIT_STATE")
for base in "${AGGREGATE_SCAN[@]}"; do
  [[ -d "$base" ]] || continue
  if rg -n 'implicit def columnMapper|MappedColumnType\.base' "$base" -g'*.scala' 2>/dev/null; then
    echo "FAIL: Slick columnMapper on aggregate command/event/state ADT (use object *Table instead)"
    FAIL=1
  fi
done

if rg -n 'format\.write\(' "$AUDIT_MAIN" -g'*.scala' 2>/dev/null | rg 'JacksonSerializer|serialize\(' 2>/dev/null; then
  echo "FAIL: spray format.write inside JacksonSerializer"
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi

echo "PASS: serialization is colocated; no forbidden central packages"
