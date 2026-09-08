# Baseline deepening: Health & configuration
Status: authored      Date: 2026-09-08

Starting point: `research/postgresql-review/02-domain-baselines.md` §1 (in/out
scope, industry themes, MCPg hooks — explicitly marked "not copy this file
verbatim") and the shipped v0 `references/health-and-configuration.md` (37
lines). No live MCPg session was available for this pass; per
`00-index.md`'s own instruction to "deepen references from live MCPg use
rather than inventing thresholds from memory alone," the substitute used here
is (a) direct source-code verification of MCPg's `health.py`,
`config_advisor.py`, and the three relevant `audit_database` categories in
`audit.py` (v0.8.x, same commit already used to verify the category-mapping
table in `references/mcpg-tooling.md`), and (b) direct fetch of current
PostgreSQL 18 documentation and named industry health-check sources — no
threshold below is invented from memory.

## Headline verification findings (read before the rest)

1. **Three different "wraparound danger" scales exist in the wild, and they
   do not agree — the reference doc must not present a single number as THE
   threshold.** Verified by direct fetch/source-read of all three:
   - **PostgreSQL's own protective mechanism** (`routine-vacuuming.html`,
     current/18 docs): a `WARNING` fires once the oldest XID is within **40
     million transactions of the hard 2-billion wraparound limit** (example
     wording: `database "mydb" must be vacuumed within 39985967
     transactions`); a hard **read-only emergency** begins once fewer than
     **3 million transactions remain** — at that point write transactions
     and anything that assigns a new XID fail, only `VACUUM` and read-only
     queries still work.
   - **MCPg's own `audit_transactions_connections`** (verified directly from
     `src/mcpg/audit.py`, the "Transaction & Connection Health" category)
     uses much lower, proactive absolute numbers on `age(datfrozenxid)`:
     **`WARNING` above 80,000,000, `CRITICAL` above 150,000,000** — the
     150M figure lines up with PostgreSQL's own `vacuum_freeze_table_age`
     default (150 million, the age at which an *aggressive* vacuum is
     forced), not with the actual ~1.997-billion catastrophe point.
   - **pganalyze's public VACUUM Advisor docs** frame the identical
     underlying signal as a **percentage of the 2-billion XID space**:
     `warning` above 50% (≈1.0B), `critical` above 80% (≈1.6B).
   None of these three is "wrong" — they're different risk appetites applied
   to the same `age(datfrozenxid)` number. The authored reference states all
   three, labeled by source, and tells the reviewing agent to **trust
   MCPg's own live `CRITICAL`/`WARNING` output (150M / 80M) as what actually
   fires in a review**, not a number quoted from any external doc.
2. **`autovacuum_freeze_max_age` default confirmed: 200,000,000 transactions**
   (PostgreSQL 18 `runtime-config-vacuum.html` / `routine-vacuuming.html`,
   direct fetch) — the original thin doc named no number at all, so this is
   a first verification, not a correction. Note it sits *between* MCPg's own
   80M/150M health-check thresholds and the 2B hard limit — i.e. MCPg's
   `CRITICAL` fires well before a table would even be forced into an
   aggressive freeze by this setting's default.
