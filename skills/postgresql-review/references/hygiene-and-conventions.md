# Hygiene & conventions

## Intent

Naming outliers and unused clutter — low blast radius but real ops cost.

## MCPg tools

`lint_naming_conventions`, `find_unused_objects`.

## What to look for

- snake_case vs mixed naming outliers (project-dependent severity)
- Unused tables/indexes already partially covered under indexing — dedupe
- Noise objects in production schemas

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Clean conventions |
| 7–8 | Minor outliers |
| 5–6 | Widespread inconsistency or clutter |
| 1–4 | Rare for hygiene alone — reserve for extreme clutter |

Most hygiene findings are **Minor**.

## Sources

MCPg lint/unused tools — research 2026-09-07.
