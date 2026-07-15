# Entity table constraints

Use when auditing or adding mutable `entity/*Table.scala` rows, evolutions, Processor writes, or Kafka projection writes.

## Required audit columns

Mutable entity tables must expose all four unless explicitly exempt:

| Scala field | DB column |
|-------------|-----------|
| `createdBy` | `created_by` |
| `createdAt` | `created_at` |
| `updatedBy` | `updated_by` |
| `updatedAt` | `updated_at` |

Apply the same shape in entity case classes, `def *`, `GetResult`, and `?` projections.

## Write rules

| Operation | `created*` | `updated*` |
|-----------|------------|------------|
| create / first `insertOrUpdate` | set from event/message | set from event/message |
| later update | preserve | set from event/message |

That rule applies to both aggregate `Processor` and Kafka projection consumers.

## Evolutions

When adding missing `created_*` to a table that already has `updated_*`:

1. add `created_by` and `created_at` as nullable
2. backfill from `updated_by` / `updated_at`
3. make them `NOT NULL`

Never edit already-applied evolution files. Add a new numbered evolution.

## Exemptions

| Table kind | Audit requirement |
|------------|-------------------|
| reference / lookup | none |
| append-only log | `createdAt` required, `createdBy` when known, no `updated*` |
| infrastructure tables | out of scope |

If a table has `updated*`, it is not append-only and must also have `created*`.

## Checklist

- [ ] every mutable entity has all four audit fields or a documented exemption
- [ ] DB columns exist and are `NOT NULL` after backfill
- [ ] Processor create paths set all four
- [ ] Processor update paths preserve `created*`
- [ ] Kafka consumer create paths set all four
- [ ] Kafka consumer update paths preserve `created*`
- [ ] no entity has `updated*` without `created*`

## Cross-references

- storage JSON / table models: `entity-table-json-types.md`
- internal vs table models: `internal-boundary-types.md`
- Kafka consumer rules: `kafka-projection-consumers.md`
