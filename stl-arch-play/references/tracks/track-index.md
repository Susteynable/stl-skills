# Track Index

Use tracks as execution order, not as deep references.

| Track | File | Use for |
|---|---|---|
| A | `track-a-application-wiring.md` | Boot, Macwire, controller registration |
| B | `track-b-controller-dsl.md` | Controller structure, envelopes, endpoint logic, implicits converters/schemas |
| C | `track-c-auto-route-package-naming.md` | Package + endpoint val -> `.apiPath` |
| D | `track-d-request-response-naming.md` | DTO names and package colocation |
| E | `track-e-path-security-errors.md` | Security mode, manual-path exceptions, error handling |
| F | `track-f-cors-and-downloads.md` | Cross-origin downloads and `Content-Disposition` |

Run **A -> F** for full reviews. For URL migration, run **C -> D -> B**.
