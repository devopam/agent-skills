# MCPg tooling & readiness

## Required for full review

MCPg exposes READ tools for health, advisors, indexes, security, and catalog.
Without a working session on the **target** database, do not claim full coverage.

Upstream: [github.com/devopam/MCPg](https://github.com/devopam/MCPg).

## Access mode

Use **`MCPG_ACCESS_MODE=read-only`** (default). Health, `audit_database`,
`run_advisors`, `recommend_indexes`, grants/RLS tools, etc. are **READ**.
Do **not** require unrestricted for review. Suggest DDL; do not run it in
default flow.

## Install (when tools missing)

| Method | Command / note |
|--------|----------------|
| pip | `pip install mcpg` |
| uv | `uv tool install mcpg` or run via `uvx mcpg` |
| Docker | `ghcr.io/devopam/mcpg` with `MCPG_DATABASE_URL` |

Verify CLI when available: `mcpg --version`.

## Client wiring

Register MCPg in the agent MCP config (stdio or HTTP).

Typical stdio env:

- `MCPG_DATABASE_URL=postgresql://user:pass@host:5432/dbname` (exact DB under review)
- `MCPG_ACCESS_MODE=read-only`
- Remote: prefer `sslmode=require` (or stronger) per MCPg TLS policy

HTTP: set transport + auth (`MCPG_HTTP_AUTH_TOKEN` or OIDC); client URL `…/mcp`.

After config change, user must reload/reconnect the MCP client; then re-detect tools.

## Smoke sequence (READ only)

1. `get_server_info` — process up
2. `list_schemas` — catalog works; separate user vs system schemas
3. Named schema scope → each name must appear
4. Optional: `list_tables(schema=…)`, `check_database_health`

**Pass:** no connection/auth errors; target DB and schemas visible.  
**Fail:** refused connection, auth error, wrong DB, missing schema, tools still absent.

## Multi-database

If secondaries are configured, use `list_databases` when available; lock the
database id under review for the session.

## Tool map (post-readiness)

| Intent | Tools |
|--------|--------|
| Health | `check_database_health` |
| Composite audit | `audit_database(schema=…)` per schema in scope |
| Advisors | `run_advisors` |
| Indexes | `recommend_indexes`, `recommend_index_drops`, `list_indexes` |
| Workload | `analyze_workload`, `detect_n_plus_one`, `why_is_this_slow` / `explain_query` |
| Maintenance | `analyze_table_bloat`, `read_autovacuum_priority`, `audit_sequences` |
| Security | `list_roles`, `list_grants`, `list_policies`, `test_rls_for_role`, `find_sensitive_columns`, `verify_connection_encryption` |
| Settings | `audit_settings`, `recommend_postgres_conf` |
| Hygiene | `lint_naming_conventions`, `find_unused_objects` |
| Inventory | `list_tables`, `get_compact_schema`, `list_extensions` |

## Degraded mode (explicit consent only)

If readiness cannot pass and the user consents: use `pg_catalog` /
`information_schema` / `pg_stat_*` (and `pg_stat_statements` if present).
Mark confidence reduced; many advisor-quality items **Not Implemented**.
Never label degraded output as a full MCPg review.

## Failure matrix

| Situation | Action |
|-----------|--------|
| Not installed | Install guidance; stop or degraded with consent |
| Not in MCP config | Config sketch; ask reconnect |
| Wrong DSN | Correct URL; re-smoke |
| Bad schema name | List schemas; re-prompt |
| User declines MCPg | Degraded only with consent |

## Sources

MCPg README, `docs/tools.md` capability gates, `docs/tour.md` — research window 2026-09-07; see `research/postgresql-review/`.
