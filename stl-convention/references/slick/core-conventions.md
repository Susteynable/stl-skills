# Slick core conventions

Use this as the canonical reference for Slick tracks A through G under `tracks/`.

## Naming and execution

- Build queries first, execute them second.
- Use `qXXXX` names for query stages.
- Use `XXXXRows` names for executed result sets.
- Keep `db.run` at the execution boundary, not inside query helpers.

## For-comp query style

When queries live inside a for-comprehension with `db.run` or `ctx.db.run`:

- Define query stages as for-comp assignments (`qBase = ...`, `qSearch = ...`), then execute on the next line (`rows <- db.run(qSearch.result)` or `rows <- ctx.db.run(qSearch.result)`).
- Avoid wrapping query construction plus execution in a block passed to `<-`:
  - `rows <- { val qBase = ...; db.run(qBase.result) }`
  - `rows <- locally { val qBase = ...; db.run(qBase.result) }`
- Reserve `locally { }` for pure computation that does not pair query construction with `db.run` (for example adjacent-room ID calculation or random room selection).
- The first line in a for-comp must be a `<-` generator before any `=` query assignments; use `_ <- Future.unit` when the block starts with query stages.
- Outside a for-comp (for example inside `match` / `case` branches), use `val qBase = ...` then `db.run(...)` — not for-comp `=` assignments.

## Query layers

- `qBase` owns the shared table set and base filters.
- `qJoined` owns post-join shaping when the query grows beyond `qBase`.
- Keep each layer responsible for one structural step.

## Join shaping

- Inner joins can use clear for-comprehension structure when multiple tables participate.
- Single-table filters should stay direct and not be forced into for-comprehension style.
- Left joins remain `joinLeft` chains rather than mixed comprehension styles.

## Request filtering

- Use `in.filter.fold` when an optional collection should either no-op or apply a filter.
- Use `filterOpt` and `filterIf` where they make conditional filters simpler and clearer.
- Keep request-filter logic close to the query layer it affects.

## Projection, count, and paging

- Shape row projections before execution.
- Keep count queries and paged data queries structurally related so they stay in sync.
- Apply paging after the intended filter and sort set is complete.

## Review checklist

- Query construction and execution are separated.
- Stage names explain structure, not business narrative.
- Join style is consistent with query type.
- Optional filters do not create branching duplication.
- Count and page behavior remain aligned.
