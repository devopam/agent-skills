# postgresql-review

Live PostgreSQL review after **MCPg readiness** (install, configure, verify
reachability for the target database and schemas).

**Use when:** auditing Postgres health, schema, indexes, workload, maintenance,
security, or hygiene — with [MCPg](https://github.com/devopam/MCPg) connected.

## Important constraints

- Prefer **`MCPG_ACCESS_MODE=read-only`** — review does not require unrestricted
- Remediations are **suggested SQL/ops only** (not applied by default)
- Degraded catalog/`pg_stat_*` mode only with **explicit** user consent

## Domains

Health & configuration, schema integrity, indexing, workload & query performance,
maintenance, security & access, hygiene & conventions.

## Canonical sources

- [SKILL.md](https://github.com/devopam/agent-skills/blob/main/skills/postgresql-review/SKILL.md)
- [references/](https://github.com/devopam/agent-skills/tree/main/skills/postgresql-review/references)
- [research/postgresql-review/](https://github.com/devopam/agent-skills/tree/main/research/postgresql-review)
- [evals/postgresql-review/](https://github.com/devopam/agent-skills/tree/main/evals/postgresql-review)
