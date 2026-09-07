---
name: postgresql-review
description: Reviews a live PostgreSQL database across health, schema integrity, indexing, workload, maintenance, security, and hygiene — after verifying MCPg is installed, configured, and reachable for the target database (and optional schemas) — producing a scored domain report with severity-ordered findings and suggested (not applied) remediations. Use when auditing or health-checking Postgres, preparing for production, investigating performance or security posture, or when MCPg is available against a database under review.
---

# PostgreSQL Review

Structured review of a **live** PostgreSQL database. Full coverage requires
**[MCPg](https://github.com/devopam/MCPg)** (READ tools). Phase 0 verifies
MCPg is installed, configured for the target DSN, and can see the database
and schema(s) in scope. Domain scoring runs only after readiness passes, or
after the user **explicitly** accepts degraded non-MCPg mode.

Ask questions in plain text, one at a time. Prefer **read-only** MCPg
(`MCPG_ACCESS_MODE=read-only`). Never require unrestricted solely for review.
Emit remediation as **suggested SQL/ops** — do not apply DDL/DML unless the
user later makes an explicit apply request outside this default flow.

Research provenance: `research/postgresql-review/`.

## Phase 0 — MCPg readiness (required)

Follow [`references/mcpg-tooling.md`](references/mcpg-tooling.md).

1. **Detect** MCPg tools (`get_server_info`, `list_schemas`, `check_database_health`, `audit_database`, …).
2. If missing → guide **install** (`pip install mcpg` / `uv tool install mcpg` / Docker) and **client MCP config** with `MCPG_DATABASE_URL` for the exact database under review; recommend `MCPG_ACCESS_MODE=read-only`. Point at [MCPg](https://github.com/devopam/MCPg) docs. Re-detect after reconnect.
3. **Verify** with READ-only smokes: `get_server_info` → `list_schemas` → confirm named schemas if scoped → optional `list_tables` / `check_database_health`.
4. **Scope lock:**
   - Default: **whole database** (non-system user schemas from `list_schemas`).
   - If user named schema(s): lock that list; fail readiness if a name is missing (list available schemas and re-prompt).
5. Record in the report header: readiness status, server/MCPg signals if any, access mode if known, schema scope.

**Do not start domain scoring until readiness passes**, unless the user explicitly opts into **degraded mode** (catalog/`pg_stat_*` only, reduced confidence — see mcpg-tooling).

## Phase 1 — Intake (if still open)

- Whole DB vs schema list (if not already locked).
- Any focus (security-only, performance-only) — still run other domains lighter unless user insists on a single domain.
- Optional: specific slow SQL for `why_is_this_slow` / `explain_query`.

## Phase 2 — Review domains (in order)

Read each domain reference before scoring. Prefer MCPg tools listed there.
Map and **dedupe** findings from `audit_database` into these domains rather
than double-counting.

1. [Health & configuration](references/health-and-configuration.md)
2. [Schema integrity](references/schema-integrity.md)
3. [Indexing](references/indexing.md)
4. [Workload & query performance](references/workload-and-query-performance.md)
5. [Maintenance](references/maintenance.md)
6. [Security & access](references/security-and-access.md)
7. [Hygiene & conventions](references/hygiene-and-conventions.md)

### Severity

| Level | Meaning |
|-------|---------|
| Critical | Wraparound risk, open security hole, invalid indexes blocking ops, data-loss class issues |
| Important | Missing PK on real tables, unindexed hot FKs, severe bloat, RLS gaps on tenant/sensitive data |
| Minor | Naming, optional indexes, low-urgency hygiene |
| Not Implemented | Expected control absent (e.g. no `pg_stat_statements`, no RLS where multi-tenant is required) |

### Scoring & verdict

- Each domain: **0–10** (see domain Scoring Guide).
- Composite: average of scored domains (state if a domain was N/A).
- Per domain: Pass if ≥ 7 and no Critical; Needs attention if 5–6.9 or Important-only issues; Fail if < 5 or any Critical.
- Overall: **PASS** / **CONDITIONAL PASS** / **FAIL** (same spirit as `python-code-review`).

## Output (required)

1. **Header** — readiness, scope, mode (full MCPg vs degraded).
2. **Domain scorecard** — table of domain → score → Pass/Needs attention/Fail.
3. **Composite** average + overall verdict.
4. **Findings** ordered Critical → Important → Minor → Not Implemented (domain tag on each).
5. **Suggested remediations** — concrete SQL/ops; **not applied**.
6. Optional file from [`assets/report-template.md`](assets/report-template.md).

## Boundaries

- Not application code review (`python-code-review`).
- Not CI/CD design (`ci-cd-plumber`).
- Not green-field data modeling (`project-incubation`).
- Not dump/restore or unrestricted DBA firefighting unless user explicitly expands scope later.
