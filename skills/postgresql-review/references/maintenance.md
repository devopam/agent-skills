# Maintenance (vacuum, bloat, sequences)

## Intent

Bloat, autovacuum pressure, sequence risk. VACUUM does not fully fix **index** bloat — prefer `REINDEX … CONCURRENTLY` when appropriate.

## MCPg tools

`analyze_table_bloat`, `read_autovacuum_priority`, `audit_sequences`;
overlap with `check_database_health`.

## What to look for

- High dead-tuple ratio / overdue vacuum
- Table and index bloat estimates
- Sequence near exhaustion
- Avoid defaulting to `VACUUM FULL` in production suggestions

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | No significant bloat or vacuum debt |
| 7–8 | Manageable debt, clear priority list |
| 5–6 | Severe bloat on important relations |
| 1–4 | Wraparound-class risk or sequences critical |

## Sources

Bloat diagnostics literature; MCPg maintenance tools — research 2026-09-07.
