---
name: stl-helper-akka-journal-event-deletion
description: >-
  Use when retiring an Akka Persistence event in the journal-owning service,
  including code removal and `event_journal` cleanup by
  `event_ser_manifest` FQN.
---

# Akka Journal Event Deletion

## Purpose

Retire an event from both code and journal storage in the service that owns the aggregate and journal schema.

## Workflow

1. Read `references/tracks/track-index.md` to classify scope.
2. Use `references/core-retirement.md` for ownership, safety, diagnostics, code removal, and evolution cleanup rules.
3. Run Tracks A through E unless the request is explicitly narrower.
4. Use the SQL assets for diagnostics or cleanup scaffolding.
5. Report owning service, event FQN, evolution file, and verification outcome.

## Guardrails

- Stop if another service owns the aggregate or journal schema.
- Do not delete mid-stream rows without a rebuild plan for replay, snapshots, and projections.
- Back up production data before destructive SQL.
- Keep code diffs minimal and event-specific.
- Down evolutions must not attempt to reinsert deleted journal rows.

## Tracks

| Track | Focus |
|---|---|
| A | Ownership and scope |
| B | Safety and diagnostics |
| C | Code retirement |
| D | Evolution cleanup SQL |
| E | Verification and handoff |

## Reference Index

| When you need... | Read |
|---|---|
| Track order | `references/tracks/track-index.md` |
| Ownership, safety, diagnostics, code removal, SQL rules | `references/core-retirement.md` |
| Cleanup SQL scaffold | `assets/journal-cleanup-evolution.sql` |
| Diagnostics bundle | `assets/journal-diagnostics.sql` |

## Activation Keywords

`delete event`, `event_journal`, `event_ser_manifest`, `retire domain event`, `Akka Persistence`, `journal cleanup`, `sequence gap`.
