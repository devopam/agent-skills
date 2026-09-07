# Indexing

## Intent

Lean, evidence-based indexes: add what helps; drop pure cost; never spray indexes.

## MCPg tools

`recommend_indexes`, `recommend_index_drops`, `list_indexes`,
`find_unused_objects`; feed with workload tools when available.

## What to look for

- Missing indexes for FK/filter patterns (prefer workload corroboration)
- Unused / rarely used large indexes (drop candidates with `CONCURRENTLY`)
- Duplicate/redundant indexes
- Invalid indexes (Critical/Important)
- Write/vacuum/WAL cost of index bloat on the set

## Do / don't

- **Do** prefer `CREATE INDEX CONCURRENTLY` / `DROP INDEX CONCURRENTLY` in suggestions.
- **Don't** recommend creating every heuristic index without size/workload context.
- **Don't** drop constraint-backed indexes.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Recommendations empty or only Minor |
| 7–8 | Small set of clear adds/drops |
| 5–6 | Many unused large indexes or clear missing hot-path indexes |
| 1–4 | Invalid indexes or severe redundancy on core tables |

## Sources

PostgresAI lean-index guidance; MCPg recommend/drop tools — research 2026-09-07.
