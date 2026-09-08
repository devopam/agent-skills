# Research: Security & access

**Retrieved:** 2026-09-08
**Status:** authoring-ready — deepens `research/postgresql-review/02-domain-baselines.md`
section 6 with direct verification against PostgreSQL's own docs, named
EDB/Supabase sources, and MCPg's actual source (v0.8.2, `github.com/devopam/MCPg`).
Feeds `skills/postgresql-review/references/security-and-access.md`.

## Headline verification findings (read before the rest)

1. **FORCE ROW LEVEL SECURITY only closes the table-owner bypass — it does
   not touch superusers or BYPASSRLS roles.** PostgreSQL's row-security docs
   state this as two separate sentences, not one conditional: "Superusers
   and roles with the `BYPASSRLS` attribute always bypass the row security
   system when accessing a table. Table owners normally bypass row security
   as well, though a table owner can choose to be subject to row security
   with `ALTER TABLE ... FORCE ROW LEVEL SECURITY`." The word "always" for
   superuser/`BYPASSRLS` has no stated exception for `FORCE` anywhere in the
   docs — `FORCE` is documented purely as an opt-in for the *owner's own*
   queries to become subject to policy. The original thin doc's phrasing
   ("RLS without FORCE where owners bypass") is directionally right but
   under-specifies this — a reviewer who sees `FORCE` set might wrongly
   conclude RLS is now airtight when a superuser-run migration tool or a
   `BYPASSRLS` app role still walks straight through it. The deepened doc
   states both bypass paths side by side so `FORCE` isn't oversold.
2. **A bare `USING` clause on an `UPDATE`/`ALL` policy does *not* silently
   allow arbitrary writes — Postgres auto-inherits it as the `WITH CHECK`
   expression when `WITH CHECK` is omitted.** `CREATE POLICY`'s docs are
   explicit: "if no `WITH CHECK` expression is defined, then the `USING`
   expression will be used both to determine which rows are visible ...
   and which new rows will be allowed to be added." This refines the
   original baseline's flagged smell ("Policies missing WITH CHECK on
   writes") — the real exploit shape is narrower than "any policy without
   an explicit WITH CHECK is a hole." It only opens a gap when: (a) the
   policy is `INSERT`-only, where **only `WITH CHECK` exists as a clause at
   all** (there is no `USING` to fall back to, so an `INSERT` policy with no
   `WITH CHECK` — or `WITH CHECK (true)` — genuinely accepts any row
   content); or (b) an author sets an explicit but too-permissive
   `WITH CHECK` that diverges from the `USING` clause's intent (e.g.
   checking a session variable that a client can influence). The deepened
   doc states the auto-inherit rule precisely so reviewers check the right
   thing — the *value* of the effective check, not just whether the SQL
   keyword `WITH CHECK` literally appears.
