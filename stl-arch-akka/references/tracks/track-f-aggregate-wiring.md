# Track F - Aggregate Wiring

Read:

- `../topics/folder-layout.md`
- `../examples/aggregate-architecture-templates.md`

Checklist:

- [ ] `*CommandDispatcher` and `*EventDispatcher` are at aggregate root.
- [ ] `Aggregate` returns `Behavior[Command]` from `Behaviors.setup`.
- [ ] Aggregate startup passes required config and implicit wiring consistently.
- [ ] State is under `state/` and imported as `state.State`.
- [ ] Aggregate event wiring calls `EventDispatcher.dispatch(state = state, event = event)`.
- [ ] There is no obsolete monolithic root `*EventHandler.scala` once per-event handlers live under `event/`.
- [ ] No `aggregate/README.md` under the impl module; architecture docs live in repo `AGENTS.md` and `stl-arch-akka` only.
