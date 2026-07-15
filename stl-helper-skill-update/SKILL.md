---
name: stl-helper-skill-update
description: >-
  Refactors or authors Cursor agent skills using modular progressive disclosure.
  Use when updating a skill, splitting an oversized SKILL.md, adding
  references, or reviewing skill structure.
---

# Update Skill

## Purpose

Use this skill to keep Cursor skills evidence-first: a lean `SKILL.md`, heavy detail in `references/`, automation in `scripts/`, and templates in `assets/`.

## Workflow

1. Measure the current skill: `SKILL.md` size, duplicate sections, stale links, and missing structure.
2. Diagnose concrete defects before changing anything.
3. Read `references/authoring-and-structure.md` for format, layout, and disclosure rules.
4. Read `references/refactor-checklist.md` when slimming or modularizing an existing skill.
5. Apply the smallest change that removes the measured defect.
6. Update the reference index so each extracted file has one clear owner.
7. Run `scripts/validate_skill.sh <skill-dir>` and confirm the original defects are resolved.
8. Optimize and consolidate: After editing, review the files to eliminate overlapping rules, merge duplicate reference contents, and ensure maximum instructional density.

## Guardrails

- Never write skills under `~/.cursor/skills-cursor/`.
- Personal skills live in `~/.cursor/skills/<name>/`; project skills live in `.cursor/skills/<name>/`.
- Keep `SKILL.md` under 500 lines; target 100 or fewer when possible.
- Keep heavy specs, tables, and templates out of `SKILL.md` once extracted.
- Keep reference links one hop from `SKILL.md`.

## Reference Index

| When you need... | Read |
|---|---|
| Layout, front matter, playbook sections, size limits | `references/authoring-and-structure.md` |
| Step-by-step refactor flow for a bloated skill | `references/refactor-checklist.md` |
| Starter file for a new skill | `assets/SKILL-template.md` |

## Activation Keywords

`update skill`, `refactor skill`, `split SKILL.md`, `progressive disclosure`, `skill structure`, `references folder`, `skill front matter`, `modular skill`, `evidence-driven skill edit`.
