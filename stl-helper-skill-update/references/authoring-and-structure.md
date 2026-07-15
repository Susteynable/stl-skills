# Authoring and Structure

Use this as the canonical reference for skill layout, `SKILL.md` format, and progressive-disclosure rules.

## Directory shape

```text
my-skill/
|- SKILL.md
|- references/
|- scripts/
`- assets/
```

Roles:

| Path | Owns | Load timing |
|---|---|---|
| `SKILL.md` | Routing, workflow, guardrails, reference index | Always |
| `references/` | Long rules, specs, checklists, lookup docs | Only when needed |
| `scripts/` | Repeatable validation or automation | Execute/verify steps |
| `assets/` | Templates or reusable output skeletons | Output stage |

Storage locations for Cursor:

| Type | Path |
|---|---|
| Personal | `~/.cursor/skills/<name>/` |
| Project | `.cursor/skills/<name>/` |
| Forbidden | `~/.cursor/skills-cursor/` |

## `SKILL.md` rules

Front matter:

- `name` is required, lowercase kebab-case, unique, ideally matches the directory.
- `description` is required, third person, focused on trigger conditions, max 1024 chars.
- `dependencies` is optional and only needed when `scripts/` require runtime packages.

Playbook body should usually contain:

1. Purpose
2. Workflow
3. Guardrails
4. Reference index
5. Optional activation keywords

## Size and disclosure rules

- Target `SKILL.md` at 100 lines or fewer when possible; hard limit 500.
- Move heavy content from `SKILL.md` into `references/` once it stops being routing-critical.
- Split references by concern so the agent can read only one topic at a time.
- Keep links one hop from `SKILL.md` to the owning file.
- Do not leave duplicate long-form rules in both `SKILL.md` and `references/`.

## Anti-patterns

- Long tables or large examples in `SKILL.md`
- Deep link chains between references
- Windows path separators in examples
- Mixing synonymous terms without choosing one
- Templates embedded inline when `assets/` can own them

## Checklist

- [ ] `name` matches directory intent
- [ ] `description` helps routing instead of summarizing the whole workflow
- [ ] `SKILL.md` only contains routing-critical content
- [ ] Each reference file owns one concern
- [ ] Validator exists when the skill has structural rules worth enforcing
- [ ] The updated skill is fully optimized, consolidating overlapping contents and removing redundant instructions
