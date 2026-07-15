# `impl.enums` StringEnum template

Copy-paste starting point for a new enum kit. Rules and review checklist: `../topics/impl-enums-string-enum.md`.

Replace placeholders:

| Placeholder | Example |
|-------------|---------|
| `Foo` | `ReservationType` |
| `Foos` | `ReservationTypes` |
| `foo_bar` | `tenant`, `hotel_guest` |
| `GrpcFoo` | gRPC generated enum alias |
| `FOO_VARIANT_A` | `RESERVATION_TYPE_APARTMENT` |

## Shared traits (once per service)

File: `impl/enums/StringEnum.scala`

```scala
package com.stey.<svc>.impl.enums

import com.fasterxml.jackson.core.{JsonGenerator, JsonParser}
import com.fasterxml.jackson.databind._

trait StringEnum[E <: StringEnum[E]] extends Product with Serializable { self: E =>
  def underlying: String
  def widen: E = this
}

trait StringEnumCompanion[E <: StringEnum[E]] {
  def all: Seq[E]

  private def typeName: String = getClass.getSimpleName.stripSuffix("$")

  def fromValue(value: String): E =
    all.find(_.underlying.equalsIgnoreCase(value)).getOrElse(
      throw new IllegalArgumentException(s"failed to deserialize $typeName")
    )

  class JacksonSerializer extends JsonSerializer[E] {
    override def serialize(value: E, gen: JsonGenerator, serializers: SerializerProvider): Unit =
      gen.writeString(value.underlying)
  }

  class JacksonDeserializer extends JsonDeserializer[E] {
    override def deserialize(parser: JsonParser, context: DeserializationContext): E =
      fromValue(parser.getValueAsString)
  }

  class JsonKeySerializer extends JsonSerializer[E] {
    override def serialize(value: E, gen: JsonGenerator, serializers: SerializerProvider): Unit =
      gen.writeFieldName(value.underlying)
  }

  class JsonKeyDeserializer extends KeyDeserializer {
    override def deserializeKey(key: String, ctxt: DeserializationContext): AnyRef =
      fromValue(key)
  }
}
```

## Standard enum kit (root `impl.enums`)

File: `impl/enums/Foo.scala`

```scala
package com.stey.<svc>.impl.enums

import com.fasterxml.jackson.annotation.JsonValue
import com.fasterxml.jackson.databind.annotation.{JsonDeserialize, JsonSerialize}

@JsonSerialize(using = classOf[Foo.JacksonSerializer])
@JsonDeserialize(using = classOf[Foo.JacksonDeserializer])
sealed trait Foo extends StringEnum[Foo]

object Foo extends StringEnumCompanion[Foo] {
  def all: Seq[Foo] = Seq[Foo](Foos.VariantA, Foos.VariantB)

  class JacksonSerializer   extends super.JacksonSerializer
  class JacksonDeserializer extends super.JacksonDeserializer
  class JsonKeySerializer   extends super.JsonKeySerializer
  class JsonKeyDeserializer extends super.JsonKeyDeserializer

  import com.stey.<svc>.api.grpc.enums.{Foo => GrpcFoo}

  implicit def toGrpc(value: Foo): GrpcFoo = value match {
    case Foos.VariantA => GrpcFoo.FOO_VARIANT_A
    case Foos.VariantB => GrpcFoo.FOO_VARIANT_B
  }

  implicit def fromGrpc(value: GrpcFoo): Foo = value match {
    case GrpcFoo.FOO_VARIANT_A                           => Foos.VariantA
    case GrpcFoo.FOO_VARIANT_B                           => Foos.VariantB
    case GrpcFoo.Unrecognized(unrecognizedValue) => ???
  }

  implicit def columnMapper(implicit profile: slick.jdbc.JdbcProfile): slick.jdbc.JdbcType[Foo] = {
    import profile.api._
    MappedColumnType.base[Foo, String](
      v => v.underlying,
      v => Foo.fromValue(v)
    )
  }
}

object Foos {
  case object VariantA extends Foo { @JsonValue override def underlying: String = "foo_variant_a" }
  case object VariantB extends Foo { @JsonValue override def underlying: String = "foo_variant_b" }
}
```

## Subpackage enum (`impl.enums.steyfinance`, etc.)

Add parent import; otherwise identical shape.

```scala
package com.stey.<svc>.impl.enums.steyfinance

import com.stey.<svc>.impl.enums.{StringEnum, StringEnumCompanion}

import com.fasterxml.jackson.annotation.JsonValue
import com.fasterxml.jackson.databind.annotation.{JsonDeserialize, JsonSerialize}

// ... same Foo / Foos structure as above
```

## Many variants (`def all` multiline)

When `all` does not fit one line, keep it on `object Foo`:

```scala
object Foo extends StringEnumCompanion[Foo] {
  def all: Seq[Foo] = Seq[Foo](
    Foos.VariantA,
    Foos.VariantB,
    Foos.VariantC
  )
  // Jackson stubs, gRPC, columnMapper unchanged
}
```

## Backtick case object names

When the Scala identifier is not a valid bare name (e.g. `48H`), use backticks in **both** holder and `all`:

```scala
object Foo extends StringEnumCompanion[Foo] {
  def all: Seq[Foo] = Seq[Foo](Foos.`48H`, Foos.Anytime)
}

object Foos {
  case object `48H`   extends Foo { @JsonValue override def underlying: String = "48_h"    }
  case object Anytime extends Foo { @JsonValue override def underlying: String = "anytime" }
}
```

## Slick default column

`fromValue` is **not** implicit — pass an explicit case object (often `.widen`):

```scala
import Foos._
// table definition
fooType = O.Default(VariantA.widen)   // preferred
// not: O.Default(Foo.fromValue("foo_variant_a"))
```

## Enum coverage test (`MiscSpec`)

Register `Foo.all` on the **main companion**, not the holder:

```scala
scala.reflect.runtime.universe.typeOf[Foo].typeSymbol.asClass -> Foo.all
```

## New-file checklist

1. Create `Foo.scala` from the standard template.
2. Add every case object to `Foos` and to `Foo.all` (qualified with `Foos.`).
3. Wire `toGrpc` / `fromGrpc` with inline `match` on both sides.
4. Add four `extends super.Jackson*` stubs — do not remove them.
5. Add `columnMapper` on `object Foo` only.
6. Add `Foo` to `MiscSpec` enum coverage list with `Foo.all`.
7. If the enum is a JSON map key in state/tests, register `JsonKeySerializer` / `JsonKeyDeserializer` in the relevant `*JacksonSpec`.