3. **Views bypass RLS by default and are a real, separate footgun the
   original baseline doesn't name.** Confirmed via Supabase's official RLS
   docs: "Views bypass RLS by default because they are usually created with
   the `postgres` user." PostgreSQL 15+ added `ALTER VIEW ... SET
   (security_invoker = true)` to make a view re-check RLS as the querying
   role instead of the view owner. A convenience view built over a
   correctly-RLS-protected table can quietly republish every tenant's rows
   if this isn't set. Added as a distinct finding shape in the deepened doc.
4. **`GRANT ... TO PUBLIC` is confirmed to include roles created after the
   grant.** PostgreSQL's own GRANT docs: "The key word `PUBLIC` indicates
   that the privileges are to be granted to all roles, including those that
   might be created later. `PUBLIC` can be thought of as an implicitly
   defined group that always includes all roles." This is exactly what the
   baseline asserted, now verified rather than assumed.
5. **Several `PUBLIC` privileges exist automatically, with no explicit
   `GRANT` statement to find.** PostgreSQL's privileges docs (5.8): default
   privileges to `PUBLIC` are "`CONNECT` and `TEMPORARY` ... privileges for
   databases; `EXECUTE` privilege for functions and procedures; and `USAGE`
   privilege for languages and data types (including domains)." A reviewer
   scanning `list_grants` output (table-scoped, per MCPg's tool doc) can
   miss that any function/procedure — including one wrapping sensitive
   logic — is `EXECUTE`-able by every role unless explicitly `REVOKE`d.
   This is new content the thin original doc didn't cover; added as its own
   "what to look for" bullet with the boundary that MCPg's `list_grants`
   only surfaces table-level grants, not this automatic function-level
   default.
6. **PostgreSQL 15 changed the `public` schema's default privileges** —
   `CREATE` on schema `public` is no longer granted to `PUBLIC` by default;
   only the database owner gets it on newly created databases (confirmed
   via EDB's and Percona's PG15 write-ups; the mechanism itself, not a
   date-sensitive claim, so treated as reliable secondary confirmation
   rather than a primary-source quote). Databases restored/upgraded from
   pre-15 clusters keep the old permissive grant unless explicitly revoked
   — worth a finding when a reviewed database predates PG15.
7. **`test_rls_for_role`, `find_sensitive_columns`, and
   `verify_connection_encryption` are grounded directly in MCPg v0.8.2
   source** (`src/mcpg/rls.py`, `src/mcpg/advisors.py`,
   `src/mcpg/liveops.py`) rather than inferred from the abbreviated
   `docs/tools.md`, which only carries prose write-ups for a subset of
   tools and lists these three in the tool-index table only. Mechanics
   confirmed from source, not guessed:
   - `test_rls_for_role` reads `pg_class.relrowsecurity` and `pg_policy`
     (joined to `pg_roles`) for the *catalog* view of which policies apply,
     then runs the actual count + a bounded sample (`sample_size`, default
     25) inside `SET LOCAL ROLE "<role>"` wrapped in
     `BEGIN TRANSACTION READ ONLY` — so the numbers reflect what that role
     really sees, not a static policy read. Its own docstring flags the
     tell: when `rls_enabled` is `False`, "the role's superuser / bypassrls
     bit may have routed around RLS."
   - `find_sensitive_columns` is a **name-pattern + data-type regex
     heuristic**, not a data-content scan: it never samples row values.
     Patterns are grouped into seven categories (`credential`, `financial`,
     `contact`, `identifier`, `health`, `government_id`, `location`) each
     with a `high`/`medium`/`low` confidence, e.g. `password`/`passwd`/`pwd`
     and `secret`/`api_key`/`private_key` at `high` confidence for
     `credential`; `email`/`phone` at `medium` for `contact`; bare
     `full_name`/`gender` at `low`/`medium`. Two data-type rules also fire
     regardless of column name: `inet` (medium — "IP addresses are personal
     data under most privacy regimes") and `cidr` (low). The tool's own
     docstring states the honest framing to carry into the reference doc
     verbatim: "Designed as a SIGNAL for review, not a verdict: a column
     called `email_template_id` will match the email heuristic but isn't
     itself an email address."
   - `verify_connection_encryption` reads `pg_stat_ssl` filtered to
     `pid = pg_backend_pid()` for the caller's own connection (`ssl`,
     `version`, `cipher`, `bits`), plus an unfiltered cluster-wide tally
     (`count(*)` / `count(*) FILTER (WHERE ssl)`) — the tool's own docstring
     notes a non-superuser may only see its own row in `pg_stat_ssl`, so the
     cluster tally is "a lower bound under restricted privileges," not a
     complete picture, when the audit connection isn't a superuser.
8. **`audit_database`'s "Authentication & Password Hygiene" category**
   (mapped to this domain in `mcpg-tooling.md`) runs exactly two checks per
   `src/mcpg/audit.py` (`audit_authentication`), both reading `pg_authid`
   (superuser-only; degrades to a `WARNING` metric explaining the
   permission gap otherwise, not a hard failure):
   - **Role password expiration** — `rolvaliduntil` already past →
     `CRITICAL` (category score −25); expiring within a fixed **30-day**
     window (the tool's own comment: "30 mirrors what most rotation
     policies set their cron to" — an MCPg design choice, not a Postgres
     default) → `WARNING` (−10).
   - **MD5-hashed passwords** — `rolpassword LIKE 'md5%'` on any
     login-capable role → `WARNING` (−15), because "PG 19 deprecates MD5
     password hashes (still supported, but explicitly flagged for
     removal)"; suggested fix is `password_encryption = scram-sha-256`
     plus re-issuing each affected role's password.
   These are genuinely this domain's territory (owns the category per the
   existing `mcpg-tooling.md` mapping table) and are now stated with their
   real thresholds instead of paraphrased.

## Supporting detail

### RLS enable / force / bypass, precisely

- `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` turns on the requirement that
  every `SELECT`/`INSERT`/`UPDATE`/`DELETE` against the table pass a policy.
  With RLS enabled and **zero policies defined**, PostgreSQL's docs state
  the default is deny-all: "If no policy exists for the table, a
  default-deny policy is used, meaning that no rows are visible or can be
  modified." (A table with RLS *enabled* but *no policies* is not itself a
  hole — it's the opposite, total lockout for everyone except the bypass
  paths below. The actual hole is RLS **not enabled** on a table that needs
  it, or enabled with only a permissive policy that's too broad.)
- Bypass paths, exhaustively, per the docs: superuser, any role with
  `BYPASSRLS`, and the table owner (unless `FORCE ROW LEVEL SECURITY` is
  also set — and even then, only the owner's bypass closes; superuser and
  `BYPASSRLS` are unconditional).
- `pg_roles.rolbypassrls` (boolean) is the column to check per role;
  `NOBYPASSRLS` is the documented default, and "only superuser roles or
  roles with `BYPASSRLS`" may grant it to another role — so a `BYPASSRLS`
  app role had to be deliberately set by someone with elevated privilege,
  it can't happen by accident of inheritance alone.

### USING / WITH CHECK, by command

Per `CREATE POLICY`'s docs, applicability of each clause is command-specific,
not universal:

| Command | `USING` | `WITH CHECK` |
|---|---|---|
| `SELECT` | yes | not allowed |
| `DELETE` | yes | not allowed |
| `INSERT` | not allowed | yes (only clause available) |
| `UPDATE` | yes | yes (defaults to `USING`'s expression if omitted) |
| `ALL` | yes | yes (defaults to `USING`'s expression if omitted) |

The exploit shape worth flagging as a finding is therefore: an `INSERT`
policy with `WITH CHECK (true)` or no `WITH CHECK` at all (accepts any row
content); or an `UPDATE`/`ALL` policy whose *explicit* `WITH CHECK` is more
permissive than its `USING` (the auto-inherit safety net only applies when
`WITH CHECK` is *absent*, not when it's present but weak).

### Grants

- `GRANT ... TO PUBLIC` reaches every current and future role — treat any
  non-trivial privilege granted to `PUBLIC` on a table holding sensitive or
  tenant data as at least Important, Critical if the columns are
  `find_sensitive_columns`-flagged at `high` confidence.
- Automatic `PUBLIC` privileges needing no `GRANT` statement to exist:
  `CONNECT`+`TEMPORARY` on every database, `EXECUTE` on every function/
  procedure, `USAGE` on every language and data type/domain. `list_grants`
  is table-scoped (per MCPg's own tool doc: "Lists the privileges granted
  on a table"), so it will not surface an over-exposed `SECURITY DEFINER`
  function — that requires checking function privileges separately if the
  schema under review defines any.
- `public` schema `CREATE` privilege: revoked from `PUBLIC` by default as of
  PostgreSQL 15 (only the DB owner keeps it on freshly created databases);
  databases upgraded/restored from pre-15 clusters retain the old grant
  unless explicitly revoked.
- Application/service roles with `rolsuper`, unnecessary `rolcreatedb`, or
  unnecessary `rolcreaterole` are the same class of smell the baseline
  already named — `list_roles` surfaces all of these plus `rolreplication`
  and `rolconnlimit` directly.

### Connection encryption

- `pg_stat_ssl` columns, confirmed: `pid`, `ssl` (bool), `version`, `cipher`,
  `bits`, `client_dn`, `client_serial`, `issuer_dn` — the last three `NULL`
  unless a client certificate was presented.
- `sslmode` tiers, confirmed from `libpq` docs: `disable` and `allow` do not
  enforce encryption (`allow` tries plaintext first); `prefer` (the libpq
  client default) tries SSL first but falls back to plaintext on failure —
  none of these three guarantee an encrypted session ever gets established.
  `require` refuses a plaintext fallback but — read precisely — only
  verifies the server certificate the same way `verify-ca` would **if a
  root CA file happens to be present**; without one it encrypts but doesn't
  authenticate the server. `verify-ca` and `verify-full` both refuse
  plaintext and check the certificate chain; only `verify-full` additionally
  checks the hostname matches the certificate. For a finding: `sslmode`
  weaker than `verify-full` on a remote/production DSN is at least a Minor
  gap, Important if the connection crosses an untrusted network and the
  mode is `prefer`/`allow`/`disable`.

## Sources (retrieved 2026-09-08 unless noted)

- https://www.postgresql.org/docs/current/ddl-rowsecurity.html — row
  security enable/force/bypass mechanics, default-deny-with-no-policy
  behavior; primary source for finding #1
- https://www.postgresql.org/docs/current/sql-createpolicy.html — per-command
  `USING`/`WITH CHECK` applicability table and the auto-inherit rule; primary
  source for finding #2
- https://www.postgresql.org/docs/current/sql-createrole.html — `BYPASSRLS`/
  `NOBYPASSRLS` definition and who may grant it; `CREATEDB`/`CREATEROLE`
  definitions
- https://www.postgresql.org/docs/current/view-pg-roles.html — `pg_roles`
  column list (`rolsuper`, `rolbypassrls`, `rolcreatedb`, `rolcreaterole`,
  `rolcanlogin`, `rolreplication`, `rolconnlimit`, `rolvaliduntil`)
- https://www.postgresql.org/docs/current/sql-grant.html — `PUBLIC` scope
  ("all roles, including those that might be created later"); primary
  source for finding #4
- https://www.postgresql.org/docs/current/ddl-priv.html — automatic
  `PUBLIC` defaults (`CONNECT`/`TEMPORARY` on databases, `EXECUTE` on
  functions/procedures, `USAGE` on languages/types); primary source for
  finding #5
- https://www.postgresql.org/docs/current/monitoring-stats.html —
  `pg_stat_ssl` view column list and descriptions
- https://www.postgresql.org/docs/current/libpq-connect.html — `sslmode`
  tier-by-tier behavior (`disable`/`allow`/`prefer`/`require`/`verify-ca`/
  `verify-full`), including `require`'s conditional-on-CA-file verification
- https://www.enterprisedb.com/postgres-tutorials/how-implement-column-and-row-level-security-postgresql
  — EDB tutorial confirming table-owner + superuser `BYPASSRLS`-equivalent
  bypass in practice, and column-level `GRANT SELECT (col1, col2, ...)` as
  a compensating control for sensitive columns (with the caveat that
  existing whole-table `SELECT` access must be revoked first for a column
  grant to actually narrow anything)
- https://supabase.com/docs/guides/database/postgres/row-level-security —
  official Supabase docs confirming `USING`/`WITH CHECK` semantics per
  command, `service_role`'s `bypassrls` attribute, and the views-bypass-RLS-
  by-default footgun with the `security_invoker = true` (PG15+) fix;
  primary source for finding #3
- https://www.enterprisedb.com/blog/new-public-schema-permissions-postgresql-15
  and https://www.percona.com/blog/public-schema-security-upgrade-in-postgresql-15/
  — secondary confirmation of the PostgreSQL 15 `public` schema `CREATE`
  privilege change (finding #6); mechanism-level claim, not date-sensitive
- `gh api repos/devopam/MCPg/contents/docs/tools.md` — MCPg tool-index table
  confirming `list_roles`/`list_grants`/`list_policies` field-level detail
  and confirming `test_rls_for_role`/`find_sensitive_columns`/
  `verify_connection_encryption` are read-gated but only documented at
  index-table granularity, not full prose, in this doc
- `gh api repos/devopam/MCPg/contents/src/mcpg/rls.py` (v0.8.2) — full
  `test_rls_for_role` implementation: catalog read for `relrowsecurity` +
  applicable `pg_policy` rows, then `SET LOCAL ROLE` inside a read-only
  transaction for the actual visible-row count and a bounded sample
- `gh api repos/devopam/MCPg/contents/src/mcpg/advisors.py` (v0.8.2) —
  full `find_sensitive_columns` implementation: regex name-pattern table
  (7 categories, 3 confidence levels) plus `inet`/`cidr` type-based rules;
  confirmed the tool samples no row data, catalog-only
- `gh api repos/devopam/MCPg/contents/src/mcpg/liveops.py` (v0.8.2) — full
  `verify_connection_encryption` implementation: own-backend `pg_stat_ssl`
  row plus cluster-wide encrypted/unencrypted tally, with the
  non-superuser visibility caveat stated in its own docstring
- `gh api repos/devopam/MCPg/contents/src/mcpg/audit.py` (v0.8.2) — full
  `audit_authentication` implementation backing `audit_database`'s
  "Authentication & Password Hygiene" category: `pg_authid.rolvaliduntil`
  expiry scan (30-day warn window) and `pg_authid.rolpassword LIKE 'md5%'`
  scan, both degrading gracefully to a `WARNING` metric (not a hard error)
  when the connection role can't read `pg_authid`
- `gh api repos/devopam/MCPg --jq '.default_branch'` /
  `gh api repos/devopam/MCPg/releases --jq '.[0].tag_name'` — confirmed
  `main` is the default branch and `v0.8.2` is the latest tagged release,
  consistent with the `v0.8.x` citation already used in
  `skills/postgresql-review/references/mcpg-tooling.md`
