# Research: Maintenance (vacuum, bloat, sequences)

Status: research pass complete      Date: 2026-09-08

Starting point: `skills/postgresql-review/references/maintenance.md` (31
lines, v0 — thin by design, per `research/postgresql-review/00-index.md`'s
own note to deepen from real research rather than "inventing thresholds from
memory alone"). No live MCPg session was available for this pass; the
substitute was direct verification against current PostgreSQL documentation,
MCPg's own source (`gh api repos/devopam/MCPg/contents/...`, matching the
technique already used for `mcpg-tooling.md`'s `audit_database` category
verification), and named industry guidance (AWS/Aurora).

## Headline verification findings (read before the rest)

1. **`autovacuum_vacuum_scale_factor` default is confirmed still `0.2` (20% of
   table size), `autovacuum_vacuum_threshold` default `50` rows** — verified
   directly against `postgresql.org/docs/current/runtime-config-autovacuum.html`.
   These are old, frequently-quoted numbers; worth stating that they were
   re-verified against current docs rather than assumed stable, because nothing
   here rules out a version bump changing them. A companion pair most
   discussions of vacuum tuning skip: **`autovacuum_vacuum_insert_threshold`
   (default `1000`) and `autovacuum_vacuum_insert_scale_factor` (default
   `0.2`)** — the PG13+ trigger for insert-only/append-heavy tables that never
   accumulate dead tuples but still need a vacuum pass for visibility-map
   maintenance and freezing. A table that's INSERT-only can look perfectly
   healthy on the dead-tuple signal alone and still be starved of vacuuming
   without this second threshold in view.
2. **`autovacuum_freeze_max_age` default confirmed `200,000,000` (200 million)
   transactions** — verified against the same page. This is the threshold
   that forces an anti-wraparound autovacuum (mandatory, ignores
   `autovacuum_enabled = off`, ignores the per-table opt-out) once a table's
   `relfrozenxid` age exceeds it. **Not previously stated anywhere in this
   skill's maintenance doc — this is new coverage, not a correction.**
3. **A second, distinct emergency threshold exists that the original thin
   doc had no coverage of at all: `vacuum_failsafe_age`, default
   `1,600,000,000` (1.6 billion) transactions** — verified against
   `postgresql.org/docs/current/runtime-config-vacuum.html`. This is
   VACUUM's last-resort failsafe: when a table's `relfrozenxid` age exceeds
   this (roughly 75% of the way to the 2³¹ hard wraparound limit), an
   in-progress vacuum drops its cost-based delay, skips non-essential index
   cleanup, and stops using a bounded buffer-access strategy — it races the
   wraparound clock rather than running politely in the background. This is
   the real mechanism behind "Postgres gets aggressive as wraparound
   approaches," and is more precise than a generic "aggressive vacuum"
   description.
4. **Postgres's own two hard-coded XID-wraparound warning stages are exact
   and quotable, not estimates**: at **40,000,000 transactions before the
   2³¹ limit**, every commit logs `WARNING: database "…" must be vacuumed
   within N transactions`; at **3,000,000 transactions before the limit**,
   the database stops accepting new write/DDL transactions entirely
   (`ERROR: database is not accepting commands that assign new transaction
   IDs…`) while read-only queries and `VACUUM` itself keep working — verified
   against the "Preventing Transaction ID Wraparound Failures" doc section.
   This is complementary to, not a duplicate of, Health & configuration's own
   framing (which — per MCPg's `audit_transactions_connections`, see below —
   uses `age(datfrozenxid)` against its own tool-chosen thresholds of 80M/150M
   to flag the *current proximity* as a health signal). Maintenance's angle is
   the *mechanism* — freeze/failsafe ages and what autovacuum does about
   them — not a restatement of Health's proximity check.
5. **`REINDEX CONCURRENTLY` confirmed introduced in PostgreSQL 12** (2019) —
   before that version, only a plain, blocking `REINDEX` existed. It takes a
   `ShareUpdateExclusiveLock` (blocks other DDL on the same relation, but not
   normal reads/writes), rebuilding the index from scratch in parallel with
   live traffic at the cost of a longer build time than a plain `REINDEX`.
   Confirmed via direct fetch and corroborating search results (Postgres 12
   release notes, PostgreSQL Wiki "Reindex concurrently" page).
