#!/usr/bin/env bash
# Reports sealed ADT traits under aggregate/ and entity/ that lack Jackson annotations.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=audit_lib.sh
source "$SCRIPT_DIR/audit_lib.sh"
audit_load_config "$SCRIPT_DIR"

SCAN=(
  "$AUDIT_COMMAND"
  "$AUDIT_EVENT"
  "$AUDIT_STATE"
  "$AUDIT_ENTITY"
)
LOOKBACK=20

fail=0
for base in "${SCAN[@]}"; do
  [[ -d "$base" ]] || continue
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    [[ "$file" == *Internal.scala ]] && continue
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      num="${line%%:*}"
      rest="${line#*:}"
      trait_name=$(echo "$rest" | sed -n 's/.*sealed trait \([A-Za-z0-9_]*\).*/\1/p')
      [[ -n "$trait_name" ]] || continue
      start=$((num - LOOKBACK))
      [[ "$start" -lt 1 ]] && start=1
      context=$(sed -n "${start},${num}p" "$file" 2>/dev/null || true)
      if echo "$context" | grep -q 'JsonTypeInfo'; then
        if ! echo "$context" | grep -q 'JsonSubTypes'; then
          echo "WARN  $file:$num  $trait_name missing @JsonSubTypes"
          fail=1
        fi
      elif echo "$context" | grep -qE 'JsonSerialize|JacksonSerializer|JacksonDeserializer'; then
        :
      else
        echo "MISSING Jackson  $file:$num  $trait_name"
        fail=1
      fi
    done < <(rg -n 'sealed trait [A-Za-z0-9_]+ extends' "$file" 2>/dev/null || true)
  done < <(find "$base" -name '*.scala' -type f 2>/dev/null)
done

AGGREGATE_SCAN=("$AUDIT_COMMAND" "$AUDIT_EVENT" "$AUDIT_STATE")
for base in "${AGGREGATE_SCAN[@]}"; do
  [[ -d "$base" ]] || continue
  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    echo "FORBIDDEN legacy Jackson polymorphism on aggregate ADT: $hit"
    fail=1
  done < <(rg -n 'include = JsonTypeInfo\.As\.PROPERTY|property = "_type"|JsonSubTypes\.Type\([^)]*name = ' "$base" 2>/dev/null || true)
done

if [[ "$fail" -ne 0 ]]; then
  echo "FAIL: sealed ADTs missing preferred Jackson annotation pattern"
  echo "Aggregate command/event/state: use @JsonTypeInfo(use = JsonTypeInfo.Id.NAME) + @JsonSubTypes(value = classOf[...]) only."
  echo "See stl-arch-akka references/topics/jackson-sealed-adt-template.md"
  exit 1
fi

echo "PASS: sealed ADTs use @JsonTypeInfo with @JsonSubTypes (or colocated custom serializers)"
