# gRPC surface delegate extraction

Use when `*ServiceImpl` should become a thin wiring shell. For a large case, see `../case-studies/grpc-surface-steycrs-case-study.md`.

## Goal

- one delegate object per RPC
- one shared `SurfaceContext`
- one `DelegateSupport`
- move logic verbatim first; refactor later

## Discover layout first

Derive these from the repo before naming or moving files:

1. impl module
2. surface package
3. existing delegates package, if any
4. bootstrap / macwire location
5. compile target

## Target shape

```text
surface/
  FooServiceImpl.scala
  delegate/
    Delegate.scala
    SurfaceContext.scala
    DelegateSupport.scala
    <service-slug>/
      BarBazDelegate.scala
```

## Rules

### Service impl

- wiring shell only
- build `ctx` once
- forward each RPC via `delegate(XxxDelegate)(in, metadata)`

### Delegates

- one file/object per RPC
- capability `C` matches actual body usage
- keep request-scoped values implicit or local
- do not type delegates as full `SurfaceContext` unless required
- helper methods, nested ADTs, and local type aliases are `private` to the delegate object (not `private[package]`)
- for multi-line response assembly in for-comprehensions, assign the value in the comprehension body then `yield` the binding; see skill `stl-convention` → `references/topics/delegate-coding-style.md`
- call `class *Internal` for write-path previews and orchestration; do not duplicate formula lookup or command logic in delegates

### SurfaceContext

- shared app-scoped deps only
- exposes `Has*` capability traits
- must not become implicit

### Error handling

- preserve existing `.recover` / `.transform`
- scope handlers per delegate
- do not centralize a large shared surface error handler during extraction

## Minimal types

```scala
trait HasDb { def db: Database }
trait HasFooInternal { def fooInternal: FooInternal }

final case class SurfaceContext(db: Database, fooInternal: FooInternal)
    extends HasDb
    with HasFooInternal

trait Delegate[I <: scalapb.GeneratedMessage, O <: scalapb.GeneratedMessage, -C] {
  def handle(ctx: C)(in: I, metadata: Metadata)(implicit system: ActorSystem[_], apmManager: ApmManager): Future[O]
}
```

## Workflow

1. list RPCs, line counts, and capabilities
2. scaffold `Delegate.scala`, `SurfaceContext.scala`, `DelegateSupport.scala` if absent
3. extract delegates in batches
4. slim the service impl to wiring only
5. compile after each batch

## Verify

```bash
sbt scalafmt
sbt scalafmtCheck
sbt "project <impl-module>" compile
```

Checks:

- delegate count equals RPC count
- no repeated per-dependency `.handle(db = ..., foo = ...)` wiring
- no unnecessary full-`SurfaceContext` delegates
- no business-logic rewrites slipped into the move

## Anti-patterns

- multiple RPCs in one delegate file
- passing every service dep into every delegate
- implicit `SurfaceContext`
- half-migrated service across multiple PRs
- shared error-handler package added in the extraction PR
- business-logic rewrites during the move
