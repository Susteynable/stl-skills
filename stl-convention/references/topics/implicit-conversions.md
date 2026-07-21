# Prefer in-scope implicit conversions

When an implicit conversion is already in scope, do **not** write explicit conversion calls. Rely on the expected type to apply the conversion.

## Elementary types (delegates / surfaces)

Delegates that mix in `ElementaryTypeConversions` (and import `implicits.converters._`) already provide:

- `UUID` ↔ `String`
- `BigDecimal` ↔ `String`
- `LocalDate` ↔ `String`

Plus `liftConversion` so `Option[A]` / collections lift when `A => B` exists.

```scala
// Preferred — uuidToString in scope via ElementaryTypeConversions
.withUser(userId = Some(userPrincipal.userId))

// Avoid — redundant when the implicit is in scope
.withUser(userId = Some(userPrincipal.userId.toString))
```

Same idea: prefer bare values over `.asUUID`, `.asBigDecimal`, `.asLocalDate`, `.toString` when the target type is already constrained and the matching implicit is in scope.

Do **not** treat sibling files that still use `.toString` (or similar) as a reason to “fix” new code — that is style drift, not a type error. PR / review bots that flag “UUID vs String mismatch” here are usually false positives when `ElementaryTypeConversions` is mixed in.

## Enums and ADTs ↔ gRPC

`impl.enums.*` (and other intentional companions) often expose `implicit def toGrpc` / `fromGrpc`. When those implicits are in scope and the call site expects the gRPC (or domain) type, pass the value directly — do not wrap with `Foo.toGrpc(...)` / `Foo.fromGrpc(...)` or hand-rolled match blocks at the call site.

Ownership of those implicits stays on the enum/companion (**`stl-arch-akka`** → `impl-enums-string-enum.md`). Do not invent mapper objects.

## When explicit conversion is still fine

- The conversion implicit is **not** in scope (missing mixin / import).
- The expression is ambiguous (multiple applicable conversions / overload).
- You need a **named method** for a non-conversion reason (e.g. parsing that can fail, or a helper that does more than `A => B`).

Otherwise prefer the implicit.

## Related

- Delegate shape: `delegate-coding-style.md` · Enum ownership: skill `stl-arch-akka` → `references/topics/impl-enums-string-enum.md`
