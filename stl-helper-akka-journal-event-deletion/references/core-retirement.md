# Core Retirement

Use this as the canonical reference for Tracks A through E.

## Ownership and scope

- The journal-owning service is the only valid place for this workflow.
- Confirm the aggregate owner, event ADT owner, and journal schema owner before any deletion work.

## Safety and diagnostics

- Identify the exact `event_ser_manifest` FQN.
- Check whether target rows are tail-only or interleaved with still-live events.
- Consider replay, snapshot, and projection consequences before deleting journal rows.
- Back up production data before destructive cleanup.

## Code retirement

- Remove the event from the ADT and serializer surface.
- Remove handlers, emitters, and downstream references that exist only for the retired event.
- Keep unrelated aggregate behavior untouched.

## Evolution cleanup SQL

- Use a destructive evolution only when the event really must be removed from journal storage.
- Cleanup SQL should target the intended manifest precisely.
- Down evolutions should document non-reversibility rather than fake row restoration.

## Verification and handoff

- Report event FQN, owning service, diagnostics scope, and evolution location.
- Record whether replay or rebuild follow-up is needed.
- Call out remaining projection or snapshot risk explicitly.
