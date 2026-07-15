# CORS Exposed Headers

Use this when a Stey Play/Tapir service returns cross-origin file downloads and the client cannot read the filename from `Content-Disposition`.

## Symptom

The browser download works, but JS sees `response.headers["content-disposition"]` as missing even though DevTools shows the header.

## Fix

Add `Content-Disposition` to `play.filters.cors.exposedHeaders` before enabling `play.filters.cors.CORSFilter`:

```hocon
play {
  filters {
    cors {
      exposedHeaders = ["Content-Disposition"]
    }
    enabled += play.filters.cors.CORSFilter
  }
}
```

Canonical snippet: `assets/application-conf-cors-exposed-headers.conf`

## Verify

1. Trigger a cross-origin file download.
2. Confirm JS can read `response.headers["content-disposition"]`.
3. Confirm the response exposes `Access-Control-Expose-Headers: Content-Disposition`.
