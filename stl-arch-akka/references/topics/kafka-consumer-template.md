# Kafka projection consumer template

Reference implementation shape (SteyConnectLlm-style).

## `ProtobufTypeUrl.scala`

```scala
package com.stey.connect.example.impl.projection.consumers

object ProtobufTypeUrl {
  def parse(typeUrl: String): Option[String] =
    typeUrl.split("/").toList match {
      case _ :: messageType :: Nil => Some(messageType)
      case _                       => None
    }
}
```

## `*EventConsumer.scala`

```scala
object ExampleEventConsumer {

  def start()(implicit system: ActorSystem[_]): Unit = {
    val topicName = com.stey.example.api.grpc.TopicNameProto.topicName
      .get(exampleevent.ExampleEventProto.scalaDescriptor.getOptions)
      .getOrElse(throw new RuntimeException("topic_name option missing in protobuf file"))

    AkkaProjection(system).startKafkaConsumer(
      topicName = topicName,
      numShards = 3,
      valueDeserializer = new ByteArrayDeserializer,
      handler = new ExampleEventConsumer()
    )
  }
}

class ExampleEventConsumer private ()(implicit system: ActorSystem[_])
    extends SlickHandler[ConsumerRecord[String, Array[Byte]]] {

  private implicit val ec: ExecutionContext = system.executionContext
  private val logger: Logger = LoggerFactory.getLogger(getClass)

  // local elementary implicits (UUID, BigDecimal, LocalDate) ...

  override def process(envelope: ConsumerRecord[String, Array[Byte]]): DBIO[Done] = {
    val payload      = ScalaPBAny.parseFrom(envelope.value)
    val typeUrl      = payload.typeUrl
    val messageBytes = payload.value.newCodedInput

    ProtobufTypeUrl.parse(typeUrl) match {
      case Some(messageType) if messageType == classOf[exampleevent.FooCreate].getName =>
        val message = exampleevent.FooCreate.parseFrom(messageBytes)
        for {
          _ <- ExampleProjectionRepository.rows.insertOrUpdate(
            ExampleProjectionEntity(
              fooId = message.fooId,
              createdBy = message.by,
              createdAt = message.getAt,
              updatedBy = message.by,
              updatedAt = message.getAt
            )
          )
        } yield Done

      case Some(messageType) =>
        logger.debug(s"skip event $messageType")
        DBIO.successful(Done)

      case None =>
        logger.debug("missing messageType")
        DBIO.successful(Done)
    }
  }
}
```

## Do not include

| Anti-pattern | Why |
|--------------|-----|
| `implicit apmManager: ApmManager` on consumer | APM belongs on gRPC/HTTP layer |
| `probe.captureThrowable` + `DBIO.successful(Done)` in `cleanUp` | Swallows failures; breaks retry |
| `.map(...).getOrElse(DBIO.successful(Done))` on parse | Use `match` with `Some` / `None` |
| Shared `impl.models` types on write path | Inline remap to entity (aggregate onion rules) |

## Example in repo

`SteyConnectLlm/stey-connect-llm-impl/src/main/scala/com/stey/connect/llm/impl/projection/consumers/`
