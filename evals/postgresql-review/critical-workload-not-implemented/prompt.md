MCPg readiness passed for whole database (schema `public`). `check_database_health`
returns mostly ok. `audit_database` flags a role with `BYPASSRLS` on a
multi-tenant table that has RLS policies defined but not FORCE-enabled
(Critical: RLS bypass on sensitive tenant data). Separately, the
`pg_stat_statements` extension is not installed, so the workload tool
returns no data.
User: "Produce the full postgresql-review report."
