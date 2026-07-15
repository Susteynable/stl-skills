# Jackson sealed ADT template

Default to this pattern for aggregate Command, Event, State, and table JSON column ADTs.

## Required shape

```scala
import com.fasterxml.jackson.annotation.{JsonSubTypes, JsonTypeInfo}

// Aggregate Command / Event / State — value-only subtypes, no include/property/name:
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME)
@JsonSubTypes(Array(
  new JsonSubTypes.Type(value = classOf[Foo.Bar]),
  new JsonSubTypes.Type(value = classOf[Foo.Baz])
))
sealed trait Foo extends Product with Serializable

object Foo {
  final case class Bar(...) extends Foo
  final case class Baz(...) extends Foo
}

// Table storage ADT — _type discriminator + explicit subtype names:
// @JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.PROPERTY, property = "_type")
// @JsonSubTypes(Array(
//   new JsonSubTypes.Type(value = classOf[Foo.Bar], name = "bar"),
//   new JsonSubTypes.Type(value = classOf[Foo.Baz], name = "baz")
// ))
```

## Rules

- Put the discriminator and subtype registration on the parent trait.
- Keep variants plain case classes or case objects.
- **Command / Event / State:** `@JsonTypeInfo(use = NAME)` + `@JsonSubTypes` with `value = classOf[...]` only. Never `include`, `property = "_type"`, or `name =` on subtypes.
- **Table JSON columns:** `@JsonTypeInfo(..., include = As.PROPERTY, property = "_type")` + `@JsonSubTypes` with explicit `name =` for stable DB JSON.
- Keep the ADT on the owning tier only. If another tier needs the same conceptual shape, redefine and remap it there — never import or alias another tier's nested ADT.

## Case objects

If a case object needs custom deserialization, add a targeted nested singleton deserializer inside the case object itself to avoid illegal cyclic references:

```scala
@JsonDeserialize(using = classOf[NotApplicable.JacksonDeserializer])
final case object NotApplicable extends Foo {
  final class JacksonDeserializer extends JsonDeserializer[NotApplicable.type] {
    override def deserialize(parser: JsonParser, context: DeserializationContext): NotApplicable.type = NotApplicable
  }
}
```

SteyCrs uses this on both aggregate and table companions (see `../case-studies/jackson-serialization-stey-crs-refactor.md`).

## Colocated custom serializers (legacy replay)

When annotation-only Jackson is insufficient for journal replay, colocate `JacksonSerializer` / `JacksonDeserializer` on the same companion as the ADT. Read legacy payloads via JsonNode — do not fall back to spray. Move map-key codecs and other test registrations into `*JacksonSpec` files.

## Use custom Jackson only when

- annotation-only Jackson cannot express the wire shape
- replay compatibility requires a JsonNode bridge
- a legacy persisted payload forces custom reading

Do not reach for custom serializers before trying the parent-trait pattern above.

## Do not

- rely on `@JsonTypeName`-only discovery
- add aggregate spray formats to support the union
- share one sealed ADT across command, event, state, and storage tiers
- reference another event's nested ADT (e.g. `OtherEvent.SomeFormula`) instead of redefining on the owning companion
- add a centralized serialization package or cross-tier bridge objects
