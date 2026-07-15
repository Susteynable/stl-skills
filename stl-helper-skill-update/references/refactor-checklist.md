# Refactor Checklist

Use this when an existing `SKILL.md` is too large, duplicates deeper docs, or mixes routing with heavy reference material.

## 1. Audit

- [ ] Record `SKILL.md` line count.
- [ ] Mark long tables, examples, and specs that are not needed for routing.
- [ ] Mark duplicate rules repeated across `SKILL.md`, references, templates, or scripts.
- [ ] List existing `references/`, `scripts/`, and `assets/` files.

## 2. Plan ownership

Choose one owner per concern:

- Routing and guardrails -> `SKILL.md`
- Heavy rules or specs -> `references/<topic>.md`
- Reusable template -> `assets/<name>.md`
- Repeatable checks -> `scripts/<name>.sh`

## 3. Slim `SKILL.md`

Keep only:

1. Front matter
2. Purpose
3. Workflow
4. Guardrails
5. Reference index
6. Optional activation keywords

## 4. Remove duplicates

- Replace extracted sections with one reference-index row.
- Delete low-value stub files instead of keeping two weak copies.
- Merge overlapping references into one stronger source when they share the same trigger.

## 5. Verify

- [ ] `SKILL.md` stays under the line limit.
- [ ] Every indexed file exists.
- [ ] Template and validator still match the final structure.
- [ ] `scripts/validate_skill.sh <skill-dir>` passes.

## 6. Optimize and Consolidate

- [ ] Review all modified and newly created skill files to ensure there are no overlapping instructions or duplicate sections.
- [ ] Consolidate similar or related rules into single reference files where possible, to prevent fragmented documentation.
- [ ] Prune unused links/indices and simplify wording to maintain the highest density of actionable instructions.
