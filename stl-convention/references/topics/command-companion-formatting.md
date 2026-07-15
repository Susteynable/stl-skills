# Command companion formatting and ordering

Applies to aggregate command case classes under `aggregate/command/` (one command per file). Architectural placement (unsealed parent `Command`, one file per command) is owned by **`stl-arch-akka`**; this topic owns formatting only.

## Placement

The companion object must immediately follow the main case class or trait with **no blank line** between them.

```scala
final case class MyCommand(...) extends Command {
  ...
}
object MyCommand {
  ...
}
```

## Member order inside `object MyCommand`

Define members in this order, with blank-line rules as noted:

1. **ADT models** — sealed traits then case classes; **no** blank line before a trait’s companion object.
2. **Exceptions** — base exception (`extends AggregateException`), then concrete exceptions **sequentially with no blank lines between them**.
3. **`Reply`** — last.

```scala
object MyCommand {
  sealed trait Payload
  object Payload {
    final case class A(...) extends Payload
    final case class B(...) extends Payload
  }

  abstract class MyCommandException(message: String) extends AggregateException(message)
  final case class NotFound(id: UUID) extends MyCommandException(s"...")
  final case class Inactive(id: UUID) extends MyCommandException(s"...")

  final case class Reply(id: UUID)
}
```

## Related

- Handler style: `command-handler-coding-style.md` · Onion command layer: `stl-arch-akka` → `onion-model.md`
