# Kafka projection consumers

Use when the service has `projection/consumers/*EventConsumer.scala` Slick handlers. Skip for aggregate-only services that only have in-process `Processor`.

Template: `kafka-consumer-template.md`

## Goal

- lean handlers
- explicit event routing
- inline event -> entity remap
- failures propagate to Akka Projection for retry

## Workflow

1. Find consumers under `projection/consumers/`.
2. Apply the guardrails below.
3. Extract shared `ProtobufTypeUrl.parse` only if duplicated.
4. Align all consumers to the same `process` shape.
5. Verify with compile and tests.

## Guardrails

### No APM in consumers

- remove `ApmManager` / `ApmProbe` from consumer startup and handler classes
- keep APM on gRPC / HTTP entry points instead

### No error-swallowing `cleanUp`

Do not wrap DBIO failures in `cleanUp { ... DBIO.successful(Done) }`. Return the DBIO directly and let projection retry.

### Explicit type-URL routing

Use:

```scala
ProtobufTypeUrl.parse(typeUrl) match {
  case Some(messageType) if messageType == classOf[SomeEvent].getName => ...
  case Some(messageType) =>
    logger.debug(s"skip event $messageType")
    DBIO.successful(Done)
  case None =>
    logger.debug("missing messageType")
    DBIO.successful(Done)
}
```

Prefer `Some(...)` / `None` matching over chained `map` / `collect`.

### Shared helper

If duplicated, centralize:

```scala
object ProtobufTypeUrl {
  def parse(typeUrl: String): Option[String] =
    typeUrl.split("/").toList match {
      case _ :: messageType :: Nil => Some(messageType)
      case _                       => None
    }
}
```

Add `ProtobufTypeUrlSpec`.

### Audit columns

- create `insertOrUpdate`: set `createdBy`, `createdAt`, `updatedBy`, `updatedAt`
- partial update: preserve `created*`, change only `updated*`

See `entity-table-constraints.md`.

## Checklist

- [ ] consumer startup is lean and APM-free
- [ ] handler DBIO does not swallow errors
- [ ] type URL routing uses explicit match cases
- [ ] event -> entity remap is inline
- [ ] unknown events no-op with debug logging
- [ ] audit columns follow create/update rules
- [ ] type URL parsing has a unit spec
