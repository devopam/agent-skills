# Security & access

## Intent

Least-privilege smell tests on roles/grants, RLS posture on multi-tenant or
sensitive tables, sensitive-column heuristics, and connection-encryption
signals when observable through the connection under review. Not a full
host CIS benchmark, not network/firewall design, not secret rotation in an
external vault (mention only — this domain checks whether the database's
own grants/policies are sound, not which secrets manager a team should buy).

## MCPg tools

`list_roles`, `list_grants`, `list_policies`, `test_rls_for_role`,
`find_sensitive_columns`, `verify_connection_encryption`. Also owns the
`audit_database` **"Authentication & Password Hygiene"** category (role
password expiry, MD5 password-hash deprecation — see below); dedupe its
findings against these dedicated tools rather than double-counting.

- `list_roles` — role attributes: `superuser`, `create_role`, `create_db`,
  `can_login`, `replication`, `bypass_rls`, `connection_limit`,
  `member_of`. Pass `include_system=true` to also see PostgreSQL's own
  `pg_*` roles (usually noise for this review).
- `list_grants` — privileges on **one table** at a time (`grantee`,
  `privilege`, `grantable`, `grantor`). Table-scoped: it will not surface
  an over-exposed function or the database-level `CONNECT`/`TEMPORARY`
  defaults below — check those separately if the schema defines any
  security-sensitive functions (especially `SECURITY DEFINER`).
- `list_policies` — RLS policies on one table: `rls_enabled` (policies are
  inert while this is off — a table can have well-written policies that do
  nothing because RLS was never enabled) plus each policy's `command`,
  `permissive` flag, `roles`, and rendered `using`/`check` expressions.
- `test_rls_for_role` — the tool that actually answers "what does this role
  see," rather than reading policy text and hoping. It reads
  `pg_class.relrowsecurity` + the applicable `pg_policy` rows for context,
  then runs `SET LOCAL ROLE "<role>"` inside a read-only transaction and
  returns the real visible-row count plus a bounded sample (25 rows by
  default). If `rls_enabled` comes back `false`, or the row count looks
  like "everything," suspect the role has `BYPASSRLS` or is the table
  owner without `FORCE` set — confirm with `list_roles`.
- `find_sensitive_columns` — a **name-pattern and data-type heuristic**,
  not a data-content scan (it never samples values). Flags columns into
  seven categories — `credential`, `financial`, `contact`, `identifier`,
  `health`, `government_id`, `location` — each at `high`/`medium`/`low`
  confidence (e.g. `password`/`secret`/`api_key` at high confidence for
  `credential`; bare `email`/`phone` at medium for `contact`; `inet`-typed
  columns at medium for `location` regardless of name). Treat every hit as
  a **signal to go verify**, not a verdict — a column named
  `email_template_id` will match and isn't itself PII.
- `verify_connection_encryption` — reads `pg_stat_ssl` for the *current*
  backend (`ssl`, `version`, `cipher`, `bits`) plus a database-wide
  encrypted/unencrypted tally. If the audit connection isn't a superuser,
  the tally is a lower bound (non-superusers may only see their own row in
  `pg_stat_ssl`) — say so in the report rather than presenting it as exact.

## What to look for

**Roles & grants**

- Application/service roles with `superuser`, or unnecessary
  `create_role`/`create_db` for a role that only needs to read and write
  application tables.
- `GRANT ... TO PUBLIC` on a table holding sensitive or tenant data.
  `PUBLIC` is not "unauthenticated" — it is *every role in the database,
  including roles created after the grant* — so this is never a narrow
  exposure. Treat as Important by default, Critical if the table also has
  `find_sensitive_columns` hits at `high` confidence.
- Remember several `PUBLIC` privileges exist with **no `GRANT` statement to
  find**: `EXECUTE` on every function/procedure, `USAGE` on every language
  and data type/domain, `CONNECT`+`TEMPORARY` on every database. A
  sensitive `SECURITY DEFINER` function is `EXECUTE`-able by anyone unless
  someone explicitly `REVOKE`d the default — `list_grants` won't catch this
  since it's table-scoped.
