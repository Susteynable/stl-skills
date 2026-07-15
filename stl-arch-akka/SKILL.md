---
name: stl-arch-akka
description: >-
  Stey Akka CQRS architecture via tracks A-Q. Use for aggregates, events,
  processors, Kafka, setup/rebuild, Jackson, gRPC surfaces, sealed ADTs, or
  delegate extraction. Coding style belongs in stl-convention.
---

# Stey Akka Architecture

Use for Stey Akka CQRS reviews, refactors, setup/rebuild, Jackson sealed-ADT fixes, Kafka consumers, and gRPC delegate extraction. Coding style and Slick live in **`stl-convention`**.

## Workflow

1. Classify as one track, a range, or a full review.
2. Read `references/tracks/track-index.md`, then only the selected track files and linked topics.
3. For full reviews, run **A → Q**; report Pass, Fail, Skipped, or N/A.
4. Stay inside the selected track unless a checklist item requires an adjacent track.
5. Singular package layout is required — see `references/topics/folder-layout.md` (no plural legacy folders).
6. For tier-boundary CI, copy `scripts/audit_*.sh` + `audit.env.example` into the repo (`references/topics/architecture-audit-scripts.md`); run `bash scripts/run_all_audits.sh` before merge on aggregate refactors.
7. When editing handler/delegate code shape or naming, also load **`stl-convention`**.

## Reference Index

| Need | Start here |
|------|------------|
| Track order and scope | `references/tracks/track-index.md` |
| Review reporting | `references/review-routine.md` |
| Onion layers / boundaries / inline remap | `references/topics/onion-model.md`, `references/topics/onion-boundary-rules.md`, `references/topics/inline-boundary-remap.md` |
| Package layout | `references/topics/folder-layout.md` |
| Display-only tags and logs | `references/topics/display-only-tags-and-logs.md` |
| Internal tier isolation | `references/topics/internal-boundary-types.md` |
| Jackson / sealed ADTs / `impl.enums` | `references/topics/aggregate-json-serialization.md`, `references/topics/impl-enums-string-enum.md`, `references/examples/impl-enums-string-enum-template.md` |
| gRPC delegate extraction | `references/topics/grpc-surface-delegate-extraction.md` |
| Coding style (handlers, naming, Slick) | skill `stl-convention` |
| Canonical aggregate shape | `references/examples/aggregate-architecture-templates.md` |
| Audit scripts | `scripts/audit_*.sh`, `scripts/audit.env.example`, `references/topics/architecture-audit-scripts.md` |
| Case studies | `references/case-studies/` |

## Guardrails

- Keep API, service, internal, command, event, state, entity, and table models separate; redefine shapes per tier (no cross-tier ADT sharing except allowed primitives / `impl.enums.*`).
- **Internal:** write-path input ADTs on `object *Internal`; public `class *Internal` takes `*Internal.*` only — no `aggregate.state` imports. See `internal-boundary-types.md`.
- **Boundaries:** inline field remap at the call site; no mapper objects, `*ToTable`/`*FromTable`, or companion `to*Grpc`/`from*Grpc`. See `onion-boundary-rules.md`, `inline-boundary-remap.md`.
- Parent `Command` / `Event` traits stay **unsealed** (one case class per file). Nested companion ADTs may be sealed.
- Thin `*ServiceImpl` + capability-typed delegates for extraction; style details in **`stl-convention`**.
- Singular package segments (`implicits` plural). See `folder-layout.md`.
- **Jackson:** aggregate journal ADTs — `@JsonTypeInfo(NAME)` + `@JsonSubTypes(value = classOf[...])` only (no `include` / `property` / subtype `name=`). Table JSON columns — `property = "_type"` + explicit `name=`. `object *Internal` serializer-free; no aggregate `columnMapper` (use `*Table` / `impl.enums`). See `aggregate-json-serialization.md`.
- No `aggregate/README.md`; architecture docs in repo-root `AGENTS.md` + this skill.
- Mark skipped tracks in full reviews. Handlers validate from `state` (Track E); coding shape is **`stl-convention`**.
- **Tags/logs display-only** — not in write-path validation/business logic; may emit as side effects. See `display-only-tags-and-logs.md`.

## Repo documentation (Track Q)

Keep repo-root **`AGENTS.md`** as the project mirror of onion rules. Sync from: `onion-model`, `onion-boundary-rules`, `inline-boundary-remap`, `folder-layout`, `display-only-tags-and-logs`, `architecture-audit-scripts`, `impl-enums-string-enum` + template; style sections from **`stl-convention`**. Do not paste A→Q checklists. Add repo gates, setup/rebuild modes, known debt. Create `AGENTS.md` before large refactors (SteyCrs shape). After onion rule changes here, update affected `AGENTS.md` in the same or a follow-up PR. Detail checklist: `references/tracks/track-q-tests-and-documentation.md`.
