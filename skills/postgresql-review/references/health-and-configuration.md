# Health & configuration

## Intent

This is the reference `postgresql-review` applies to the question "is the
instance itself in good shape, independent of any particular table's schema
or any particular query's plan": connection and cache pressure,
transaction-ID wraparound proximity, checkpoint/bgwriter behavior, temp-file
spill, replication lag, invalid indexes, and `postgresql.conf` settings that
are actively dangerous or badly misaligned with the machine underneath it.
It is deliberately **not** capacity planning (sizing a new instance from
scratch), hardware selection, or non-Postgres layers such as a PgBouncer
config file sitting on disk unless a setting it manages is itself exposed
through `pg_settings`.

Two adjacent domains own work this file hands off rather than duplicates.
**Bloat/dead-tuple remediation** is [Maintenance](maintenance.md)'s —
`check_database_health`'s dead-tuple/bloat counts are only a coarse
cluster-wide signal here; per-table ranking, `REINDEX`, and autovacuum
tuning belong to Maintenance's `analyze_table_bloat` /
`read_autovacuum_priority`. **Deadlocks/lock contention** — despite sharing
`pg_stat_database`/`audit_database` — belong to
[Workload & query performance](workload-and-query-performance.md):
`audit_database`'s "Concurrency & Lock Contention" category is mapped
there per [`mcpg-tooling.md`](mcpg-tooling.md), not here.

## MCPg tools

| Tool | What it actually checks |
|---|---|
| `check_database_health` | Six fixed checks in one call: connection utilization vs. `max_connections`, buffer cache hit ratio, dead-tuple pressure, invalid indexes, replication lag, table bloat. Returns an overall `ok`/`warning` status plus per-check detail. |
| `audit_database` (categories: **Memory & I/O Efficiency**, **Transaction & Connection Health**, **Configuration Settings**) | The three `audit_database` categories this domain owns — see [`mcpg-tooling.md`](mcpg-tooling.md)'s mapping table. Each returns a 0–100 sub-score plus per-metric evidence/suggestion pairs; **dedupe** against `check_database_health` and `audit_settings` rather than reporting the same signal three times. |
| `audit_settings(total_ram_mb=…)` | A pghero-style sweep of `pg_settings`: dangerous toggles (`fsync`/`full_page_writes`/`autovacuum` off), cross-setting sanity (`maintenance_work_mem` vs. `work_mem`, `checkpoint_completion_target`), and — only when `total_ram_mb` is supplied — RAM-relative ratio checks for `shared_buffers`/`effective_cache_size`. Passing `total_ram_mb` meaningfully deepens this check; ask the user for it if known. |
| `recommend_postgres_conf(total_ram_mb=…, cpu_count=…, workload=…, storage=…)` | A **pure calculator** — no database connection at all. pgtune-style sizing for `shared_buffers`, `effective_cache_size`, `work_mem`, `maintenance_work_mem`, WAL sizing, and parallelism knobs from caller-supplied inputs. Treat its output as a starting point to hand the user, not a verdict on the live instance. |
| `get_server_info` | Version, access mode, transport, connection status — context for every other finding (e.g. whether `pg_stat_checkpointer` should even be queried, see below). |
| `list_extensions` | Extension inventory — flag a missing extension in this domain only when its absence blocks another domain's tooling (e.g. no `pg_stat_statements` limits Workload's `analyze_workload`; no `pgstattuple` limits Maintenance's precise bloat mode). |
| `verify_connection_encryption` | Reads `pg_stat_ssl` for the caller's own backend (`ssl`, `version`, `cipher`, `bits`) plus a cluster-wide encrypted/total tally — confirms the MCP path itself is actually running over TLS, not just configured to. |
| `read_pg_stat_io` (optional) | Wraps `pg_stat_io` — PostgreSQL **16+ only**; returns `available: false` on older servers rather than erroring. Useful when a cache-hit-ratio warning needs a per-`backend_type`/`context` breakdown of where the reads are actually landing. |
| `read_pg_wal_stats` / `get_wal_archive_status` (optional) | Pull in only when checkpoint/WAL findings need archiving-lag or WAL-generation-rate context beyond what `audit_database`'s Memory & I/O category already surfaces. |

## What to look for

### Transaction ID wraparound

Query: `SELECT datname, age(datfrozenxid) FROM pg_database;` — exactly what
MCPg's `audit_transactions_connections` runs. **Three scales describe "how
worried" for the same number and disagree — cite MCPg's own live output as
what drives this review's severity, not a number lifted from an external
doc:**

