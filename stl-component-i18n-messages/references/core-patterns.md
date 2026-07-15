# Core Patterns

Use this as the canonical reference for Tracks A through F.

## Storage decision

Use message resources for:

- Enum labels
- System-generated fixed text
- Static catalog entries that do not need admin editing

Keep DB-backed `I18nText` for:

- Scenarios
- Templates
- Classifications or close reasons managed by admins or projects

## Message resource files

- `messages.en` is the parity baseline.
- Every additional locale file must define every key present in `messages.en`.
- Keep keys fully qualified and stable.

## Scala code patterns

- Resolve with `I18nMessageApi.rawMessageAt("Fully.Qualified.Key", lang)`.
- Do not use `messageAt` when the call site already provides the full key.
- For multi-locale gRPC fields, build `I18nText.from` from `messageApi.availableLanguages`.
- Enum list APIs usually omit `Unknown` from list results but still need the fallback message key.

## API wiring

- Bootstrap `I18nMessageApi` once in `ApplicationLoader`.
- Use `HasI18nMessageApi` where services or delegates need access.
- Keep message-loading concerns out of ad hoc utility code.

## DB catalog removal

- Remove lookup tables only when their sole job was static i18n labels.
- Keep per-entity relationship tables that carry real business links.
- Report code, schema, and data effects together when removing catalog storage.

## Verification

- Run locale parity checks.
- Verify enum or delegate output in at least one affected API path.
- Confirm no missing-key fallback strings appear at runtime.
