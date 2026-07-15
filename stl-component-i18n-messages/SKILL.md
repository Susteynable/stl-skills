---
name: stl-component-i18n-messages
description: >-
  Use when adding Stey Scala enum labels or system strings through
  stey-common-i18n-message resource files, wiring `HasI18nMessageApi`, or
  removing DB lookup tables used only for static catalog i18n text.
---

# Stey Component I18n Messages

## Purpose

Use deploy-time message resources for fixed labels and system strings, while keeping admin-configurable content in DB-backed `I18nText`.

## Workflow

1. Read `references/tracks/track-index.md` to classify scope.
2. Use `references/core-patterns.md` for storage decisions, message files, Scala resolution, API wiring, and DB catalog removal rules.
3. Run only the needed tracks in order and report verification results.
4. Use the parity script and assets for final checks or scaffolding.

## Guardrails

- `stey-common-i18n-message` must be present before code wiring changes.
- `ApplicationLoader` must load `I18nMessageApi` once.
- Use `rawMessageAt`, not `messageAt`, for fully qualified keys.
- Build multi-locale `I18nText` from `availableLanguages`.
- Enum list APIs keep `Unknown` out of the public list but still provide its fallback key.
- Every new locale file must define every key in `messages.en`.
- Do not move static enum labels into MySQL when message files are enough.
- Drop only catalog tables used solely for static i18n labels.

## Tracks

| Track | Focus |
|---|---|
| A | Scope and storage |
| B | Message resources |
| C | Scala code resolution |
| D | API wiring |
| E | DB catalog removal |
| F | Verification |

## Reference Index

| When you need... | Read |
|---|---|
| Track order | `references/tracks/track-index.md` |
| Storage, key rules, Scala patterns, API wiring, DB removal | `references/core-patterns.md` |
| Enum label pattern | `assets/enum-label-pattern.scala` |
| Message key block | `assets/message-key-block.properties` |
| Locale key parity check | `scripts/check_message_key_parity.py` |

## Activation Keywords

`I18nMessageApi`, `rawMessageAt`, `messages.en`, `messages.zh`, `I18nText.from`, `HasI18nMessageApi`, enum labels, lookup table removal`.
