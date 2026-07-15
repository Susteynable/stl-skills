# Slick Refactor Report

**File:** `<path/to/Delegate.scala>`
**Date:** `<YYYY-MM-DD>`

## Tracks Reviewed

| Track | Status | Notes |
|-------|--------|-------|
| A - Query Construction | Pass / Fail / Skipped | |
| B - Execution Boundaries | Pass / Fail / Skipped | |
| C - Inner Join Shaping | Pass / Fail / Skipped | |
| D - Left Join Layering | Pass / Fail / Skipped | |
| E - Request Filtering | Pass / Fail / Skipped | |
| F - Projection, Count, Paging | Pass / Fail / Skipped | |
| G - Review Checklist | Pass / Fail / Skipped | |

## Changes Applied

- `<change 1>`
- `<change 2>`

## Semantics Check

- [ ] Query results unchanged (naming/structure only).
- [ ] Terminal actions moved to `db.run` / `ctx.db.run`.
- [ ] No inner joins left in `qJoined`.

## Follow-ups

- `<optional follow-up>`
