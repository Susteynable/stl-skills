# SteyCrs Case Study — Delegate Extraction

Optional reference for the pattern in [SKILL.md](../SKILL.md). Other Stey services follow the same architecture with project-specific packages and capability traits.

## Metrics

| Service | Before | After | Delegates |
|---------|-------:|------:|----------:|
| `SteyCrsApiConsoleServiceImpl` | ~4,200 lines | ~81 lines | 16 |
| `SteyCrsReservationServiceImpl` | ~3,631 lines | ~273 lines | 79 |

95 delegates total; capability-typed `SurfaceContext` + `DelegateSupport`.

## Layout (SteyCrs)

```
stey-crs-impl/src/main/scala/com/stey/crs/impl/surface/
  SteyCrs*ServiceImpl.scala
  delegate/
    Delegate.scala
    SurfaceContext.scala
    DelegateSupport.scala
    steycrs<name>service/*.scala
```

Package: `com.stey.crs.impl.surface.delegate` (+ per-service subpackage).

Subpackage slug: `SteyCrs{Name}ServiceImpl` → `steycrs{name}service` (e.g. `ApiConsole` → `steycrsapiconsoleservice`).

## SteyCrs capability traits

```scala
trait HasDb
trait HasManticoresearch
trait HasInventoryInternal
trait HasReservationInternal
trait HasTemplateEngine
```

## Capability profile counts (post-refactor)

| Capability `C` | Count | Examples |
|----------------|------:|----------|
| `HasReservationInternal` | 57 | `ReservationTagSetDelegate` |
| `HasDb` | 30 | `ReservationGetDelegate` |
| `HasDb with HasReservationInternal` | 5 | `ReservationGroupSetDelegate` |
| `HasDb with HasManticoresearch` | 1 | `ReservationSearchDelegate` |
| `HasDb with HasReservationInternal with HasInventoryInternal` | 1 | `ReservationRoomRecommendDelegate` |
| `HasTemplateEngine` | 1 | `ReservationRegistrationFormGetDelegate` |

## Error-handler profiles (reservation extraction script)

| Profile | Use |
|---------|-----|
| `plain_ok` | read-only / simple commands |
| `rate_plan` | rate plan validation exceptions |
| `room_assign_note` | room assign note illegal |
| `scheduled_check_in_full` | scheduled check-in domain |
| `inventory_reserve_failed` | inventory reserve + rerent recover |

## Docs and scripts (SteyCrs repo)

```
scripts/extract_reservation_delegates.py
docs/superpowers/specs/2026-06-17-*-delegate*.md
docs/superpowers/plans/2026-06-17-*-delegate*.md
```

## Typical commits (SteyCrs)

### Delegate extraction

1. `refactor: extract <service> delegates`
2. `refactor: slim SteyCrs<Name>ServiceImpl to delegate wiring only`
3. `refactor: introduce capability-typed SurfaceContext for delegates`
4. `chore: scalafmt ...`

### Jackson, tier decoupling, and inline remap (2026-06)

See `jackson-serialization-stey-crs-refactor.md` for the full series. Representative commits:

1. `refactor: convert polymorphic aggregate state and event ADTs to annotation-based Jackson serialization`
2. `refactor: eliminate cross-event ADT references for ReservationAddonItemAddEvent and ReservationAddonItemUpdateEvent in Event.scala`
3. `refactor: inline cross-layer ADT remaps and remove shared gRPC converters`
4. `refactor: make table ADTs spray-only and enforce serializer-free internal tier` → superseded by full Jackson standardisation
5. `refactor: remove legacy spray-json support from stey-crs-impl and standardise on Jackson`
6. `Remove bulk setup commands and colocate setup ADTs on Add events.`