- On databases that predate PostgreSQL 15 (or were restored from a pre-15
  cluster), the `public` schema's `CREATE` privilege may still be granted
  to `PUBLIC` — PG15 changed the default so only the database owner gets
  it on newly created databases. Worth a Minor-to-Important finding
  depending on what else lives unqualified in `public`.

**Row-level security**

- Multi-tenant or sensitive tables with RLS not enabled at all
  (`list_policies.rls_enabled = false`, or no policies exist). With RLS
  enabled and zero policies, PostgreSQL defaults to deny-all — that's a
  functional lockout, not a leak, but it usually means the feature was
  half-wired and needs finishing, not that it's safe as-is.
- **RLS enabled but not `FORCE`d, where the connecting application role
  is also the table owner** — a very common ORM/migration-tool pattern.
  Bypass here is not hypothetical: PostgreSQL's own docs state table
  owners "normally bypass row security," full stop, unless
  `ALTER TABLE ... FORCE ROW LEVEL SECURITY` is also set. This is the
  textbook Critical finding for this domain — RLS *looks* configured in
  `list_policies` output while every query the app actually runs walks
  straight past it. See the worked example below.
- Any role with `bypass_rls = true` (`list_roles`, `pg_roles.rolbypassrls`)
  that is also the application's normal connection role. Superusers and
  `BYPASSRLS` roles bypass RLS unconditionally — **`FORCE ROW LEVEL
  SECURITY` does not close this path**, it only removes the table-owner
  exemption. Don't let a `FORCE`d table read as "fully closed" if the app
  role also happens to carry `BYPASSRLS` or superuser.
- `INSERT`-only policies with `WITH CHECK (true)` or no `WITH CHECK` at
  all — for `INSERT`, `WITH CHECK` is the *only* clause a policy can carry
  (there's no `USING` to fall back on), so an absent or trivially-true
  check accepts any row content.
- For `UPDATE`/`ALL` policies: PostgreSQL auto-inherits `USING` as the
  effective `WITH CHECK` when `WITH CHECK` is omitted, so a bare `USING`
  clause here is *not* automatically a hole. The real smell is an
  **explicit** `WITH CHECK` that's more permissive than the `USING` clause
  it sits next to (e.g. checking a client-influenced session variable) —
  read both expressions from `list_policies`/`test_rls_for_role` rather
  than flagging on the mere absence of the keyword.
- Views built over an RLS-protected table: views are usually created by
  the table owner and **bypass RLS by default**, republishing an
  unprotected copy of a protected table. `ALTER VIEW ... SET
  (security_invoker = true)` (PostgreSQL 15+) makes the view re-check RLS
  as the querying role instead.
- Use `test_rls_for_role` as the actual app connection role whenever RLS
  posture is in question — don't take policy text at face value.

**Sensitive columns**

- Any `find_sensitive_columns` hit at `high` confidence with no
  compensating control noted (no RLS, no column-level grant narrowing, no
  encryption-at-rest/application-layer note). Column-level privilege
  (`GRANT SELECT (col1, col2) ON table TO role`) only actually narrows
  access if the role's whole-table `SELECT` grant is revoked first —
  flag a column grant that coexists with an unrevoked table-wide grant as
  ineffective, not as a real control.
- Report categories and confidence as MCPg returns them; don't silently
  upgrade a `low`-confidence name-only match to a headline finding without
  saying it's a heuristic.

**Connection encryption**

- `sslmode` weaker than `verify-full` on a remote/production DSN.
  `disable`/`allow`/`prefer` never guarantee an encrypted session (`prefer`
  — the client default — falls back to plaintext on any SSL failure).
  `require` refuses plaintext but only verifies the server certificate the
  way `verify-ca` would *if a CA file happens to be configured* — without
  one it's encrypted-but-unauthenticated. Only `verify-full` also checks
  the server hostname against the certificate.
- `verify_connection_encryption` reporting `ssl = false` for the audit's
  own backend, or an `unencrypted_connections` count greater than zero in
  the cluster-wide tally, on a connection that isn't purely local.

## Worked examples

**1. Critical — RLS enabled, not forced, app role owns the table.**
`list_policies` shows `rls_enabled = true` on `tenants.invoices` with a
sensible-looking policy (`USING (tenant_id = current_setting('app.tenant_id')::int)`).
But `list_roles` shows the application's connection role, `app_svc`, has no
`bypass_rls` flag — yet `test_rls_for_role(schema='tenants', table='invoices',
role='app_svc')` returns every tenant's rows, not just one. The cause:
`app_svc` is also the table's owner (a common `migrate-and-serve-as-one-role`
setup), and table owners bypass RLS by default. The policy is real and
correctly written — it simply never runs for the role that matters.
**Suggested remediation (not applied):**
```sql
ALTER TABLE tenants.invoices FORCE ROW LEVEL SECURITY;
```
Re-run `test_rls_for_role` afterward to confirm `app_svc` now sees only its
own tenant's rows. If `app_svc` also turns out to carry `bypass_rls = true`
or superuser, `FORCE` alone won't fix it — that flag has to be revoked
separately (`ALTER ROLE app_svc NOBYPASSRLS;`), since `FORCE` only removes
the table-owner exemption, not the `BYPASSRLS`/superuser one.

