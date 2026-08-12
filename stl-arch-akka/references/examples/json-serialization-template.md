# JsonSerialization template (application ObjectMapper)

Copy into `<svc>-impl/src/main/scala/com/stey/<svc>/impl/JsonSerialization.scala`. Canonical shape: SteyCms / SteyCrs.

**Do not** call `JacksonObjectMapperProvider` or add `registerAkkaJacksonModules` — Akka loads `CodeJacksonModule` / `I18nJacksonModule` / `SorterJacksonModule` from each `stey-common-*-jackson` jar's `reference.conf` (`akka.serialization.jackson.jackson-modules += …`).

Requires impl deps:

- `com.stey.common` %% `stey-common-code-jackson`
- `com.stey.common` %% `stey-common-i18n-jackson`
- `com.stey.common` %% `stey-common-sorter-jackson`

Prefer versions that ship `*JacksonModule` + `reference.conf` (SteyCms `test` baseline: code `2.0.8+`, i18n `2.2.9+`, sorter `2.0.6+`).

```scala
package com.stey.<svc>.impl

import com.fasterxml.jackson.databind.node.ObjectNode
import com.fasterxml.jackson.databind.{JsonNode, ObjectMapper}
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.scala.DefaultScalaModule
import com.stey.common.code.jackson.CodeJacksonModule
import com.stey.common.i18n.jackson.I18nJacksonModule
import com.stey.common.sorter.jackson.SorterJacksonModule

object JsonSerialization {

  /** Application / user-side ObjectMapper — not Akka's serializer.
    *
    * Intended for explicit, call-site JSON work over business data: table JSON columns (`toJsonString` / `fromJsonString`), audit / log payload shaping (`cleanupPayload`), and other manual transform helpers on this object.
    *
    * Contrast with Akka Jackson (`akka.serialization.jackson`, bound to `JsonSerializable` / `CborSerializable` in `application.conf`): that ObjectMapper is configured and owned by Akka for persistence and remoting (command / event / state / run ser/deser). Do not use
    * this mapper for those paths, and do not treat Akka's mapper as a general-purpose API for application JSON.
    *
    * Module overlap is intentional and limited to shared domain codecs (`CodeJacksonModule`, `I18nJacksonModule`, `SorterJacksonModule`, plus Scala / `JavaTime`). Same modules, separate ObjectMapper instances and separate lifecycles — keep configuration changes for one path
    * from silently affecting the other. This mapper registers the three modules explicitly; Akka loads them from each `stey-common-*-jackson` jar's `reference.conf` (`akka.serialization.jackson.jackson-modules`).
    */
  private lazy val objectMapper: ObjectMapper = new ObjectMapper()
    .registerModule(DefaultScalaModule)
    .registerModule(new JavaTimeModule)
    .registerModule(CodeJacksonModule)
    .registerModule(I18nJacksonModule)
    .registerModule(SorterJacksonModule)

  def toCompactString[T](value: T): String =
    toJson(value)

  def toJson[T](value: T): String =
    objectMapper.writeValueAsString(value)

  def fromJson[T](json: String, clazz: Class[T]): T =
    objectMapper.readValue(json, clazz)

  def treeToValue[T](node: JsonNode, clazz: Class[T]): T =
    objectMapper.treeToValue(node, clazz)

  def fromJsonString[T](json: String, clazz: Class[T]): T =
    objectMapper.readValue(json, clazz)

  def toJsonString[T](value: T): String =
    objectMapper.writeValueAsString(value)

  def cleanupPayload(value: Any, additional: Map[String, String] = Map.empty): String = {
    val node = toObjectNode(value)
    node.remove("at")
    node.remove("by")
    additional.foreach { case (key, v) => node.put(key, v) }
    objectMapper.writeValueAsString(node)
  }

  private def toObjectNode[T](value: T): ObjectNode =
    objectMapper.valueToTree(value)
}
```

## Optional overload

When call sites need Jackson `TypeReference` (e.g. `List[Foo]` / `Map[String, Bar]`):

```scala
import com.fasterxml.jackson.core.`type`.TypeReference

def fromJson[T](json: String, typeRef: TypeReference[T]): T =
  objectMapper.readValue(json, typeRef)
```

## Call-site rules

| Use | API |
|-----|-----|
| Table JSON columns | `toJsonString` / `fromJsonString` |
| Audit / log payloads | `cleanupPayload` |
| Setup journal re-seed dummy | `toCompactString(SetupDummyEvent(...))` |
| Command / Event / State / Run journal | Akka Jackson only (`JsonSerializable`) — not this object |

Do not expose a public `ObjectMapper` / `sharedMapper`. Prefer `JsonNodeFactory.instance.objectNode()` when building empty nodes outside this helper.

## Related

- Full rules: `../topics/aggregate-json-serialization.md`
- Track O checklist: `../tracks/track-o-aggregate-serialization.md`
