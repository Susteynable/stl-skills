# Surface delegate coding style

Applies to read-path `surface/delegate/*` objects. Delegate extraction layout and capability typing: **`stl-arch-akka`** → `references/topics/grpc-surface-delegate-extraction.md`. This topic owns coding shape.

## Helper visibility

Keep helpers, nested ADTs, and local type aliases **`private` to the delegate object** — not package-scoped.

```scala
// Preferred
private type ApiAppCtx = HasDb with HasReservationInternal
private final case class BaseData(...)
private def loadBaseData(ctx: ApiAppCtx, ...): Future[BaseData] = ...

// Avoid
private[steycrsapiappservice] def loadBaseData(...)
private[steycrsapiconsoleservice] final case class BaseData(...)
```

Call helpers directly (`loadBaseData(...)`), not qualified with the delegate name (`CheckInRoomGetDelegate.loadBaseData(...)`).

## For-comprehension: assign, then yield

When a for-comprehension builds a multi-line response proto or non-trivial value, bind it in the body and yield the binding.

```scala
// Preferred
for {
  spaceTags <- ctx.db.run(qPagedSpaceTags.result)
  room = CheckInRoomRecommendResponse.Room(
    spaceId = Some(spaceId),
    spaceCode = Some(spaceCode),
    // ...
    spaceTags = spaceTags
  )
} yield room

// Avoid — large constructor after yield
for {
  spaceTags <- ctx.db.run(qPagedSpaceTags.result)
} yield CheckInRoomRecommendResponse.Room(spaceId = Some(spaceId), /* ... */)
```

Same for top-level RPC responses and loader results. **Exception:** Slick query comprehensions may keep inline tuple yields (`yield (colA, colB, ...)`).

## Write-path orchestration stays in `*Internal`

Delegates assemble reads. For preview calculations, command assembly, or domain-tied formula lookup, call **`class *Internal`** — do not reimplement in the delegate.

```scala
// Preferred
addonMap <- ctx.reservationInternal.reservationCalculatePaidUpgradePreview(
  projectId = projectId,
  reservationId = reservationId,
  targetRoomTypeIds = Seq(targetRoomTypeId),
  at = now
)
```

Trim unused delegate capability types when dependencies move to Internal.

## Related

- Slick: `../slick/core-conventions.md` · Naming: `var-and-method-naming.md` · Implicits: `implicit-conversions.md` · Inline remap: `stl-arch-akka` → `inline-boundary-remap.md`
