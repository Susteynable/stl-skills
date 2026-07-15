---
name: stl-convention
description: >-
  Stey Scala coding conventions: handler/delegate style (Either.cond,
  assign-then-yield, resolve*/build*Events/maybe*), command companions, and
  Slick query layering (qXXXX, db.run, qBase/qJoined). Not onion architecture
  (use stl-arch-akka).
---

# Stey Scala Coding Conventions

Implementation style for Stey Scala / Akka services:

- **Scala style** — naming, for-comprehensions, command companions, surface delegates
- **Slick** — `qXXXX` construction, `db.run` boundaries, joins, filters, paging

Architecture (onion, Jackson, audits): **`stl-arch-akka`**.

## Workflow

1. Classify as **Scala style**, **Slick**, or both.
2. Read only the matching references (for Slick reviews use tracks A→G in `references/slick/tracks/track-index.md`).
3. Prefer/avoid patterns only — do not change domain or query semantics on naming/style-only edits.
4. Unclear boundaries → switch to `stl-arch-akka` (no mappers / shared ADTs).

## Guardrails

**Scala style** — `Either.cond` for boolean validation; assign-then-yield for multi-part results; intentful names (`resolve*`, `build*Events`, `maybe*`); delegate helpers `private` to the object; write-path in `*Internal`; fixed command companion order. Details: `references/topics/`.

**Slick** — Any `db.run` / `ctx.db.run`: flat `qXXXX = ...` then `<- db.run` (no block/`locally` query+execute); single-table filters stay direct; left joins as `joinLeft` chains; in `qBase`, join `if` on the generator line, filter `if` after all tables. Details: `references/slick/core-conventions.md`.

Do not duplicate onion / Jackson / package rules — **`stl-arch-akka`**.

## Reference Index

| Need | Start here |
|------|------------|
| Command handler validation, event yield, helper implicits | `references/topics/command-handler-coding-style.md` |
| Var / method naming | `references/topics/var-and-method-naming.md` |
| Command companion formatting | `references/topics/command-companion-formatting.md` |
| Surface delegate helpers | `references/topics/delegate-coding-style.md` |
| Slick core + tracks A–G | `references/slick/core-conventions.md`, `references/slick/tracks/track-index.md` |
| Slick refactor report template | `assets/slick-refactor-report-template.md` |
| Onion / CQRS architecture | skill `stl-arch-akka` |

## Activation Keywords

`Either.cond`, `assign-then-yield`, `resolve*`, `build*Events`, `maybe*`, command companion, delegate helpers, `qXXXX`, `XXXXRows`, `db.run`, `ctx.db.run`, `filterOpt`, `filterIf`, `qBase`, `qJoined`, `joinLeft`, Slick.
