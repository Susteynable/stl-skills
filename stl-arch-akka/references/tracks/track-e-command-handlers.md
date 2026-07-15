# Track E - Command Handlers

Read:

- `../examples/aggregate-architecture-templates.md`
- `../topics/display-only-tags-and-logs.md`
- Coding style (Either.cond, assign-then-yield, naming, companions): skill **`stl-convention`**

Checklist:

- [ ] New commands are wired in `*CommandDispatcher`.
- [ ] Commands and their colocated CommandHandlers are defined in a single file per command under `aggregate/command/` (singular; not `commandhandlers/`).
- [ ] Top-level/file-level imports in each command file are combined into a single contiguous block under the `package` statement (see the Import Rearrangement subroutine below).
- [ ] Handlers return `Either[AggregateException, ...]` then `recover` / `intercept` / `reply`.
- [ ] Handler coding shape follows **`stl-convention`** (`Either.cond`, assign-then-yield, `runDispatcher` / `import state._`, intentful helper names).
- [ ] Command-to-event mapping is inline and field-by-field; no private `toEvent`/`toXxx` helpers.
- [ ] Setup commands emit events only; no Slick/projection writes in handlers.
- [ ] Handler logic does not import table, entity, or shared cross-tier model types as write-path inputs (handlers may read `State` for validation).
- [ ] Validation and branching use first-class domain state, not tag membership or log artifacts (see `../topics/display-only-tags-and-logs.md`); tag/log events may be emitted only as display/audit side effects.

## Import Rearrangement Subroutine

Because Command and CommandHandler objects are colocated in a single file, top-level imports can become split across the file. Use the following routine to combine and rearrange them:

### The Rules
1. **Combine Top-Level Imports**: All imports defined at the file scope (outside any class, trait, object, or method body) must be gathered into a single contiguous block directly under the `package` declaration.
2. **Preserve Relative Raw Order**: The top-level imports must be kept in their original relative order of appearance (without sorting or restructuring).
3. **Deduplicate**: Remove exact duplicate import statements, preserving their first occurrence.
4. **Keep Parameter-Dependent Imports Local**: Any local imports inside method bodies that depend on method parameters or local variables (such as `import state._`, `import command._`, etc.) **must remain** inside the method body to prevent compilation/scope errors.

### Implementation Outline
You can use a Python script or custom regex parsing to perform the rearrangement:
- Parse lines and strip block/line comments and string literals (preserving newlines to keep line numbers intact).
- Track the curly brace nesting level.
- For any line starting with 'import ' at `brace_level == 0` (top-level):
  - Extract the import line.
  - Mark the line for deletion.
- Insert the unique/deduplicated extracted imports right under the 'package ' line.
- Clean up consecutive blank lines.