**2. Important — sensitive column with an ineffective compensating grant.**
`find_sensitive_columns` flags `customers.ssn` (`government_id`, high
confidence). `list_grants` shows `analytics_ro` was given
`GRANT SELECT (customer_id, region) ON customers TO analytics_ro` — looks
like a narrowing column grant — but also still holds a pre-existing
`GRANT SELECT ON customers TO analytics_ro` from before the column grant
was added. The table-wide grant supersedes the column-level one; `ssn`
remains fully readable by `analytics_ro`. **Suggested remediation (not
applied):**
```sql
REVOKE SELECT ON customers FROM analytics_ro;
GRANT SELECT (customer_id, region) ON customers TO analytics_ro;
```

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Grants are least-privilege; RLS enabled *and* forced everywhere the data model needs tenant isolation; no unaddressed high-confidence sensitive-column hits; connection encryption at `verify-ca`/`verify-full` or local-only |
| 7–8 | Minor grant hygiene issues (a stale `PUBLIC` grant on a low-sensitivity table, a column grant that isn't yet narrowed) but no live bypass path |
| 5–6 | RLS missing on tenant/sensitive tables, or enabled-but-not-forced with the app role owning the table (bypass exists but is at least contained to the owning role); sensitive columns flagged with no compensating control; `sslmode` at `prefer`/`allow` on a remote connection |
| 1–4 | `PUBLIC` or superuser-like app-role access to sensitive/tenant data; app connection role has `bypass_rls` or superuser (RLS is decorative); `INSERT` policy accepting any row content; `sslmode=disable` on a remote production connection |

## Sources

Verified 2026-09-08 against PostgreSQL's own docs (`ddl-rowsecurity.html`,
`sql-createpolicy.html`, `sql-createrole.html`, `view-pg-roles.html`,
`sql-grant.html`, `ddl-priv.html`, `monitoring-stats.html`,
`libpq-connect.html`); EDB's column/row-level-security tutorial; Supabase's
official RLS docs (USING/WITH CHECK semantics, views-bypass-RLS-by-default,
`security_invoker`); EDB/Percona coverage of PostgreSQL 15's `public`-schema
privilege change; and MCPg v0.8.2 source (`src/mcpg/rls.py`,
`src/mcpg/advisors.py`, `src/mcpg/liveops.py`, `src/mcpg/audit.py`) for the
actual behavior of `test_rls_for_role`, `find_sensitive_columns`,
`verify_connection_encryption`, and the `audit_database` "Authentication &
Password Hygiene" category. Full citation list and headline corrections:
`research/postgresql-review/security-and-access.md`.
