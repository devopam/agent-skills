# Schema integrity

## Intent

Structural soundness: keys, FKs, advisor rules — not product data modeling.

## MCPg tools

`run_advisors`, `list_constraints`, `list_foreign_keys`, `list_partitions`,
`summarize_table` for important tables; consume relevant `audit_database` categories.

## What to look for

- Tables without primary key / identity where maintenance and ORM patterns expect one
- Foreign keys without supporting indexes on the referencing side (especially hot paths)
- Duplicate constraints/indexes flagged by advisors
- `timestamp` without time zone on business columns (advisor)
- Partition anomalies at a high level

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Advisors clean on in-scope schemas |
| 7–8 | Few Important items, no Critical |
| 5–6 | Multiple missing PKs or unindexed FKs |
| 1–4 | Systemic integrity gaps on core tables |

## Evidence

Object identity (schema.table), advisor rule id/name if any, suggested SQL.

## Sources

pg-index-health-class findings; MCPg `run_advisors` — research 2026-09-07.
