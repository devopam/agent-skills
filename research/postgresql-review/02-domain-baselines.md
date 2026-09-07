# Domain coverage baselines

**Retrieved:** 2026-09-07  
Each section is a **baseline** (in/out, evidence themes, MCPg hooks, target reference file). Authoring pass will deepen with concrete thresholds and worked examples — not copy this file into `references/` verbatim.

Severity model (align with other agent-skills scored skills):

| Level | Meaning (Postgres context) |
|-------|----------------------------|
| Critical | Data-loss / wraparound / open security hole / invalid indexes blocking ops |
| Important | Missing PK on real table, unindexed hot FK, severe bloat, RLS gaps on multi-tenant data |
| Minor | Naming, optional indexes, hygiene |
| Not Implemented | Expected control absent (e.g. no `pg_stat_statements`, no RLS where product requires tenants) |

Scoring: 0–10 per domain + composite average; overall PASS / CONDITIONAL PASS / FAIL analogous to `python-code-review`.

---

## 1. Health & configuration

**In:** connections/cache signals, dead tuples / invalid indexes, replication lag signals, dangerous settings posture, extension inventory relevant to ops.  
**Out:** full capacity planning, hardware sizing, non-Postgres layers (PgBouncer config files on disk unless exposed via settings).

**Industry themes:** healthcheck suites stress vacuum/bloat, TXID wraparound proximity, replication slots holding WAL, backup-related settings, cache hit behavior.

**MCPg:** `check_database_health`, `audit_settings`, `recommend_postgres_conf`, `get_server_info`, `list_extensions`, `verify_connection_encryption`, optional I/O/WAL readers.

**Target:** `references/health-and-configuration.md` (~100–150 lines)

---

## 2. Schema integrity

**In:** missing primary keys / unique constraints on tables that need identity; FK graph issues; advisor rules (nullable `timestamp` without time zone, etc.); partition sanity at a high level.  
**Out:** full data-model redesign, naming of every business entity.

**Industry themes:** tables without PKs block some maintenance tools (e.g. pg_repack); FKs without supporting indexes cause sequential scans on parent deletes/updates; static analyzers (e.g. pg-index-health class) codify these.

**MCPg:** `run_advisors`, `list_constraints`, `list_foreign_keys`, `list_partitions`, `summarize_table` for hot tables.

**Target:** `references/schema-integrity.md` (~100–140 lines)

---

## 3. Indexing

**In:** missing indexes suggested by workload/FK patterns; duplicate/redundant indexes; unused/rarely used indexes; invalid indexes; lean index set principle (write/vacuum/WAL cost).  
**Out:** blindly creating every recommended index; micro-optimizing without workload evidence.

**Industry themes:** unused indexes still cost writes, cache, vacuum, WAL; drop with care (`CONCURRENTLY`); not every FK needs an index (false positives exist — prefer evidence).

**MCPg:** `recommend_indexes`, `recommend_index_drops`, `list_indexes`, `find_unused_objects`, workload tools as input.

**Target:** `references/indexing.md` (~120–160 lines)

---

## 4. Workload & query performance

**In:** top consumers from `pg_stat_statements` when available; N+1 patterns; optional explain of user-supplied SQL.  
**Out:** rewriting application code; full query inventory of the app.

**Industry themes:** inspect seq scans, cache hit, slow statements; index advisor tied to real queries beats pure schema heuristics.

**MCPg:** `analyze_workload`, `detect_n_plus_one`, `why_is_this_slow` / `explain_query` / `analyze_query_plan` when SQL given; `list_active_queries` for live pressure.

**Fallback note:** without `pg_stat_statements`, domain scores with explicit limitation.

**Target:** `references/workload-and-query-performance.md` (~100–140 lines)

---

## 5. Maintenance (vacuum, bloat, sequences)

**In:** table/index bloat signals; autovacuum priority / overdue vacuum; sequence exhaustion risk; reminder that VACUUM does not fully fix index bloat (REINDEX).  
**Out:** scheduling enterprise backup products; running VACUUM FULL in production as default advice.

**Industry themes:** dead tuple %; wraparound; index bloat needs REINDEX CONCURRENTLY; autovacuum tuning is contextual.

**MCPg:** `analyze_table_bloat`, `read_autovacuum_priority`, `audit_sequences`, health check overlap.

**Target:** `references/maintenance.md` (~100–140 lines)

---

## 6. Security & access

**In:** role/grant least privilege smell tests; RLS enabled/forced where multi-tenant or sensitive; policy presence; sensitive column heuristics; TLS on the connection path when observable.  
**Out:** full CIS benchmark of the host OS; network firewall design; secret rotation in external vaults (mention only).

**Industry themes:** RLS footguns (owner bypass without FORCE; missing WITH CHECK; BYPASSRLS on app roles); grants vs RLS (both needed); column privileges for PII; test as the real app role.

**MCPg:** `list_roles`, `list_grants`, `list_policies`, `test_rls_for_role`, `find_sensitive_columns`, `verify_connection_encryption`.

**Target:** `references/security-and-access.md` (~120–160 lines)

---

## 7. Hygiene & conventions

**In:** naming outliers; unused objects; clutter that raises ops cost.  
**Out:** enforcing a single corporate naming standard without user context.

**MCPg:** `lint_naming_conventions`, `find_unused_objects`.

**Target:** `references/hygiene-and-conventions.md` (~60–90 lines)

---

## Cross-cutting report shape (for SKILL.md later)

1. Preconditions: MCPg present? access mode? schema scope?  
2. Run health + `audit_database` (or fallbacks).  
3. Walk domains; merge/dedupe findings.  
4. Scorecard table + severity-ordered list + suggested SQL (not applied).  
5. Optional saved report from template.

**Composite tool note:** MCPg `audit_database` already returns a multi-category scored report. Skill should **consume and map** those categories into the seven domains above rather than ignore them or double-count blindly — authoring pass must define the mapping explicitly.

---

## Sources (sampling, 2026-09-07)

- MCPg tour/tools: health, advisors, index recommend/drop, sensitive columns, RLS test  
- pg-healthcheck / postgres_dba style check groups (vacuum, indexes, locks, statements)  
- PostgresAI / community guidance on lean indexes and unused index cost  
- Aurora/AWS and general bloat diagnostics; commentary that VACUUM ≠ index rebuild  
- EDB / Supabase / security writeups on RLS, FORCE RLS, grants, WITH CHECK  

Full citation list to be carried into each authored `references/*.md` **Sources** section.

---

## Explicitly deferred (post-v0)

- Dedicated **extensions** domain (pgvector HNSW tuning, Timescale policies) as first-class scored domain  
- Apply-fixes mode  
- Continuous monitoring / alerting design  
- Multi-database (`MCPG_SECONDARY_DATABASE_URLS`) matrix reviews beyond "list and note"
