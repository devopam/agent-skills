# Health & configuration

## Intent

Instance-level health and dangerous/misaligned settings — not capacity planning.

## MCPg tools

`check_database_health`, `audit_settings`, `recommend_postgres_conf`,
`get_server_info`, `list_extensions`, `verify_connection_encryption`;
optional I/O/WAL readers when relevant.

## What to look for

- Connection / cache / dead-tuple / invalid-index / replication-lag signals from health
- Settings that undermine durability, logging, or autovacuum (from audit_settings / conf recommendations)
- TLS on the MCPg path when `verify_connection_encryption` is available
- Missing useful extensions called out only when they block other domains (e.g. no `pg_stat_statements` → workload limitation)

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Health clean; no Critical/Important config issues |
| 7–8 | Minor warnings only |
| 5–6 | Important health or settings issues |
| 1–4 | Critical health (e.g. wraparound proximity, invalid indexes widespread) |
| 0 | Unreachable after readiness (should not score in full mode) |

## Evidence

Each finding: severity, signal/source tool, why it matters, suggested action.

## Sources

MCPg health tools; industry healthcheck themes (vacuum, wraparound, slots) — `research/postgresql-review/02-domain-baselines.md`.