6. **`VACUUM FULL` mechanism confirmed precisely**: it rewrites the entire
   table into a new file with no free space and *does* return the reclaimed
   space to the OS, but requires an `ACCESS EXCLUSIVE` lock for the duration
   — blocking all reads and writes on the table, not just other DDL. Plain
   `VACUUM` is the inverse on both axes: no exclusive lock (reads/writes
   continue), but reclaimed space is kept for reuse *within* the table rather
   than returned to the OS. This is why `VACUUM FULL` is unsafe as a casual
   production default and why the skill should keep suggesting
   `pg_repack`/`REINDEX CONCURRENTLY`-class approaches instead when bloat
   must be reclaimed live.
7. **`integer` vs `bigint` ranges confirmed exact**: `integer` is
   `-2147483648` to `2147483647` (≈2.1 billion); `bigint` is
   `-9223372036854775808` to `9223372036854775807` (≈9.2 quintillion) — per
   `datatype-numeric.html`. Matches the task's stated approximations exactly;
   no correction needed, just precision.
8. **No universal "how close to max" percentage is documented by Postgres
   itself for sequence exhaustion — genuinely workload-dependent, as the task
   anticipated.** But MCPg's own `audit_sequences` tool (in
   `src/mcpg/config_advisor.py`, §16.1 per its own roadmap numbering) *does*
   ship concrete, verifiable defaults: **`warning_pct=80.0`,
   `critical_pct=95.0`**, computed against `pg_sequences.last_value` versus
   the sequence's `max_value` (or `min_value` for a descending sequence —
   the tool is direction-aware, handling `increment_by < 0` deliberately per
   an inline code comment referencing a past review). This is the one
   concrete number this domain can cite without inventing anything: not a
   Postgres constant, but a named, sourced tool default, stated as such.
9. **MCPg's `audit_sequences` requires `pg_sequences`, which is PG 10+
   only** — on an older server it returns `available=False` with an explicit
   message rather than silently reporting nothing. Worth surfacing in the
   reference doc as a documented degraded-mode edge case, not a fabricated
   one — confirmed directly in source (`_has_pg_sequences`).
10. **MCPg's `analyze_table_bloat` runs two distinct modes**, confirmed from
    `src/mcpg/health.py`: a cheap **catalog estimate** by default
    (`relpages` against a size implied by `reltuples × (avg_width + 24) /
    (8192 − 24)` — the 24-byte figure is per-tuple header overhead, 8192 the
    page size), or a **precise mode** (`precise=True`) using the
    `pgstattuple`/`pgstatindex` extensions when installed, falling back
    silently to the estimate if the extension is absent. Table bloat and
    index bloat are reported separately — `IndexBloat.est_bloat_pct` in
    precise mode comes from `pgstatindex.avg_leaf_density` (100 minus that
    value), a different physical signal than the dead-tuple ratio the table
    side uses. This matches, and gives concrete backing to, the existing thin
    doc's line that "VACUUM does not fully fix index bloat."
11. **MCPg's `audit_database` "Table Cleanliness & Bloat" category (source:
    `src/mcpg/audit.py::audit_cleanliness_bloat`) uses a concrete, named
    threshold**: a table is flagged only once `n_dead_tup > 100` *and* its
    dead-tuple ratio (`n_dead_tup / (n_live_tup + n_dead_tup) × 100`) exceeds
    **10%** — any such table trips the category to `CRITICAL`. The same
    category's second check flags any `pg_index.indisvalid = false` row
    (invalid index) as `CRITICAL`, suggesting
    `REINDEX INDEX CONCURRENTLY` by name. Both are MCPg's own operational
    thresholds (not Postgres constants) — cited as such, not as universal
    law.
