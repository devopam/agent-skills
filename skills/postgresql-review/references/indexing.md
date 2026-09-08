# Indexing

## Intent

Lean, evidence-based indexes: add what a real access pattern needs, drop
what is pure cost, never spray indexes on every column that could
plausibly be filtered. Every index is a standing bet that its read benefit
outweighs its write, cache, vacuum, and WAL cost on every future
`INSERT`/`UPDATE`/`DELETE` — this domain audits whether that bet still pays
off, not whether more indexes exist.

## MCPg tools

| Tool | Role in this domain |
|---|---|
| `recommend_indexes` | Table-level heuristic: flags tables with `n_live_tup ≥ 10,000` (default `min_live_tuples`) where `seq_scan > idx_scan`. Per flagged table, suggests a btree on any unindexed single-column FK, plus type-driven suggestions (GIN for `jsonb`/array columns, trigram GIN via `pg_trgm` for text columns). |
| `recommend_index_drops` | Sibling advisor: walks `pg_stat_user_indexes` + `pg_stat_user_tables`, flags existing indexes that look like pure cost. Excludes PK/unique/exclusion-backing indexes and anything under 1 MB. Returns a ready-to-run `DROP INDEX CONCURRENTLY` statement per candidate. |
| `list_indexes` | Inventory: every index on a table with its access method (`btree`/`gin`/`gist`/`brin`/`hash`/`spgist`, or an extension's) and a `partitioned` flag. Ground truth for what exists before reasoning about duplicates. |
| `find_unused_objects` | Zero-scan signal for both tables and indexes since the last stats reset. Indexes: `idx_scan = 0`, excluding PK/unique. Tables: zero scans **and** zero writes (stricter "truly cold" bar). Explicitly documented as "a strong signal of dead code, but NOT a verdict." |
| `run_advisors` | Not in the original tool list for this domain but load-bearing for it: its `duplicate_indexes` and `redundant_indexes` rules are the only MCPg tools that actually detect duplicate/redundant indexes (see below). Also flags `unindexed_foreign_key` — useful corroboration for `recommend_indexes`' FK suggestions. |

Feed all of the above with workload evidence when available
(`analyze_workload`, `why_is_this_slow`) — a heuristic table/column
suggestion is weaker evidence than "this query plan actually seq-scans
here."

## What to look for

### Missing indexes for FK/filter patterns

PostgreSQL does not auto-index foreign keys (only `PRIMARY KEY`/`UNIQUE`
get an automatic index). An unindexed FK forces a sequential scan on the
child table for every `UPDATE`/`DELETE` on the parent that must check or
cascade the constraint, and a seq-scan join whenever the query joins from
the parent side. `recommend_indexes` and `run_advisors`'s
`unindexed_foreign_key` rule surface this from opposite angles — dedupe on
the same column when both fire.

Prefer workload corroboration before recommending a new index purely from
this heuristic — a small table, or a FK never actually joined through,
doesn't need the index just because it's unindexed. `recommend_indexes`
itself only fires past `n_live_tup ≥ 10,000` and `seq_scan > idx_scan` for
exactly this reason.

### Unused / rarely used large indexes

The core signal is `pg_stat_user_indexes.idx_scan` (or the all-database
`pg_stat_all_indexes`): each index scan increments this counter, so
`idx_scan = 0` over a meaningful observation window is the standard
"unused index" pattern. `recommend_index_drops` operationalizes this with
three reason codes, in descending confidence:

- **`never_used`** — `idx_scan = 0`. No read-side cost to dropping;
  the only thing reclaimed is the write/vacuum/WAL tax the index has
  been paying for nothing.
- **`scan_no_fetch`** — `idx_scan > 0` but the index reads and fetches
  zero rows. Usually an existence-check access pattern; a partial index
  (or no index) typically serves it more cheaply. (Index-only scans are
  deliberately excluded from this signal — they read via the index without
  incrementing the fetch counter, so a naive "zero rows returned" check
  would misclassify a working covering index as dead.)
- **`rarely_used`** — `idx_scan > 0` but below 1% (default
  `low_scan_ratio`) of the table's total scan activity. A real but
  marginal asset; weigh the disk/write cost against the read benefit
  rather than treating this tier as an automatic drop.

Indexes smaller than 1 MB, and anything backing a `PRIMARY KEY`/`UNIQUE`/
exclusion constraint, are excluded from `recommend_index_drops` by
design — dropping those would be a schema change, not a performance win.

**Caveat — false positives from a young stats window.** `idx_scan` is a
*cumulative* counter that resets to zero under more than just an explicit
`pg_stat_reset()` call: PostgreSQL's own docs state cumulative statistics
survive a clean shutdown but are reset "when starting from an unclean
shutdown (e.g., after an immediate shutdown, a server crash, starting from
a base backup, and point-in-time recovery)." A promoted standby is a
related case: per a pgsql-hackers discussion, its stats file is deleted at
the start of recovery, so a freshly promoted primary reports `idx_scan = 0`
on every index regardless of how long that index was actually live on the
former primary. Always ask how long the instance has been up, and whether
it recently failed over or restored, before treating `idx_scan = 0` as a
verdict — MCPg's own tool docs make the same point: "Run this after the
database has been hot for a meaningful period — fresh stats produce false
positives."

**Worked example.** `recommend_index_drops` returns `idx_orders_legacy_status`
on `public.orders`: 340 MB, `idx_scan = 0`, `reason_code = never_used`,
`table_seq_scan = 480,000`, `table_idx_scan = 12,000,000` (the table is
clearly served by other indexes — this one just never gets picked). The
instance has been up 45 days with no failover, so the signal is
trustworthy. Suggested remediation (not applied):

```sql
DROP INDEX CONCURRENTLY "public"."idx_orders_legacy_status";
```

Flag Important (Critical if disk pressure is already a finding elsewhere);
note that `CONCURRENTLY` avoids the exclusive lock a plain `DROP INDEX`
would take, and that instance uptime supports the zero-scan signal.

### Duplicate/redundant indexes

Two distinct checks, both catalog-level and both living in `run_advisors`
rather than in `recommend_index_drops`:

- **Exact duplicates** (`duplicate_indexes` rule) — two indexes on the same
  table with identical `pg_index.indkey` (column list), `indclass`
  (operator classes), `indoption` (sort/nulls-order), `indisunique`,
  `indisprimary`, `indpred` (partial-index predicate), and `indexprs`
  (expression list), on the same access method. Stricter than "same
  columns" — it will not flag a partial or expression index as a duplicate
  of a plain index over the same columns, avoiding a suggestion to drop a
  constraint- or predicate-specific index by mistake.
- **Prefix redundancy** (`redundant_indexes` rule) — one btree index's
  column list is a strict, ordered prefix of another's on the same table
  (e.g. `(tenant_id)` vs. `(tenant_id, created_at)`), with matching partial
  predicates. The shorter index is redundant because any query it serves,
  the longer index serves too — never flagged when the shorter index is
  the `PRIMARY KEY`/`UNIQUE` backer, since uniqueness enforcement needs its
  own index regardless of a longer covering index existing.

Both are read-only lint checks (`run_advisors`) — they report candidates,
they don't drop anything. Corroborate with `list_indexes`' access-method
field before suggesting a drop: a `btree` and a `gin` index over the same
column are never duplicates — they serve different query shapes.

### Invalid indexes, and why suggestions default to `CONCURRENTLY`

A plain `CREATE INDEX`/`DROP INDEX` takes a lock that blocks writes to the
table for the full build/drop duration — a single-scan, single-transaction
operation. `CONCURRENTLY` avoids that by splitting the build across
multiple transactions: the index enters the catalog as invalid first, then
two table scans run, each waiting for pre-existing transactions that could
modify the table to finish, before the index is finally marked valid. The
cost of that safety: it cannot run inside an explicit transaction block
(`CREATE INDEX CONCURRENTLY cannot run inside a transaction block` is a
hard error), it takes noticeably longer wall-clock time, and a failure
partway through (deadlock, or a uniqueness violation hit during the second
scan) leaves the index behind in the catalog marked invalid rather than
rolling back cleanly — a plain (non-concurrent) `CREATE INDEX` failure, by
contrast, rolls back within its single transaction and doesn't leave this
residue.

The exact catalog signal for an invalid index is `pg_index.indisvalid =
false` — `check_database_health`'s check runs literally `SELECT count(*)
FROM pg_index WHERE NOT indisvalid`. An invalid index is ignored for query
planning but still pays the full write-side maintenance cost: worst of
both worlds. The documented recovery path (not a guess): drop it and
retry, preferably concurrently again —

```sql
DROP INDEX CONCURRENTLY "schema"."broken_idx_name";
CREATE INDEX CONCURRENTLY "broken_idx_name" ON "schema"."table_name" (...);
```

— or use `REINDEX INDEX CONCURRENTLY` as the documented alternative when
the original definition is known and unchanged. Always score invalid
indexes Critical/Important per `SKILL.md`'s severity model — the table is
silently missing planner coverage it appears to have.

### Write/vacuum/WAL cost of the index set as a whole

Every index on a table is maintained on every `INSERT` and every
`UPDATE`/`DELETE` that touches an indexed column — write cost scales with
index count, not just write volume. Autovacuum has to process every index
during its bulk-delete and (typically again) its cleanup phase, so a wide
index set makes every vacuum slower and raises the odds of a table falling
behind; every index modification also generates its own WAL records,
adding replication/backup volume proportional to index count, not row
count. This is the mechanism behind "lean index set" in the Scoring guide
below — a concrete, ongoing tax paid on every write, whether or not the
index is ever read.

## Do / don't

- **Do** prefer `CREATE INDEX CONCURRENTLY` / `DROP INDEX CONCURRENTLY` in
  every suggested remediation, and name the invalid-index cleanup path
  when suggesting a rebuild.
- **Do** corroborate a `recommend_indexes` suggestion with workload
  evidence (`analyze_workload`, `why_is_this_slow`, or a user-supplied
  slow query) before treating it as more than a candidate.
- **Do** check instance uptime / recent failover or restore before trusting
  a `never_used`/zero-`idx_scan` finding as a verdict.
- **Don't** recommend creating every heuristically-suggested index without
  size/workload context — `recommend_indexes` itself only fires past a
  live-tuple floor for this reason; don't undo that discipline in the
  report.
- **Don't** drop a `PRIMARY KEY`/`UNIQUE`/exclusion-constraint-backed
  index, even if its `idx_scan` is low — that's a schema change with
  correctness implications, not a pure performance win, and both
  `recommend_index_drops` and `find_unused_objects` already exclude these
  by design.
- **Don't** flag a same-column index on a different access method
  (`btree` vs. `gin`/`gist`) as a duplicate — they serve different query
  shapes even over identical columns.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Recommendations empty, or only Minor (e.g. one small rarely-used index, no invalid indexes, no exact duplicates) |
| 7–8 | Small, clearly-justified set of adds/drops; at most one or two `rarely_used` drop candidates or one redundant-prefix pair |
| 5–6 | Several `never_used` large indexes, or one or more clear missing hot-path indexes corroborated by workload evidence, or an exact duplicate index pair on a core table |
| 1–4 | Invalid indexes present, or severe redundancy/duplication on core (high-write or high-row-count) tables, or a wide index set with clear vacuum/WAL impact already evidenced elsewhere in the review |

## Sources

- PostgreSQL 18 docs, `CREATE INDEX` (`sql-createindex.html`) —
  `CONCURRENTLY` locking/mechanics, invalid-index failure mode, exact
  recovery guidance, transaction-block restriction — retrieved 2026-09-08.
- PostgreSQL 18 docs, Cumulative Statistics System
  (`monitoring-stats.html`) — `pg_stat_all_indexes`/`pg_stat_user_indexes`
  and `idx_scan` semantics; exact stats-reset conditions (unclean
  shutdown, crash, base backup, PITR) — retrieved 2026-09-08.
- pgsql-hackers mailing-list thread, "No stats after promoting standby?"
  — confirms a promoted standby's stats reset independent of an index's
  actual historical usage — retrieved 2026-09-08.
- PostgresAI, "Why keep your index set lean"
  (postgres.ai/blog/20251110-postgres-marathon-2-013-...) — write
  amplification, planner overhead, disk space, cache pollution, autovacuum
  burden, and WAL pressure as the six named costs of an over-wide index
  set; recommended action ("drop unused, drop redundant, reindex bloated")
  — retrieved 2026-09-08.
- MCPg source (`gh api repos/devopam/MCPg/contents/...`), v0.4.0+ tree —
  `docs/tools.md`, `docs/cookbook.md`, `src/mcpg/indexing.py`,
  `src/mcpg/advisors.py`, `src/mcpg/health.py` — exact tool behavior,
  thresholds, reason-code taxonomy, and catalog queries for
  `recommend_indexes`, `recommend_index_drops`, `find_unused_objects`,
  `run_advisors`'s `duplicate_indexes`/`redundant_indexes`/
  `unindexed_foreign_key` rules, and `check_database_health`'s invalid-index
  check — retrieved 2026-09-08.
- Full provenance and headline corrections: `research/postgresql-review/indexing.md`.
