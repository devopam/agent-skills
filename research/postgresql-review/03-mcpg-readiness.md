# MCPg readiness (required precondition)

**Retrieved:** 2026-09-07  
**Sources:** MCPg README (install, quick start, env vars), `docs/installation.md` / integrations patterns, `docs/tools.md` READ tools for smoke checks.

This phase runs **before** any domain scorecard. Goal: MCPg is **installed**, **configured** for the target database, and **accessible** for the database and schema(s) in scope.

---

## Why required

A full `postgresql-review` depends on MCPg’s health, advisor, and catalog
tools (`check_database_health`, `audit_database`, `run_advisors`,
`recommend_indexes`, …). Without a working MCPg session pointed at the
right DSN, the skill cannot claim production-grade coverage.

---

## Readiness checklist (ordered)

### 1. Detect

- Are MCPg tools visible to the agent (e.g. `get_server_info`,
  `list_schemas`, `check_database_health`, `audit_database`)?
- If **yes** → go to **3. Verify access**.
- If **no** → go to **2. Install & wire**.

### 2. Install & wire (when not detected)

Guide the user (do not assume a host-specific installer UI):

| Step | Guidance |
|------|----------|
| Install | Preferred: `pip install mcpg` or `uv tool install mcpg` / `uvx mcpg`. Alternative: Docker image `ghcr.io/devopam/mcpg`. |
| Version | `mcpg --version` when CLI is available |
| Client config | Register MCPg in the agent’s MCP config (stdio or HTTP). Typical stdio: command `uvx` / `mcpg`, env `MCPG_DATABASE_URL`, optional `MCPG_ACCESS_MODE=read-only`. |
| DSN | `MCPG_DATABASE_URL=postgresql://…` for the **exact** database under review. Remote hosts should use TLS (`sslmode=require` or stronger) per MCPg defaults. |
| Access mode | **`read-only`** for review (see `01-scope-and-mcpg-mapping.md`). Do not require unrestricted. |
| HTTP (if used) | Auth required (`MCPG_HTTP_AUTH_TOKEN` or OIDC); point client at `/mcp`. |

Point at upstream docs rather than inventing installers:
[MCPg README](https://github.com/devopam/MCPg), installation + integrations guides.

After the user confirms config reload / reconnect, re-run **1. Detect**.

### 3. Verify access (smoke)

Call only **READ** tools. Suggested sequence:

1. `get_server_info` (or equivalent) — process up, version, mode signals if exposed.
2. `list_schemas` — catalog reachable; note user vs system schemas.
3. If user scoped to schema(s): confirm each appears (or fail readiness with a clear message).
4. Optional: `list_tables(schema=…)` for the primary schema; `check_database_health` as a deeper smoke (still readiness, not full scoring).

**Pass readiness** when: tools respond without auth/connection errors **and** the target DB (and named schemas, if any) are visible.

**Fail readiness** when: connection refused, auth failure, empty/wrong database, schema not found, or tools missing after install attempt.

### 4. Scope lock

Once reachable:

- **Whole DB (default):** plan iteration over non-system user schemas from `list_schemas`.
- **Named schema(s):** lock the list; do not silently expand to other schemas.

Record in the report header: MCPg version/server info if available, access mode if known, schema scope.

### 5. Only then — domain review

Proceed to health + `audit_database` + domain deepening per `02-domain-baselines.md`.

---

## Failure handling

| Situation | Skill behavior |
|-----------|----------------|
| MCPg not installed | Explain install options; stop domain review until ready **or** user opts into degraded mode |
| Installed but not in client MCP config | Provide config sketch (env + stdio/HTTP); ask user to reconnect |
| Wrong DSN / wrong database | Ask for corrected `MCPG_DATABASE_URL`; re-verify |
| Schema name invalid | List available schemas; re-prompt scope |
| User refuses to install MCPg | **Degraded mode** only with explicit consent: catalog/`pg_stat_*` SQL; mark overall confidence reduced and many advisor items Not Implemented |

Do not silently run a “full” scored review without MCPg and present it as equivalent.

---

## Multi-database note

If `MCPG_SECONDARY_DATABASE_URLS` is in play, readiness should clarify **which** database id is under review (`list_databases` when available) and lock that id for the session.

---

## Target authored artifact

After baseline approval: fold into `skills/postgresql-review/SKILL.md` (Phase 0 — Readiness) and `references/mcpg-tooling.md` (install + smoke commands + failure matrix).

**Eval cases (later):** readiness-fail-no-mcpg; readiness-pass-then-audit; wrong-schema-prompt.