12. **MCPg's `read_autovacuum_priority` (`src/mcpg/autovacuum.py`) computes
    the *real* per-table Postgres trigger formula** —
    `autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor ×
    reltuples` — read live from `current_setting()` (so it reflects a
    customized cluster, not hardcoded defaults) and compares it against
    `n_dead_tup`. It buckets tables as `overdue` (ratio ≥ 1.0 — the literal
    line Postgres itself uses to decide autovacuum should already have run),
    `watchlist` (ratio ≥ 0.5 — MCPg's own earlier-warning heuristic, labeled
    as such in-source, not a Postgres constant), or `borderline`. It also
    surfaces `autovacuum_enabled = off` per-table opt-outs (via
    `pg_class.reloptions`) explicitly, so the agent doesn't recommend
    pushing on a table that's intentionally excluded.
13. **AWS Aurora's bloat-diagnostics page verified directly** (the source the
    original baseline named without having fetched it):
    `docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.diag-table-ind-bloat.html`.
    Concrete content beyond generic "bloat diagnostics": it recommends the
    `pgstattuple` extension (gated to the `pg_stat_scan_tables` role or
    superuser) for precise dead-tuple measurement, recommends testing
    `pg_repack` or `VACUUM FULL` against a **clone** before running either in
    production, documents the per-table `vacuum_index_cleanup` storage
    parameter (`AUTO`/`ON`/`OFF`) for controlling whether a `VACUUM` also
    cleans index bloat, and flags a genuinely separate bloat source this
    domain's tools don't otherwise surface: **autovacuum never touches
    temporary tables**, so an application that creates and drops temp tables
    without `ON COMMIT DELETE ROWS` can quietly bloat `pg_attribute` and
    `pg_depend` (system catalogs) over time.

## Supporting detail

- `n_live_tup` / `n_dead_tup` in `pg_stat_user_tables` (and
  `pg_stat_all_tables`) are documented as **estimates**, not exact counts —
  confirmed via `monitoring-stats.html`. Worth stating in any finding that
  cites them, so a reviewer doesn't over-claim precision from a signal
  Postgres itself labels approximate.