3. **`checkpoint_completion_target`'s current default is confirmed 0.9**
   (PostgreSQL 18 `runtime-config-wal.html`) — this matches what MCPg's own
   `config_advisor.py` source already assumed in an inline comment ("0.9
   (the PG 14+ default)"). Not a correction; confirms MCPg's embedded
   assumption is accurate and safe to cite as-is.
4. **`pg_stat_bgwriter` was split in PostgreSQL 17** — checkpoint-specific
   counters (`num_timed`, `num_requested`, `buffers_written`, `write_time`,
   `sync_time`, and others) moved to a **new `pg_stat_checkpointer` view**;
   `pg_stat_bgwriter` on PG17+ retains only `buffers_clean`,
   `maxwritten_clean`, `buffers_alloc`, `stats_reset`. Confirmed via web
   search (dbi-services, pganalyze's own "5 minutes of Postgres" post) and
   independently confirmed in MCPg's own source: `audit_memory_io` in
   `audit.py` already branches on whether `pg_stat_checkpointer` exists
   before choosing its checkpoint query. The authored reference names both
   views and the version boundary rather than assuming one fixed schema.
5. **Invalid indexes have a concrete, sourced instance-health cost beyond
   "wasted space,"** which the original thin doc's "invalid-index signals"
   bullet didn't have backing for. PostgresAI's invalid-index-overhead
   analysis (fetched directly) measured the **HOT (Heap-Only Tuple) update
   ratio dropping from 96.8% to 0%** on a table once an invalid index
   existed on an updated column — every update on that column falls back to
   a full (non-HOT) update, generating more WAL and more dead tuples for
   autovacuum to clean up. This is the specific "health-adjacent" angle the
   task brief asked for, distinct from Indexing's own deeper query-planning
   coverage of the same objects.
6. **Scope correction against the already-verified category map**:
   `pg_stat_database.deadlocks` is a real column and the task's research
   prompt listed it among health-relevant `pg_stat_database` signals, but
   MCPg checks it under the **"Concurrency & Lock Contention"**
   `audit_database` category (`audit_concurrency_locks` in `audit.py`),
   which `references/mcpg-tooling.md`'s own mapping table assigns to
   **Workload & query performance** (optional live-pressure context), not
   Health & configuration. The authored reference does not duplicate this
   finding — it cross-references the boundary explicitly so the two domains
   don't double-score the same deadlock count.
7. **`pg_stat_database.conflicts`** (recovery-conflict cancellations on a
   standby) is a real, documented column, but grepping every fetched MCPg
   module (`health.py`, `audit.py`, `io_stats.py`) found **no tool that
   currently reads it**. The authored reference names it as a real signal
   worth a direct `run_select` check on a standby, but does not claim MCPg
   tool coverage that doesn't exist — per the "don't fabricate tool
   behavior" rule.
8. **Named industry references are now individually verified**, replacing
   the baseline's vaguer "pg-healthcheck / postgres_dba style check groups"
   phrasing:
   - **pganalyze VACUUM Advisor / txid_wraparound docs** — real, current,
     fetched directly; also documents that PostgreSQL's anti-wraparound
     autovacuum holds a `SHARE UPDATE EXCLUSIVE` lock that can block DDL,
     a detail worth keeping in the worked example.
   - **PostgresAI invalid-index-overhead blog** (2026-01-06) — real,
     fetched directly, six named costs plus the HOT-update measurement
     above.
   - **Citus's 2019 "Health checks for your Postgres database" playbook** —
     real, fetched directly; states a 99% cache-hit-ratio target (same
     number MCPg's own `check_cache_hit_ratio`/`audit_memory_io` use
     independently) and an unused-index review cadence, but does **not**
     cover connections, replication, checkpoints, or dangerous settings —
     narrower than the baseline implied, noted so it isn't over-cited.
   - **pg-healthcheck (pgEdge)** and **postgres_dba (NikolayS)** — both
     confirmed to be real, existing, actively-described open-source tools
     with check groups matching the baseline's description (vacuum/bloat,
     WAL/slots, locks, upgrade-readiness for pg-healthcheck; bloat, index
     health, lock trees, vacuum monitoring for postgres_dba).

## Supporting detail: exact thresholds pulled from MCPg source

Verified directly against `src/mcpg/health.py` (`check_database_health`,
six checks) and `src/mcpg/audit.py` (`audit_memory_io` /
`audit_transactions_connections`, the two `audit_database` categories this
domain owns beyond "Configuration Settings") and `src/mcpg/config_advisor.py`
(`audit_settings`, `recommend_postgres_conf`), all read at commit-current
v0.8.x on 2026-09-08:

| Check (tool) | Threshold |
|---|---|
| Connections vs. `max_connections` (`check_database_health`) | `WARNING` above 80% used |
| Connection saturation (`audit_database`) | `WARNING` above 60%, `CRITICAL` above 80% |
| Buffer cache hit ratio (both) | `WARNING`/flag below 99% (`blks_hit`/(`blks_hit`+`blks_read`) from `pg_stat_database`) |
| Dead tuples (`check_database_health`) | table flagged when `n_dead_tup > 1000` **and** `n_dead_tup > 0.1 × n_live_tup` |
| Invalid indexes (`check_database_health`) | any row in `pg_index WHERE NOT indisvalid` |
| Replication lag (`check_database_health`) | `WARNING` above 64 MiB max standby lag (`pg_wal_lsn_diff` vs. `replay_lsn`) |
| Table bloat (`check_database_health`) | flagged when `relpages` exceeds ~2.0× a catalog-estimated minimum, ignoring tables under ~128 pages (~1 MiB) |
| Checkpoint/bgwriter behavior (`audit_database`) | `WARNING` when requested (non-timed) checkpoints exceed 10% of the total, or backend writes exceed bgwriter clean writes, or any backend fsyncs occur |
| Temp file spill (`audit_database`) | `WARNING` above 0 bytes, `CRITICAL` above 500 MB (`pg_stat_database.temp_bytes`) |
| Rollback rate (`audit_database`) | `WARNING` above 0.1% of commits+rollbacks |
| XID wraparound age (`audit_database`) | `WARNING` above 80,000,000, `CRITICAL` above 150,000,000 (`age(datfrozenxid)`) |
| Prepared transactions (`audit_database`) | any row in `pg_prepared_xacts` is `CRITICAL` |
| `fsync` / `full_page_writes` / `autovacuum` off (`audit_settings`) | each `CRITICAL` if `off` |
| `synchronous_commit` off (`audit_settings`) | `WARNING` |
| `shared_buffers` (`audit_settings`) | `WARNING` below 128 MB absolute; with RAM supplied, `WARNING` outside a 10–45% of total-RAM band |
| `maintenance_work_mem` (`audit_settings`) | `WARNING` if below `work_mem` |
| `checkpoint_completion_target` (`audit_settings`) | `WARNING` below 0.9 |
| `effective_cache_size` (`audit_settings`, RAM-aware only) | `WARNING` below 40% of total RAM |

`recommend_postgres_conf` is a **pure calculator** (no DB connection) —
pgtune-style sizing from caller-supplied RAM/CPU/workload/storage inputs, not
a live read. Treat its output as a **starting point**, per its own
docstring, not gospel — this framing is preserved in the authored reference.

## Supporting detail: verified current PostgreSQL 18 defaults

Fetched directly from `postgresql.org/docs/current/` (resolves to PG18 as of
this research date):

| Setting | Current default |
|---|---|
| `shared_buffers` | 128 MB (may be lower if the OS won't support it at `initdb` time) |
| `effective_cache_size` | 4 GB |
| `work_mem` | 4 MB |
| `maintenance_work_mem` | 64 MB |
| `max_connections` | 100 (typical; may be lower per-platform) |
| `checkpoint_completion_target` | 0.9 |
| `max_wal_size` | 1 GB |
| `min_wal_size` | 80 MB |
| `wal_level` | `replica` |
| `synchronous_commit` | `on` |
| `fsync` | `on` |
| `log_min_duration_statement` | `-1` (disabled — no statement-duration logging at all) |
| `autovacuum_freeze_max_age` | 200,000,000 transactions |
| `vacuum_freeze_min_age` | 50,000,000 transactions |
| `vacuum_freeze_table_age` | 150,000,000 transactions (capped at 0.95× `autovacuum_freeze_max_age`) |

## Sources

- <https://www.postgresql.org/docs/current/routine-vacuuming.html> — PG18
  wraparound mechanism: `age(datfrozenxid)`, the 40M-transaction `WARNING`
  wording, the <3M-transaction read-only emergency, aggressive-vacuum
  triggers, `vacuum_freeze_min_age`/`vacuum_freeze_table_age` defaults,
  post-emergency recovery sequence (prepared transactions, long
  transactions, replication slots, plain `VACUUM` not `VACUUM FULL`/`FREEZE`)
  — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-vacuum.html> —
  confirms `autovacuum_freeze_max_age` default 200,000,000 — retrieved
  2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-resource.html> —
  `shared_buffers` (128MB), `work_mem` (4MB), `maintenance_work_mem` (64MB)
  current defaults — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-connection.html>
  — `max_connections` default (100, typical) — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-query.html> —
  `effective_cache_size` default (4GB) — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-wal.html> —
  `fsync` (on), `synchronous_commit` (on), `wal_level` (replica),
  `checkpoint_completion_target` (0.9), `max_wal_size` (1GB), `min_wal_size`
  (80MB) current defaults; fsync=off / synchronous_commit=off risk framing
  — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-logging.html> —
  `log_min_duration_statement` default (`-1`, disabled) — retrieved
  2026-09-08
- <https://www.postgresql.org/docs/current/monitoring-stats.html> —
  `pg_stat_database` columns (`blks_hit`/`blks_read`, `deadlocks`,
  `conflicts`, `temp_files`/`temp_bytes`, `xact_commit`/`xact_rollback`);
  `pg_stat_bgwriter` (PG17+ reduced column set) vs. new
  `pg_stat_checkpointer` view; `pg_stat_replication` lag columns
  (`write_lag`/`flush_lag`/`replay_lag`, `sent_lsn`/`write_lsn`/
  `flush_lsn`/`replay_lsn`) — retrieved 2026-09-08
- <https://www.postgresql.org/about/news/postgresql-18-released-3142/> and
  <https://www.postgresql.org/docs/release/18.6/> — confirms PostgreSQL 18
  (18.6, 2026-08-13) is the current stable release this doc's defaults
  target — retrieved 2026-09-08
- dbi-services blog, "PostgreSQL 17: New catalog view pg_stat_checkpointer"
  and pganalyze's "5 minutes of Postgres" post on the same topic — confirms
  the PG17 `pg_stat_bgwriter`/`pg_stat_checkpointer` split and which columns
  moved — retrieved 2026-09-08 (web search summary, not a raw fetch)
- <https://pganalyze.com/docs/checks/vacuum/txid_wraparound> — pganalyze's
  percentage-of-2-billion wraparound thresholds (50% warning / 80% critical
  / ~99.85% shutdown risk), the `SHARE UPDATE EXCLUSIVE`-lock detail on
  anti-wraparound autovacuum, and its "long-running transaction" /
  "blocking replication slot" remediation framing — retrieved 2026-09-08
- <https://postgres.ai/blog/20260106-invalid-index-overhead> — six named
  costs of invalid indexes, the 96.8%→0% HOT-update-ratio measurement, the
  `pg_index WHERE NOT indisvalid` detection query (matches MCPg's own
  `check_invalid_indexes` query exactly), `_ccnew`/`_ccold` recovery-suffix
  guidance — retrieved 2026-09-08
- <https://www.citusdata.com/blog/2019/03/29/health-checks-for-your-postgres-database/>
  — 99% cache-hit-ratio target, unused-index review guidance; confirmed
  this playbook does **not** cover connections/replication/checkpoints/
  dangerous settings, narrower than the original baseline implied —
  retrieved 2026-09-08
- <https://www.pgedge.com/blog/introducing-pg-healthcheck-postgresql-health-diagnostics>
  — confirms pg-healthcheck is a real, current tool with vacuum/WAL-slot/
  lock-contention/upgrade-readiness check groups and a natural-language
  `ask` mode — retrieved 2026-09-08
- <https://github.com/NikolayS/postgres_dba> — confirms postgres_dba is a
  real, current tool; bloat estimation, index health, lock trees, vacuum
  monitoring, buffer-cache inspection check groups; works against the
  `pg_monitor` role for most reports — retrieved 2026-09-08
- `repos/devopam/MCPg` (GitHub, via `gh api`), `src/mcpg/health.py` — every
  `check_database_health` threshold cited above, read directly — retrieved
  2026-09-08
- `repos/devopam/MCPg`, `src/mcpg/config_advisor.py` — `audit_settings`
  rule set and exact thresholds, `recommend_postgres_conf`'s pgtune-style
  pure-function behavior, `audit_sequences` (confirmed **not** this
  domain's — see Maintenance mapping) — read directly — retrieved
  2026-09-08
- `repos/devopam/MCPg`, `src/mcpg/audit.py` — `audit_memory_io`,
  `audit_transactions_connections`, `_audit_settings_category` (the three
  `audit_database` categories this domain owns), plus confirming
  `audit_concurrency_locks` (deadlocks) and `_audit_sequences_category`
  belong to sibling domains per the mapping table — read directly —
  retrieved 2026-09-08
- `repos/devopam/MCPg`, `src/mcpg/io_stats.py` — confirms `read_pg_stat_io`
  wraps `pg_stat_io`, PostgreSQL 16+ only, returns `available=False` below
  16 — read directly — retrieved 2026-09-08
- `repos/devopam/MCPg`, `src/mcpg/liveops.py` — confirms
  `verify_connection_encryption` reads `pg_stat_ssl` (`ssl`, `version`,
  `cipher`, `bits`) for the caller's own backend plus a cluster-wide tally
  — read directly — retrieved 2026-09-08
- `repos/devopam/MCPg`, `docs/tools.md` — tool index and the
  "Health, tuning & advisors" category description used to cross-check tool
  names against the skill's existing `references/mcpg-tooling.md` — read
  directly — retrieved 2026-09-08
- `/Users/devopammittra/GitHub/agent-skills/skills/postgresql-review/references/mcpg-tooling.md`
  (this repo) — source of the `audit_database` category→domain mapping this
  file cross-checks findings #6 and #8 against — read 2026-09-08
- `/Users/devopammittra/GitHub/agent-skills/research/postgresql-review/02-domain-baselines.md`
  §1 (this repo) — the baseline this document deepens — read 2026-09-08
