# Maintenance (vacuum, bloat, sequences)

## Intent

Bloat, autovacuum pressure, and sequence exhaustion — the three classes of
maintenance debt that stay silent until they aren't. This domain owns the
*mechanism*: why dead tuples accumulate, why an index doesn't shrink the way
a table does, and how close a sequence is to running out. It does **not**
own the current transaction-ID-wraparound proximity check
(`age(datfrozenxid)` against a cluster) — that live signal belongs to
[Health & configuration](health-and-configuration.md) via
`audit_database`'s "Transaction & Connection Health" category. This domain's
angle on wraparound is the vacuum machinery that prevents it in the first
place (freeze thresholds, the emergency failsafe) — complementary framing,
not a restatement of Health's own check.

## MCPg tools

| Tool | What it returns |
|---|---|
| `analyze_table_bloat(schema, precise=False)` | Per-table and per-index bloat estimates. Default mode is a cheap catalog estimate (`relpages` vs. a size implied by row count and average width); `precise=True` switches to the `pgstattuple`/`pgstatindex` extensions when installed, falling back silently to the estimate if absent. Table and index bloat are reported as **separate** signals. |
| `read_autovacuum_priority(limit=25)` | Tables ranked by how overdue they are for autovacuum, computed from the real per-table trigger formula (see below), read live from `current_setting()` so it reflects a customized cluster. Flags per-table `autovacuum_enabled = off` opt-outs explicitly. |
| `audit_sequences(warning_pct=80.0, critical_pct=95.0)` | Every sequence's consumption against its ceiling, direction-aware (ascending sequences exhaust toward `max_value`, descending toward `min_value`). Requires `pg_sequences` (PostgreSQL 10+); on an older server it reports unavailable rather than silently returning nothing. |

Overlap with `check_database_health` / `audit_database`: the composite audit
folds two categories into this domain — **"Table Cleanliness & Bloat"**
(dead-tuple ratio + invalid-index count) and **"Sequence Exhaustion"** (the
same `audit_sequences` logic, scored). Dedupe against the dedicated tools
above rather than double-counting the same underlying finding.

The gated `run_maintenance` tool (actual `VACUUM`/`ANALYZE`) needs
`restricted`/`unrestricted` access and is out of this skill's default
read-only flow — this domain only ever suggests the SQL, never runs it.

## What to look for

### Dead-tuple pressure and autovacuum debt

The core per-table Postgres trigger is:

```
vacuum_threshold = autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor × reltuples
```

Current defaults: `autovacuum_vacuum_threshold = 50` rows,
`autovacuum_vacuum_scale_factor = 0.2` (20% of the table). A table crosses
autovacuum's own trigger once `n_dead_tup` (from `pg_stat_user_tables`,
itself an **estimate**, not an exact count) exceeds that threshold —
`read_autovacuum_priority` calls this ratio ≥ 1.0 `overdue`; ≥ 0.5 is its own
earlier `watchlist` heuristic (not a Postgres constant). A separate,
easy-to-miss pair covers insert-only tables that never accumulate dead
tuples but still need a vacuum pass for freezing and visibility-map upkeep:
`autovacuum_vacuum_insert_threshold` (default `1000`) and
`autovacuum_vacuum_insert_scale_factor` (default `0.2`). A busy append-only
ingestion table can look perfectly clean on the dead-tuple signal alone and
still be maintenance-starved without checking insert-driven triggering too.

MCPg's own `audit_database` "Table Cleanliness & Bloat" category uses a
concrete (tool-chosen, not a Postgres constant) threshold: a table with more
than 100 dead tuples *and* a dead-tuple ratio above **10%** trips the
category to CRITICAL, suggesting `VACUUM ANALYZE` and autovacuum
scale-factor tuning.