- The wraparound mechanism (freeze, anti-wraparound autovacuum, failsafe) is
  genuinely shared territory with Health & configuration, which owns the
  *current-proximity* signal via `age(datfrozenxid)` (MCPg's own
  `audit_transactions_connections` check, thresholds 80M WARNING / 150M
  CRITICAL, mapped to the Health & configuration domain per
  `mcpg-tooling.md`'s category table). This domain's reference doc states the
  underlying settings and mechanism (freeze_max_age, failsafe_age, the two
  hard warning stages) so a Maintenance-domain finding about vacuum debt can
  explain *why* wraparound risk accumulates, without re-deriving or
  duplicating Health's own scored proximity check.
- MCPg's `run_maintenance` (in `src/mcpg/maintenance.py`) is the **WRITE**-gated
  tool behind an actual `VACUUM`/`ANALYZE`/`VACUUM (ANALYZE)` — it requires
  `restricted`/`unrestricted` access mode and is explicitly out of this
  skill's default read-only flow. Confirmed present in source so the
  reference doc doesn't imply this skill could invoke it; suggested SQL
  stays textual only, consistent with the skill's "suggest, never apply"
  framing.

## Sources (retrieved 2026-09-08)

- <https://www.postgresql.org/docs/current/runtime-config-autovacuum.html> —
  `autovacuum_vacuum_threshold` (50), `autovacuum_vacuum_scale_factor` (0.2),
  `autovacuum_vacuum_insert_threshold` (1000),
  `autovacuum_vacuum_insert_scale_factor` (0.2),
  `autovacuum_freeze_max_age` (200,000,000),
  `autovacuum_multixact_freeze_max_age` (400,000,000), `autovacuum_naptime`
  (1min), `autovacuum_vacuum_cost_delay` (2ms).
- <https://www.postgresql.org/docs/current/routine-vacuuming.html> —
  "Preventing Transaction ID Wraparound Failures": freezing mechanism,
  `FrozenTransactionId`, the two hard warning stages (40M / 3M transactions
  before the limit) with exact log-message text, forced anti-wraparound
  autovacuum behavior, "do not use VACUUM FULL to recover" guidance.
- <https://www.postgresql.org/docs/current/runtime-config-vacuum.html> —
  `vacuum_failsafe_age` default (1,600,000,000) and failsafe behavior
  (drops cost-delay, skips index cleanup, disables bounded buffer strategy).
- <https://www.postgresql.org/docs/current/sql-vacuum.html> — `VACUUM FULL`'s
  `ACCESS EXCLUSIVE` lock and space-return-to-OS behavior versus plain
  `VACUUM`'s no-exclusive-lock, reuse-within-table behavior.
- <https://www.postgresql.org/docs/current/datatype-numeric.html> — exact
  `integer` (-2147483648..2147483647) and `bigint`
  (-9223372036854775808..9223372036854775807) ranges.
- <https://www.postgresql.org/docs/current/view-pg-sequences.html> —
  `pg_sequences` column list (`last_value`, `min_value`, `max_value`,
  `increment_by`, `start_value`, etc.) and `last_value` NULL conditions.
- <https://www.postgresql.org/docs/current/monitoring-stats.html> —
  `n_live_tup` / `n_dead_tup` exact descriptions ("estimated number of
  live/dead rows").
- <https://www.postgresql.org/docs/12/sql-reindex.html> and
  <https://paquier.xyz/postgresql-2/postgres-12-reindex-concurrently/> and
  the PostgreSQL Wiki "Reindex concurrently" page — `REINDEX CONCURRENTLY`
  introduced in PostgreSQL 12, `ShareUpdateExclusiveLock` behavior.
- <https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.diag-table-ind-bloat.html>
  — Aurora's own bloat-diagnostics guidance: `pgstattuple` usage and role
  gate, clone-then-`pg_repack`/`VACUUM FULL` testing pattern,
  `vacuum_index_cleanup` storage parameter, temp-table bloat caveat and
  `ON COMMIT DELETE ROWS` mitigation.
- `gh api repos/devopam/MCPg/contents/src/mcpg/autovacuum.py` — full source
  of `read_autovacuum_priority`: the live per-table threshold formula,
  `overdue`/`watchlist`/`borderline` bucket thresholds (1.0 / 0.5),
  `autovacuum_enabled` per-table opt-out detection.
- `gh api repos/devopam/MCPg/contents/src/mcpg/health.py` — full source of
  `analyze_table_bloat` (and the simpler `check_table_bloat` health check):
  estimate-vs-`pgstattuple` dual mode, the catalog-estimate formula, and the
  separate table/index bloat percentage signals.
- `gh api repos/devopam/MCPg/contents/src/mcpg/config_advisor.py` — full
  source of `audit_sequences` (§16.1 in MCPg's own roadmap numbering):
  `warning_pct=80.0` / `critical_pct=95.0` defaults, `pg_sequences`
  PG10+ requirement, direction-aware ascending/descending exhaustion math.
- `gh api repos/devopam/MCPg/contents/src/mcpg/audit.py` — full source of
  `audit_cleanliness_bloat` ("Table Cleanliness & Bloat" category: 10%
  dead-tuple-ratio / >100-row threshold, invalid-index check),
  `_audit_sequences_category` (folds `audit_sequences` into "Sequence
  Exhaustion"), and `audit_transactions_connections` (the `age(datfrozenxid)`
  80M/150M thresholds mapped to Health & configuration, confirming the
  domain boundary rather than duplicating it).
- `gh api repos/devopam/MCPg/contents/src/mcpg/maintenance.py` — full source
  of `run_maintenance`, confirming it is WRITE-gated and out of this skill's
  default read-only flow.
- `gh api repos/devopam/MCPg/contents/docs/tools.md` — tool index confirming
  `analyze_table_bloat`, `read_autovacuum_priority`, `audit_sequences` are
  all `read`-gated (available in every access mode, including `read-only`).
- `research/postgresql-review/02-domain-baselines.md` §5 (this repo) — the
  approved research baseline this file was authored from; retained as the
  provenance record for the decisions above.
