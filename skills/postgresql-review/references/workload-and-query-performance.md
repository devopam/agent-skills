# Workload & query performance

## Intent

Top consumers and pathological patterns — not rewriting application code.

## MCPg tools

`analyze_workload`, `detect_n_plus_one`, `list_active_queries`;
`why_is_this_slow` / `explain_query` / `analyze_query_plan` when user supplies SQL.

## What to look for

- Slow statements by total time / mean time (`pg_stat_statements` via workload tool)
- N+1 / repeated identical fingerprints
- Live blocking only as optional context (`list_locks`, `find_blocking_chains`)

## Limitation

If `pg_stat_statements` (or workload tool) unavailable: score with explicit
**Not Implemented** / reduced confidence; do not invent hot queries.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | No severe hotspots; or N/A documented with good health elsewhere |
| 7–8 | Moderate hotspots with clear index/plan suggestions |
| 5–6 | Clear N+1 or dominant sequential scans on large tables |
| 1–4 | Pathological load without mitigation path |

## Sources

MCPg tour workload tools; inspect-style checklists — research 2026-09-07.
