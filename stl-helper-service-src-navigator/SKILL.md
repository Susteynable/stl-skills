---
name: stl-helper-service-src-navigator
description: >-
  Use when finding Stey service source locations across Stey, SteyApi,
  SteyConnect, or SteyWeb checkouts while keeping paths portable across
  different local roots.
---

# Stey Service Source Navigator

## Purpose

Resolve service names to `ANCHOR`-relative source locations without leaking machine-specific absolute paths.

## Workflow

1. Find `ANCHOR`: the first ancestor containing one or more of `Stey/`, `SteyApi/`, `SteyConnect/`, or `SteyWeb/`.
2. Normalize the user input and check `references/dictionary.md` first.
3. If no dictionary entry matches, discover real paths from the filesystem and strip the `ANCHOR` prefix.
4. Report with `assets/service-resolution-report.md`.
5. Update the dictionary only after a confirmed filesystem hit.

## Guardrails

- Never report absolute paths.
- Never invent a path that was not confirmed by the dictionary or filesystem.
- Use only the stable category labels `stey`, `stey-api`, `stey-connect`, `stey-web`, or `unknown`.
- Use forward slashes in reports.

## Reference Index

| When you need... | Read |
|---|---|
| Known service mappings | `references/dictionary.md` |
| Final response format | `assets/service-resolution-report.md` |

## Activation Keywords

`find stey service`, `SteyApi`, `SteyConnect`, `SteyWeb`, `service path`, `ANCHOR`, `relative path`.