- **PostgreSQL's own mechanism**: `WARNING` only at 40 million transactions
  before the hard 2-billion ceiling; a **read-only emergency** (writes and
  anything assigning a new XID fail) only below 3 million remaining.
- **MCPg's `audit_transactions_connections`** is far more conservative:
  `WARNING` above **80,000,000**, `CRITICAL` above **150,000,000** — the
  150M figure matches `vacuum_freeze_table_age`'s default (where `VACUUM`
  is forced into an *aggressive* freeze), well short of actual catastrophe.
- **pganalyze's VACUUM Advisor** frames it as % of the 2-billion space:
  `warning` above 50% (~1.0B), `critical` above 80% (~1.6B).

`autovacuum_freeze_max_age`'s current default is **200,000,000**
transactions — verify against this cluster's actual `SHOW
autovacuum_freeze_max_age`, since it's commonly raised deliberately.
**Worked example:** a table whose `age(datfrozenxid)` reads 1.8 billion is
**Critical** under any of the three scales — it sits inside PostgreSQL's
own 40M-transaction warning band and will force an anti-wraparound
autovacuum (holds a `SHARE UPDATE EXCLUSIVE` lock, capable of blocking DDL)
well before the read-only emergency at ~1.997B. Suggested remediation
(never applied): schedule a database-wide `VACUUM` outside peak hours,
check `pg_stat_activity`/`pg_replication_slots` for anything holding back
the effective `xmin`, and confirm `autovacuum` isn't disabled anywhere in
scope.

### Cache hit ratio and buffer efficiency

`sum(blks_hit) / (sum(blks_hit) + sum(blks_read))` from `pg_stat_database`
is the standard signal; **99% is the threshold both MCPg's own
`check_database_health`/`audit_database` and the independently-sourced
Citus health-check playbook converge on** — worth citing as corroboration,
not one vendor's opinion. Below 99%, suggest `shared_buffers` sizing (see
settings table) only after confirming the working set genuinely exceeds
current `shared_buffers` — `read_pg_stat_io`, on PG16+, can show whether
misses concentrate on one relation.

### Checkpoint and background-writer behavior

**Version-dependent view split, PostgreSQL 17+:** checkpoint counters
(`num_timed`, `num_requested`, `buffers_written`, `write_time`,
`sync_time`) moved out of `pg_stat_bgwriter` into a **new
`pg_stat_checkpointer` view**; PG17+'s `pg_stat_bgwriter` keeps only
`buffers_clean`, `maxwritten_clean`, `buffers_alloc`, `stats_reset`. MCPg's
own `audit_database` (Memory & I/O Efficiency) already branches on whether
`pg_stat_checkpointer` exists — confirm `get_server_info`'s version before
trusting a raw `pg_stat_bgwriter`-only query on PG17+. Flag **Important**
when requested (non-timed) checkpoints exceed ~10% of the total, backend
processes write more buffers than the background writer itself, or any
backend-forced fsyncs occur — all three mean checkpoints are too infrequent
or `max_wal_size` is too small for the actual WAL volume.

### Temporary file spill

`pg_stat_database.temp_files` / `temp_bytes` track disk spills from sorts
and hash operations that didn't fit in `work_mem`. MCPg's own thresholds:
any spill at all is a **Minor**/warning signal, above 500 MB is
**Important**/critical — the fix is a `work_mem` increase or an index on
the sorted/grouped column, evaluated per query rather than as a blanket
global bump (a global `work_mem` increase multiplies across every
concurrent connection and sort node in a plan).

### Connections

`count(*)` from `pg_stat_activity` against `current_setting('max_connections')`.
MCPg's two tools use slightly different bands: standalone
`check_database_health` warns above 80% used; `audit_database`'s
Transaction & Connection Health is finer-grained — **Important** above
60%, **Critical** above 80%. A connection count pinned near
`max_connections` (default 100, often raised) with no pooler in front
warrants suggesting connection pooling (e.g. PgBouncer) over just raising
`max_connections` — each connection carries real backend memory overhead
independent of `work_mem`.

### Replication lag

For a primary with standbys: `pg_stat_replication` carries LSN progress
(`sent_lsn`/`write_lsn`/`flush_lsn`/`replay_lsn`) and elapsed-time lag
(`write_lag`/`flush_lag`/`replay_lag`, each an `interval`) — the lag
intervals answer "how much commit delay would `synchronous_commit`'s
stricter levels impose right now," not a prediction of catch-up time, and
revert to `NULL` on an idle, fully-caught-up standby (not missing data).
MCPg's `check_database_health` computes lag in **bytes** via
`pg_wal_lsn_diff` against `replay_lsn` and warns above 64 MiB. Zero
connected standbys reports `ok`, not a finding — absence of replication
isn't itself a defect here (durability posture is Maintenance/Security's
concern, e.g. backup strategy).

### Invalid indexes (health angle)

`SELECT * FROM pg_index WHERE NOT indisvalid` is both MCPg's
`check_database_health` query and the standard community detection query —
an invalid index is what's left behind when `CREATE INDEX CONCURRENTLY` or
`REINDEX INDEX CONCURRENTLY` fails or is interrupted (lock timeout,
cancelled session). Indexing owns judging whether to rebuild or drop a
specific one; this domain's angle is the instance-wide cost it keeps
imposing while it sits there: it still receives every `INSERT`/`UPDATE`
maintenance write, still generates WAL, and — the sharpest documented
effect — it **blocks HOT (Heap-Only Tuple) updates** on any column it
covers; one measured case showed the HOT-update ratio on an affected table
fall from 96.8% to 0%, i.e. every update on that column became a full
non-HOT update, generating more WAL and more dead tuples. **Worked
example:** three invalid indexes on a high-write table is **Important**
here (instance-wide write/WAL/vacuum cost); one left on a column backing a
*unique constraint* the application now silently lacks enforcement for
escalates to **Critical** and is also reported to Schema integrity.

### Dangerous or misaligned settings

Query `pg_settings`, or trust `audit_settings`'s own sweep — its checks and
current defaults it flags against:

| Setting | Current stable-Postgres default | Flag when |
|---|---|---|
| `fsync` | `on` | `off` — **Critical**: unrecoverable corruption risk on crash; there is no production justification, only throwaway/reload-from-backup clusters |
| `full_page_writes` | `on` | `off` — **Critical**: torn-page corruption risk on crash unless storage guarantees atomic 8 kB writes |
| `autovacuum` | `on` | `off` (globally) — **Critical**: unbounded bloat and eventual forced wraparound; PostgreSQL still force-vacuums tables past `autovacuum_freeze_max_age` even with this off, but bloat elsewhere goes unmanaged |
| `synchronous_commit` | `on` | `off` — **Important**, not Critical: no corruption risk (a crash can only lose the most recent ~3×`wal_writer_delay` of allegedly-committed work, not corrupt the database) — confirm it's a deliberate trade-off, especially on a primary rather than a replica |
| `shared_buffers` | 128 MB | below 128 MB absolute, or outside roughly a 10–45% (target ≈25%) share of host RAM when RAM is known — **Important**; a value still at the shipped default on a production-sized host is itself the finding |
| `effective_cache_size` | 4 GB | below ~40% of host RAM (typical target 50–75%) when RAM is known — **Minor/Important**: this is only a planner hint, not a memory allocation, but a low value makes the planner under-favor index scans |
| `work_mem` | 4 MB | no universal danger threshold — cross-reference against observed `temp_files`/`temp_bytes` above rather than flagging in isolation |
| `maintenance_work_mem` | 64 MB | below `work_mem` — **Minor**: `VACUUM`/`CREATE INDEX` get less memory than a single query sort |
| `checkpoint_completion_target` | 0.9 | below 0.9 — **Minor**: concentrates checkpoint I/O into a shorter burst instead of spreading it across the checkpoint interval |
| `max_wal_size` | 1 GB | frequent requested (non-timed) checkpoints (see above) are the practical symptom of this being too small for the actual write volume |
| `wal_level` | `replica` | below `replica` (`minimal`) on any instance expected to support replication or logical decoding later — **Important**, since raising it later requires a restart |
| `log_min_duration_statement` | `-1` (disabled) | left at `-1` on a production instance with no other slow-query visibility (no `pg_stat_statements`) — **Minor/Not Implemented**: no way to see what's actually slow |

`recommend_postgres_conf` is a pure function of RAM/CPU/workload/storage —
call it to generate a **suggested** `postgresql.conf` snippet the user can
review, never to imply the live instance already matches it.

### Sequences and extensions — boundary notes

Sequence-exhaustion risk (`audit_sequences`, the "Sequence Exhaustion"
`audit_database` category) is **Maintenance's**, not this domain's — don't
re-report a near-exhausted sequence here. Extension inventory
(`list_extensions`) is scored here only as a *blocker* note (e.g. no
`pg_stat_statements` limits what Workload can see); it is not itself a
Health finding unless a missing extension blocks one of this domain's own
checks (e.g. `pgstattuple` absent only matters to Maintenance's precise
bloat mode, not here).

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | `check_database_health` fully `ok`; `audit_database`'s three owned categories all `GOOD`; no dangerous settings (`fsync`/`full_page_writes`/`autovacuum` all `on`); wraparound age well under MCPg's own 80M `WARNING` line |
| 7–8 | Only Minor findings — e.g. `checkpoint_completion_target` below 0.9, `effective_cache_size` under-provisioned, a handful of invalid indexes with no unique-constraint impact |
| 5–6 | One or more Important findings — e.g. connection saturation in the 60–80% band with no pooler, cache hit ratio persistently under 99%, `synchronous_commit=off` on a primary with no documented rationale, wraparound age between MCPg's 80M and 150M lines |
| 1–4 | Any Critical health/config finding — `fsync`/`full_page_writes`/`autovacuum` off, wraparound age above MCPg's 150M `CRITICAL` line, connection saturation above 80%, widespread invalid indexes blocking constraint enforcement, any dangling `pg_prepared_xacts` row |
| 0 | Unreachable after readiness passed (should not occur in full-MCPg mode — see Phase 0) |

## Required evidence in findings

Each finding in this domain must include:

- **Severity** — Critical / Important / Minor / Not Implemented.
- **Signal/source** — the exact tool and check name (e.g.
  "`audit_database` → Transaction & Connection Health → Transaction ID
  Wraparound Age") or the exact query if produced via direct `run_select`
  fallback.
- **Current value vs. threshold** — the actual number MCPg returned and
  which of this doc's stated thresholds it crosses; don't restate a generic
  rule without the instance's own number attached.
- **Why it matters** — one sentence on the mechanism (e.g. "an anti-
  wraparound autovacuum will be forced and will hold a lock capable of
  blocking DDL," not just "wraparound is bad").
- **Suggested action** — concrete SQL/ops, explicitly **not applied** by
  this skill (e.g. "suggested: schedule `VACUUM (VERBOSE, ANALYZE)
  <table>` during a maintenance window" rather than running it).

## Sources

- <https://www.postgresql.org/docs/current/routine-vacuuming.html> — PG18
  wraparound mechanism, `age(datfrozenxid)`, the 40M/3M protective
  thresholds, `vacuum_freeze_min_age`/`vacuum_freeze_table_age` defaults —
  retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-vacuum.html> —
  `autovacuum_freeze_max_age` default (200,000,000) — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-resource.html>,
  <https://www.postgresql.org/docs/current/runtime-config-connection.html>,
  <https://www.postgresql.org/docs/current/runtime-config-query.html>,
  <https://www.postgresql.org/docs/current/runtime-config-wal.html>,
  <https://www.postgresql.org/docs/current/runtime-config-logging.html> —
  current-stable (PostgreSQL 18) defaults for `shared_buffers`,
  `work_mem`, `maintenance_work_mem`, `max_connections`,
  `effective_cache_size`, `fsync`, `synchronous_commit`, `wal_level`,
  `checkpoint_completion_target`, `max_wal_size`, `min_wal_size`,
  `log_min_duration_statement` — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/monitoring-stats.html> —
  `pg_stat_database`, `pg_stat_bgwriter`/`pg_stat_checkpointer` (PG17+
  split), `pg_stat_replication` lag columns — retrieved 2026-09-08
- <https://www.postgresql.org/about/news/postgresql-18-released-3142/> —
  confirms PostgreSQL 18 as current stable — retrieved 2026-09-08
- <https://pganalyze.com/docs/checks/vacuum/txid_wraparound> — pganalyze's
  percentage-of-2-billion wraparound framing and anti-wraparound-autovacuum
  lock behavior — retrieved 2026-09-08
- <https://postgres.ai/blog/20260106-invalid-index-overhead> — invalid-index
  costs including the HOT-update-ratio measurement and detection query —
  retrieved 2026-09-08
- <https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/>
  — 99% cache-hit-ratio corroboration — retrieved 2026-09-08
- <https://www.pgedge.com/blog/introducing-pg-healthcheck-postgresql-health-diagnostics>,
  <https://github.com/NikolayS/postgres_dba> — named industry health-check
  tools, confirmed real and current — retrieved 2026-09-08
- MCPg (`github.com/devopam/MCPg`) source, read directly via `gh api` at
  v0.8.x: `src/mcpg/health.py` (`check_database_health`),
  `src/mcpg/audit.py` (`audit_memory_io`, `audit_transactions_connections`,
  `_audit_settings_category`), `src/mcpg/config_advisor.py`
  (`audit_settings`, `recommend_postgres_conf`), `src/mcpg/io_stats.py`
  (`read_pg_stat_io`), `src/mcpg/liveops.py`
  (`verify_connection_encryption`) — retrieved 2026-09-08
- Full provenance, headline corrections, and additional detail:
  `research/postgresql-review/health-and-configuration.md` — authored
  2026-09-08