**Worked example.** `read_autovacuum_priority` returns
`orders` at `n_dead_tup=480,000`, `n_live_tup=520,000`, `reltuples≈1,000,000`,
`vacuum_threshold≈200,050` (50 + 0.2×1,000,000), `dead_tuple_ratio≈2.4`,
`priority=overdue`, `last_autovacuum` several days stale. That ratio well
above 1.0 means autovacuum should already have run multiple times over and
isn't keeping up — likely cost-limited or contending with a long-running
transaction holding back the xmin horizon. Suggested remediation (never
applied): run `VACUUM (ANALYZE) orders;` manually during a low-traffic
window, and if the table's churn is structurally high, lower its
per-table `autovacuum_vacuum_scale_factor` via `ALTER TABLE orders SET
(autovacuum_vacuum_scale_factor = 0.05)` rather than relying on the
cluster-wide default.

### Table bloat vs. index bloat — different signals, different fixes

Plain `VACUUM` reclaims a table's dead-tuple space **for reuse within that
table** — it does not return the space to the OS, and critically, it does
not shrink an already-bloated B-tree index the same way. Index bloat
(fragmented, sparsely-filled leaf pages from repeated updates/deletes) is a
physically different problem: `analyze_table_bloat`'s precise mode measures
it via `pgstatindex.avg_leaf_density` — bloat is `100 − avg_leaf_density` —
a leaf-page-fill signal, not a dead-tuple count. The fix for index bloat
specifically is `REINDEX … CONCURRENTLY` (introduced in **PostgreSQL 12**),
which rebuilds the index from scratch under a `ShareUpdateExclusiveLock` —
blocking concurrent DDL on the relation, but not ordinary reads or writes —
at the cost of a longer build than a plain `REINDEX`.

`VACUUM FULL` is the wrong default to suggest here or anywhere in
production: it rewrites the *entire table* into a new file and takes an
`ACCESS EXCLUSIVE` lock for the duration — blocking all reads and writes,
not just DDL — in exchange for actually returning space to the OS. Keep
suggestions to `REINDEX CONCURRENTLY` for index bloat and, where table-level
space reclamation is genuinely needed without downtime,
`pg_repack`-class tooling — never `VACUUM FULL` as a casual recommendation.

A bloat source outside the usual dead-tuple/index lens: **autovacuum never
processes temporary tables.** An application that creates and drops temp
tables per-session without `ON COMMIT DELETE ROWS` can quietly bloat the
`pg_attribute`/`pg_depend` system catalogs over time — a finding worth
raising even when every user table looks clean.

### Wraparound — the mechanism this domain owns

Postgres freezes old rows (marking them with the special always-oldest
`FrozenTransactionId`) so a table's oldest live XID never actually reaches
the 2³¹ wraparound limit. Three concrete thresholds govern this:

- **`autovacuum_freeze_max_age`** (default `200,000,000` transactions) — once
  a table's `relfrozenxid` age exceeds this, Postgres **forces** an
  anti-wraparound autovacuum on it, ignoring `autovacuum_enabled = off` and
  any per-table opt-out.
- **`vacuum_failsafe_age`** (default `1,600,000,000` transactions, roughly
  75% of the way to the hard limit) — VACUUM's last resort: an in-progress
  vacuum past this age drops its cost-based delay, skips non-essential index
  cleanup, and stops bounding its buffer usage, trading throughput for
  racing the wraparound clock.
- Two hard-coded warning stages independent of the settings above: at
  **40,000,000 transactions before** the limit, every commit logs a
  `WARNING: database "…" must be vacuumed within N transactions`; at
  **3,000,000 transactions before** the limit, the database refuses any new
  write or DDL transaction (read-only queries and `VACUUM` itself keep
  working) until a database-wide `VACUUM` runs.

Persistent maintenance debt (autovacuum starved by cost limits, disabled
per-table, or blocked by a long-held lock) is what turns "routine" freezing
into a race against these thresholds — this domain's dead-tuple and
autovacuum-priority findings are the leading indicator; Health &
configuration's `age(datfrozenxid)` check is the lagging one. Don't
duplicate Health's proximity thresholds here — cite the mechanism, point at
Health's domain for the current-cluster number.

