# Slick tracks A–G

Read `../core-conventions.md`, then verify the tracks in scope (or A→G for a full review).

| Track | Use for | Verify |
|-------|---------|--------|
| A | Query construction | Stages use `qXXXX`; `qBase` (or equivalent) owns the shared base shape |
| B | Execution boundaries | `db.run` at the boundary; helpers return query structure, not rows; flat `qXXXX = ...` then `<- db.run(...)` — not `{ val q...; db.run }` or query+execute `locally` |
| C | Inner joins | Multi-table inner joins use a clear consistent structure; single-table filters are not over-wrapped |
| D | Left joins | Remain `joinLeft` chains; optional joined data does not blur layer ownership |
| E | Request filtering | `filterOpt` / `filterIf` / `in.filter.fold` where appropriate; no duplicated query branches for conditionals |
| F | Projection, count, paging | Order is consistent; count matches the filtered data query |
| G | Final review | Structural conventions improved without semantic drift unless requested |
