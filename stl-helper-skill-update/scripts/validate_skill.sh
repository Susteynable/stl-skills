#!/usr/bin/env bash
# Validates skill directory structure and SKILL.md front matter.
set -euo pipefail

SKILL_DIR="${1:-}"
MAX_SKILL_LINES=500
WARN_SKILL_LINES=100

die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

[[ -n "$SKILL_DIR" ]] || die "Usage: validate_skill.sh <skill-dir>"
[[ -d "$SKILL_DIR" ]] || die "Not a directory: $SKILL_DIR"

SKILL_MD="$SKILL_DIR/SKILL.md"
[[ -f "$SKILL_MD" ]] || die "Missing SKILL.md in $SKILL_DIR"

lines=$(wc -l < "$SKILL_MD" | tr -d ' ')
if [[ "$lines" -gt "$MAX_SKILL_LINES" ]]; then
  die "SKILL.md has $lines lines (max $MAX_SKILL_LINES). Split into references/."
fi
if [[ "$lines" -gt "$WARN_SKILL_LINES" ]]; then
  warn "SKILL.md has $lines lines; consider progressive disclosure (target <=$WARN_SKILL_LINES)."
fi

head -1 "$SKILL_MD" | grep -q '^---$' || die "SKILL.md must start with YAML front matter (---)"
name=$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_MD" | head -n 1 | tr -d '" ''' )
[[ -n "$name" ]] || die "Missing 'name:' in front matter"
dir_name=$(basename "$SKILL_DIR")
[[ "$name" == "$dir_name" ]] || warn "name '$name' does not match directory '$dir_name'"
[[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "name must be lowercase kebab-case: $name"

desc=$(awk 'BEGIN{in_fm=0; in_desc=0} /^---$/{if(in_fm==0){in_fm=1; next} else exit} in_fm && /^description:/{in_desc=1} in_desc{print}' "$SKILL_MD" | tr -d '
' | sed 's/^description:[[:space:]]*//')
[[ -n "$desc" ]] || die "Missing 'description:' in front matter"
if [[ ${#desc} -gt 1024 ]]; then
  die "description exceeds 1024 characters (${#desc})"
fi
if [[ ${#desc} -gt 250 ]]; then
  warn "description is ${#desc} chars; aim for ~200 for routing clarity"
fi

for sub in references scripts assets; do
  [[ -d "$SKILL_DIR/$sub" ]] && echo "OK: $sub/ present"
done

echo "OK: skill '$name' validated ($lines lines in SKILL.md)"
