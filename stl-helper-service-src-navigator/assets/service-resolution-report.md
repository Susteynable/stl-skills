```markdown
Service: <input name>
Task track: <identify | dictionary | discovery | dictionary-update>
Category: <stey | stey-api | stey-connect | stey-web | unknown>
Primary path (ANCHOR-relative): <parent>/<repo>[/<module>]
Related modules (ANCHOR-relative):
- <parent>/<repo>/<module> - <why relevant>
Confidence: <high | medium | low>
Evidence: <dictionary entry | glob hit | package/build marker>
```

Do not include the absolute `ANCHOR` location in the report. Readers reconstruct it from their own checkout.