### Sequence exhaustion

`integer` sequences (the default for `serial`/`SERIAL`) top out at
`2,147,483,647` (≈2.1 billion); `bigint` sequences (`bigserial`) at
`9,223,372,036,854,775,807` (≈9.2 quintillion) — six orders of magnitude
more headroom. `pg_sequences.last_value` against `max_value` (or
`min_value` for a descending sequence) is the signal; note `last_value`
reads `NULL` on a sequence never advanced, or without `USAGE`/`SELECT`
privilege — don't misread a permissions gap as "sequence unused." There is
no Postgres-documented universal percentage for "how close is too close" —
it's genuinely workload-dependent (an insert-heavy table burns through
headroom far faster than a slowly-growing reference table). MCPg's own
`audit_sequences` ships concrete, named defaults worth citing as a
reasonable starting point rather than inventing one: **`warning_pct=80.0`,
`critical_pct=95.0`**.

**Worked example.** `audit_sequences` reports
`public.legacy_events_id_seq`: `last_value=2,101,000,000`,
`max_value=2,147,483,647` (an `integer` sequence), `used_pct≈97.9`,
`status=CRITICAL`. Suggested remediation (never applied): widen the column
and its sequence to `bigint` —
`ALTER TABLE legacy_events ALTER COLUMN id TYPE bigint, ALTER COLUMN id
SET DEFAULT nextval('legacy_events_id_seq'::regclass); ALTER SEQUENCE
legacy_events_id_seq AS bigint;` — planned and tested outside peak hours,
since it rewrites the column; the "as bigint" sequence alter alone is fast,
but the column type change is a full table rewrite unless done via a
new-column-and-swap pattern for a large table.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | No table on the autovacuum overdue list; no significant table or index bloat; all sequences well under warning threshold. |
| 7–8 | Some watchlist-level dead-tuple pressure or moderate bloat, but nothing overdue; clear priority list if action is needed; sequences under 80% used. |
| 5–6 | One or more tables overdue for autovacuum, or significant table/index bloat on an important relation; a sequence in the 80–95% warning band. |
| 1–4 | Wraparound-class risk (approaching `autovacuum_freeze_max_age` or beyond, or Health's proximity check already critical), autovacuum disabled on churny tables, or a sequence at/above the 95% critical band with no remediation path identified. |

## Sources

- PostgreSQL docs (`runtime-config-autovacuum.html`,
  `routine-vacuuming.html`, `runtime-config-vacuum.html`, `sql-vacuum.html`,
  `datatype-numeric.html`, `view-pg-sequences.html`,
  `monitoring-stats.html`) — autovacuum/freeze/failsafe defaults, wraparound
  warning stages, `VACUUM FULL` lock behavior, `integer`/`bigint` ranges,
  `pg_sequences` columns, `n_live_tup`/`n_dead_tup` semantics. Retrieved
  2026-09-08.
- PostgreSQL 12 release documentation and PostgreSQL Wiki "Reindex
  concurrently" — `REINDEX CONCURRENTLY` introduced in PG 12,
  `ShareUpdateExclusiveLock` behavior. Retrieved 2026-09-08.
- AWS Aurora PostgreSQL "Diagnosing table and index bloat" —
  `pgstattuple`-based diagnosis, clone-then-`pg_repack`/`VACUUM FULL`
  testing pattern, `vacuum_index_cleanup` storage parameter, temp-table
  bloat caveat. Retrieved 2026-09-08.
- MCPg source (`src/mcpg/autovacuum.py`, `health.py`, `config_advisor.py`,
  `audit.py`, `maintenance.py`) — `read_autovacuum_priority`,
  `analyze_table_bloat`, `audit_sequences` (§16.1) implementation and
  defaults; `audit_database`'s "Table Cleanliness & Bloat" and "Sequence
  Exhaustion" category logic; `run_maintenance`'s WRITE gate. Retrieved
  2026-09-08.
- Full provenance and headline findings: `research/postgresql-review/maintenance.md`.
