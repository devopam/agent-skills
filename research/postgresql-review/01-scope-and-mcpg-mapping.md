# Scope, access mode, and MCPg mapping

**Retrieved:** 2026-09-07  
**Primary sources:** MCPg `docs/tools.md`, `docs/tour.md`, README capability gates; industry health-check / security practice (see Sources).

---

## In scope

- Live **review** of an existing PostgreSQL database (or one/more schemas).
- Scored findings across agreed domains (see `02-domain-baselines.md`).
- **Suggested** remediation (SQL text, ops steps). Skill does **not** apply DDL/DML unless a future explicit "apply" mode is designed and gated.
- **MCPg as required utility** for a full review — with an explicit **readiness phase** (install → configure → verify access to the target DB/schemas). Detail: [`03-mcpg-readiness.md`](03-mcpg-readiness.md).
- Degraded catalog/`pg_stat_*` path **only** after readiness failure **and** explicit user consent.

## Explicit non-scope (v0)

- Designing green-field schemas from product requirements (→ project-incubation / ADRs).
- Application ORM/code review (→ `python-code-review` or language-specific skills).
- CI/CD pipeline design for migrations (→ `ci-cd-plumber`).
- Running `pg_dump` / restore / unrestricted maintenance as part of the default review.
- Vendor-only features that require non-Postgres engines (except noting optional extensions when MCPg reports them).

---

## Phase 0 — MCPg readiness (required)

Before domain scoring, the skill **must**:

1. **Detect** whether MCPg tools are available to the agent.
2. If not: guide **install** (`pip` / `uv` / Docker) and **client MCP wiring** with `MCPG_DATABASE_URL` for the database under review and `MCPG_ACCESS_MODE=read-only` (recommended).
3. **Verify** reachability: smoke READ calls (`get_server_info` / `list_schemas`, and schema existence if scoped).
4. **Lock scope** (whole DB vs named schemas) against what the server actually sees.
5. Only then run health + advisors + domain review.

Full checklist, failure matrix, and multi-DB note: [`03-mcpg-readiness.md`](03-mcpg-readiness.md).

---

## Access mode: read-only is enough (not unrestricted)

### Decision

**Default MCPg mode for this skill: `MCPG_ACCESS_MODE=read-only` (or any mode that exposes the READ capability).**

**Do not require `unrestricted` for review.**

### Evidence (MCPg capability gates)

From MCPg `docs/tools.md` (2026-09-07):

| Capability | Default access mode | What it unlocks |
|------------|---------------------|-----------------|
| **READ** | every mode | catalog, query, search, **health, advisors**, ORM exporters, NL→SQL generate, cursors, AGE reads |
| WRITE | restricted / unrestricted | `run_write`, maintenance cancel/terminate, imports, … |
| DDL | unrestricted + `MCPG_ALLOW_DDL` | `run_ddl`, migrations complete, extension enable, … |
| SHELL | unrestricted + `MCPG_ALLOW_SHELL` | dump/restore, copy between DBs |

Health, tuning & advisors — including `check_database_health`, `audit_database`, `run_advisors`, `recommend_indexes`, `recommend_index_drops`, `analyze_workload`, `analyze_table_bloat`, `find_sensitive_columns`, `lint_naming_conventions`, `find_unused_objects`, `list_grants`, `list_policies`, `test_rls_for_role`, `audit_settings` — are documented under the **read** gate.

### Implications for the skill

1. Instruct the agent: **prefer read-only MCPg**; never ask the user to flip to unrestricted solely to "run a review."
2. Remediations are **emitted as suggestions** (e.g. `CREATE INDEX CONCURRENTLY …`, `REINDEX INDEX CONCURRENTLY …`). Execution requires a separate, explicit user request and a write-capable session — out of default skill flow.
3. If the user *already* runs unrestricted for other reasons, still only call READ tools during review unless they explicitly ask to apply a fix.

### When restricted/unrestricted *would* matter

Only if a future skill mode includes "apply approved fixes," seed data, or dump/restore. That is **not** v0.

---

## Scope selection UX

1. **Default:** whole database — iterate user schemas (exclude system schemas unless user asks).
2. **Narrow:** if user names schema(s) at invoke time, limit advisors/catalog tools to those schemas.
3. **Prompt once** when ambiguous: "Review the whole database, or a specific schema?"
4. Scope is validated during **readiness** against `list_schemas` (and tables if needed).

MCPg’s `audit_database(schema, …)` is schema-scoped; `check_database_health()` is instance-oriented. Skill should combine both: health once, then per-schema (or multi-schema) depth.

---

## Preferred MCPg tool map (v0)

### Readiness / smoke

| Intent | Tools |
|--------|--------|
| Server up | `get_server_info`, `describe_self` (if useful) |
| Catalog reachable | `list_schemas`, optional `list_tables` |
| Deeper smoke | `check_database_health` |

### Always / early (post-readiness)

| Intent | Tools |
|--------|--------|
| Instance health | `check_database_health` |
| Comprehensive scored pass | `audit_database` (per schema under review) |
| Server context | `get_server_info`, `list_extensions` |
| Schema inventory | `list_schemas`, `list_tables`, `get_compact_schema` |

### Domain deepening

| Domain | Primary MCPg tools |
|--------|-------------------|
| Schema integrity | `run_advisors`, `list_constraints`, `list_foreign_keys`, `list_partitions` |
| Indexing | `recommend_indexes`, `recommend_index_drops`, `list_indexes`, `find_unused_objects` |
| Workload & plans | `analyze_workload`, `detect_n_plus_one`, `explain_query` / `analyze_query_plan` / `why_is_this_slow` (when user supplies SQL) |
| Maintenance | `analyze_table_bloat`, `read_autovacuum_priority`, `audit_sequences` |
| Security & access | `list_roles`, `list_grants`, `list_policies`, `test_rls_for_role`, `find_sensitive_columns`, `verify_connection_encryption` |
| Settings | `audit_settings`, `recommend_postgres_conf` |
| Hygiene | `lint_naming_conventions`, `find_unused_objects` |
| Live pressure (optional) | `list_active_queries`, `list_locks`, `find_blocking_chains` |

### Optional / extension-aware (only if present)

pgvector / turboquant / pg_search / Timescale / AGE tools — fold into Indexing or a later "extensions" domain if installed; do not fail the review if absent.

---

## Fallback when MCPg is missing or unreachable

1. Complete readiness steps in [`03-mcpg-readiness.md`](03-mcpg-readiness.md).
2. If still blocked, **ask** whether to continue in degraded mode.
3. Degraded mode only with consent: same domain checklist via `pg_catalog` / `information_schema` / `pg_stat_*`, with reduced confidence and Not Implemented where advisors cannot run.
4. Never present a degraded run as a full MCPg-backed review.

---

## Sources

- MCPg `docs/tools.md` capability gates + tool index (READ vs WRITE/DDL/SHELL) — retrieved 2026-09-07  
- MCPg `docs/tour.md` ("Is this database healthy?", "Lint the schema?") — retrieved 2026-09-07  
- MCPg README install / quick start / env — retrieved 2026-09-07  

Target authored files after approval: `skills/postgresql-review/references/mcpg-tooling.md` (readiness + tool map, ~120–160 lines).
