---
name: stl-arch-play
description: >-
  Use when standardizing Stey Scala Play Tapir APIs: ApplicationLoader wiring,
  camelCase package auto-routes, endpoint-val DTO naming, envelopes, security,
  errors, and cross-origin file downloads.
---

# STL Arch Play

## Purpose

Keep Stey Play + Tapir APIs aligned with the ApplicationLoader/ApplicationComponents architecture used in SteyApiSystem, SteyApiWeb, and SteyApiConsole.

## Workflow

1. Scope the task: new endpoint, controller refactor, URL migration, or architecture review.
2. Read `references/tracks/track-index.md`; for path migrations start with **Track C** + **Track D**.
3. Classify the endpoint: `unsecured`, `secured`, or `user-aware`.
4. Apply the relevant track checklists and linked core references.
5. Preserve existing callback and response contracts unless the task explicitly changes them.
6. Verify `ApplicationComponents` wiring and compile/test behavior.

## Guardrails

- Prefer `apiEndpointBuilder.*Endpoint...apiPath...apiServerLogic`; avoid raw `endpoint` + `.serverLogic` unless the path/contract is intentionally custom.
- Prefer `ApiRequest[T]` / `ApiResponse[T]` envelopes for normal APIs.
- Multi-word route folders must be camelCase so `.apiPath` generates correct kebab-case URLs.
- DTO names follow the endpoint val in the same package: `create` -> `CreateRequest` / `CreateResponse`.
- Do not manually wrap business exceptions in endpoint logic; let the DSL / handlers map them.
- Do not add `Router.scala`, `resources/routes`, or Guice `Module` wiring for Tapir APIs.
- For cross-origin downloads, expose `Content-Disposition`; see Track F.

## Tracks

| Track | Focus |
|---|---|
| A | ApplicationLoader/ApplicationComponents wiring |
| B | Controller DSL pattern and endpoint structure |
| C | Package + endpoint val -> `.apiPath` URL |
| D | DTO naming from endpoint val |
| E | Security mode, path exceptions, and error handling |
| F | CORS and file downloads |

Run **A -> F** for full reviews. For URL migration, run **C -> D -> B**.

## Reference Index

| When you need... | Read |
|---|---|
| Track order and scope | `references/tracks/track-index.md` |
| Boot, wiring, DSL file map, error flow | `references/core-architecture.md` |
| Controller patterns and copyable endpoint skeletons | `references/controller-patterns.md` |
| Path/security/error rules only | `references/path-security-error-conventions.md` |
| Cross-origin file download header fix | `references/cors-exposed-headers.md` |

## Expected Outputs

- A mismatch list with exact files to update.
- Refactors for package paths, endpoint vals, DTO names, and controller wiring.
- Compile/test validation results and any explicit residual contract differences.

## Activation Keywords

`stl-arch-play`, `tapir play alignment`, `ApplicationLoader`, `ApplicationComponents`, `apiPath`, `auto route`, `camelCase package`, `endpoint val naming`, `CreateRequest`, `CreateResponse`, `CORS`, `Content-Disposition`.
