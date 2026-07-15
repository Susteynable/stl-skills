# Copy-ready enum label pattern for stey-common-i18n-message.
# Replace EnumName, underlying field, and Unspecified sentinel as needed.
# See references/topics/scala-code-patterns.md

// On sealed trait:
def messageKey: String = s"EnumName.$underlying"

def name(implicit messageApi: I18nMessageApi): I18nText =
  I18nText.from(
    messageApi.availableLanguages.toSeq.sortBy(_.getLanguage).map { locale =>
      locale -> I18nMessageApi.rawMessageAt(messageKey, locale)
    }
  )

// On companion object:
def listable: Seq[EnumName] = all.filterNot(_ == Unspecified)

// In gRPC delegate:
implicit val messageApi = ctx.i18nMessageApi
EnumNames.listable.map { t =>
  Response.Info(value = t, name = Some(t.name))
}
