# Research: Indexing

Status: authored from live verification (no MCPg session) Date: 2026-09-08

Starting point: `research/postgresql-review/02-domain-baselines.md` §3
(Indexing) plus the shipped v0 stub at
`skills/postgresql-review/references/indexing.md` (37 lines). This pass
verifies the baseline's load-bearing claims against official PostgreSQL
docs, a named industry source (PostgresAI), and MCPg's own source (v0.4.0+
tree, fetched via `gh api repos/devopam/MCPg/contents/...`), and deepens the
reference doc to the baseline's own ~120-160 line target.

## Headline verification findings (read before the rest)

1. **The Indexing domain's MCPg tool list in `mcpg-tooling.md` is
   incomplete for duplicate/redundant-index detection.** The current tool
   list (`recommend_indexes`, `recommend_index_drops`, `list_indexes`,
   `find_unused_objects`) has no tool that actually finds duplicate or
   redundant indexes. Direct inspection of MCPg's source
   (`src/mcpg/advisors.py`) shows that check lives in `run_advisors`, under
   two distinct rule functions: `_duplicate_indexes` (exact functional
   duplicates — same `pg_index.indkey`/`indclass`/`indoption`/
   `indisunique`/`indisprimary`, same `indpred`/`indexprs`, same access
   method) and `_redundant_indexes` (column-list *prefix* redundancy — one
   index's columns are a leading prefix of another's). MCPg's own
   `docs/cookbook.md` confirms this placement directly: `run_advisors(schema="app")
   # PK / FK / duplicate-index / nullable-tstz`. The reference doc below
   adds `run_advisors` to Indexing's tool list and names both rules
   explicitly — this is a correction to the tool map surfaced here, not
   silently patched into `mcpg-tooling.md` (out of this task's scope: "only
   write the two files named above").
2. **`recommend_index_drops`'s exact thresholds and reason taxonomy are
   now verified, not estimated.** Source (`src/mcpg/indexing.py`):
   `min_index_size_bytes` defaults to `1_000_000` (~1 MB — skip small
   indexes regardless of scan count), `low_scan_ratio` defaults to `0.01`
   (1%). Three reason codes in descending strength: `never_used`
   (`idx_scan == 0`), `scan_no_fetch` (`idx_scan > 0` but
   `idx_tup_fetch == 0` **and** `idx_tup_read == 0` — the `idx_tup_read`
   condition specifically excludes index-only scans, which read via the
   index but never increment `idx_tup_fetch`), `rarely_used` (`idx_scan` below
   `low_scan_ratio` of the table's total scan activity). PK/unique/exclusion
   indexes are hard-excluded. Output includes a ready-to-run
   `DROP INDEX CONCURRENTLY "schema"."index";` string with identifier
   quoting/escaping already applied.
3. **`recommend_indexes`'s heuristic is table-level scan-ratio, not
   query-level.** It flags tables with `n_live_tup >= min_live_tuples`
   (default 10,000) where `seq_scan > COALESCE(idx_scan, 0)`, then emits
   per-column suggestions: an unindexed single-column FK always wins
   (btree), otherwise a type-driven suggestion (GIN for `jsonb`/array
   columns, trigram GIN via `pg_trgm` for text columns). This confirms the
   baseline's caution that "not every FK needs an index" and "prefer
   workload corroboration" — the tool's own docstring says picking exactly
   *which* columns a workload filters on "still needs query analysis (see
   `analyze_workload`)."
4. **`find_unused_objects`'s exact query and caveat wording verified.**
   Source (`src/mcpg/advisors.py` `find_unused_objects`): indexes are
   flagged on `pg_stat_user_indexes.idx_scan = 0`, excluding
   `pg_index.indisprimary`/`indisunique`. Tool description states plainly:
   "a strong signal of dead code, but NOT a verdict... Run this after the
   database has been hot for a meaningful period — fresh stats produce
   false positives." Tables are flagged only when *both* scan counts and
   all three write counters (`n_tup_ins`/`upd`/`del`) are zero — a stricter
   "truly cold" bar than the index-side check.
5. **`check_database_health`'s invalid-index check is the literal query
   the baseline implies.** Source (`src/mcpg/health.py`
   `check_invalid_indexes`): `SELECT count(*) AS invalid FROM pg_index
   WHERE NOT indisvalid`. Confirms `pg_index.indisvalid = false` as the
   exact catalog signal, sourced directly rather than inferred.
6. **The stats-reset caveat is broader than "just `pg_stat_reset()`."**
   PostgreSQL's own docs (`monitoring-stats.html`) state cumulative
   counters are preserved across a *clean* shutdown but reset to zero
   "when starting from an unclean shutdown (e.g., after an immediate
   shutdown, a server crash, starting from a base backup, and point-in-time
   recovery)." A pgsql-hackers mailing-list thread ("No stats after
   promoting standby?") adds a fact the official docs page doesn't state
   in those words: "The stats file is deleted at the start of recovery, so
   stats from primary and standby will differ; this is considered a
   feature, not a bug" — i.e. a freshly promoted standby starts with
   `idx_scan = 0` on every index regardless of how long the index was
   live on the former primary. This is cited as a mailing-list discussion,
   not an official-docs guarantee, and stated as such in the reference doc.
7. **`CREATE INDEX CONCURRENTLY` mechanics confirmed verbatim against
   PostgreSQL's own `CREATE INDEX` docs**, including the multi-transaction
   build (index enters the catalog as invalid, two table scans, waits for
   pre-existing transactions to terminate before marking valid), the
   transaction-block restriction ("A regular `CREATE INDEX` command can be
   performed within a transaction block, but `CREATE INDEX CONCURRENTLY`
   cannot"), and the exact recommended recovery: "drop the index and try
   again to perform `CREATE INDEX CONCURRENTLY`. (Another possibility is to
   rebuild the index with `REINDEX INDEX CONCURRENTLY`.)"
8. **PostgresAI's lean-index guidance verified directly** (not
   paraphrased from memory): the cited PostgresAI blog post ("Why keep
   your index set lean," `postgres.ai/blog/20251110-postgres-marathon-2-013...`)
   names six concrete costs (write amplification — citing a Percona
   benchmark showing up to 58% throughput loss comparing 39 vs. 7 indexes
   on the same table; planner overhead; disk space — a real 20 GiB
   reclaimed / a 769 MiB → 5 MiB single-index example; buffer-cache
   pollution; autovacuum burden — "vacuum processes all indexes during the
   bulk delete phase, and typically again during the cleanup phase";
   WAL pressure) and states its actual recommended action in three
   imperatives: "Drop unused indexes. Drop redundant indexes. Reindex
   degraded (bloated) indexes."

## Supporting detail

- The baseline's in-scope/out-of-scope framing for Indexing (evidence-based
  add/drop, not blind heuristic creation, not micro-optimizing without
  workload evidence) is unchanged by this research pass — it already
  matched what MCPg's own tool docstrings independently argue for
  (`recommend_indexes`'s docstring explicitly defers exact column choice
  to `analyze_workload`).
- `list_indexes` was confirmed (via `docs/tools.md`) to report each index's
  access method (`btree`/`gin`/`gist`/`brin`/`hash`/`spgist`, or an
  extension's like `hnsw`/`ivfflat`) and a `partitioned` flag — useful for
  spotting a partitioned-index template vs. a genuinely redundant
  per-partition duplicate, but it does not itself do redundancy detection;
  that's `run_advisors`'s job (see finding #1).
- MCPg's own `_redundant_indexes` rule (source excerpt) walks only `btree`
  indexes, skips a candidate if it is itself primary/unique (protecting
  constraint-backed indexes from being flagged as the redundant member),
  and requires a *strict superset* column-prefix match plus equal partial-
  index predicates before flagging — this is exactly the "prefix-subset
  redundancy check" the task description asked me to verify rather than
  invent, now confirmed against real source instead of guessed.
- Nothing in this pass contradicts the shipped v0 stub's existing content;
  every item in it ("prefer CONCURRENTLY," "don't drop constraint-backed
  indexes," "invalid indexes are Critical/Important") is retained and now
  backed by a specific verified source rather than general knowledge.

## Sources (retrieved 2026-09-08 unless noted)

- <https://www.postgresql.org/docs/current/sql-createindex.html> — `CREATE
  INDEX CONCURRENTLY` mechanics: locking behavior avoided vs. plain
  `CREATE INDEX`, the multi-transaction build process, invalid-index
  failure mode, exact recovery guidance (drop + retry, or `REINDEX INDEX
  CONCURRENTLY`), and the transaction-block restriction.
- <https://www.postgresql.org/docs/current/monitoring-stats.html> —
  `pg_stat_all_indexes`/`pg_stat_user_indexes` view description, `idx_scan`
  column semantics (including the "multiple index searches per scan node
  execution" nuance for `IN`/`OR` queries), and the exact conditions under
  which cumulative stats counters reset to zero (unclean shutdown, crash,
  base backup, point-in-time recovery) vs. survive a clean shutdown.
- pgsql-hackers mailing-list thread, "No stats after promoting standby?"
  (`postgresql.org/message-id/...`, surfaced via web search, not an
  official docs page) — confirms a promoted standby's stats file is
  deleted at the start of recovery, so post-promotion `idx_scan` starts at
  zero independent of the index's actual historical usage.
- <https://postgres.ai/blog/20251110-postgres-marathon-2-013-why-keep-your-index-set-lean>
  — PostgresAI's lean-index guidance: six named costs of excess indexes
  (write amplification with a cited Percona 39-vs-7-index benchmark,
  planner overhead, disk space with a real 20 GiB / 769 MiB→5 MiB example,
  cache pollution, autovacuum burden, WAL pressure) and the three-part
  recommended action (drop unused, drop redundant, reindex bloated).
- `gh api repos/devopam/MCPg/contents/docs/tools.md` — `recommend_indexes`,
  `recommend_index_drops`, `list_indexes`, `check_database_health` tool
  descriptions (v0.4.0-era reference section) confirming behavior,
  parameters, and defaults.
- `gh api repos/devopam/MCPg/contents/docs/cookbook.md` — confirms
  duplicate-index detection is invoked via `run_advisors`, not via any tool
  in the Indexing domain's previously-listed set; shows `find_unused_objects`
  paired with `recommend_indexes` in a real usage recipe with the explicit
  caution "Drop nothing without re-reading `find_unused_objects` after the
  database has been hot for a meaningful period — fresh stats produce
  false positives."
- `gh api repos/devopam/MCPg/contents/src/mcpg/advisors.py` — full source
  for `_duplicate_indexes` (exact `pg_index` column comparison:
  `indkey`, `indclass`, `indoption`, `indisunique`, `indisprimary`,
  `indpred`, `indexprs`), `_redundant_indexes` (column-prefix subset
  algorithm, partial-index-predicate equality guard, PK/unique exclusion),
  and `find_unused_objects` (exact table/index queries and the "cold
  table" bar requiring zero scans *and* zero writes).
- `gh api repos/devopam/MCPg/contents/src/mcpg/indexing.py` — full source
  for `recommend_indexes` (scan-ratio heuristic, FK-detection subquery,
  GIN/trigram suggestion logic, partition roll-up to parent) and
  `recommend_index_drops` (exact defaults `min_index_size_bytes=1_000_000`,
  `low_scan_ratio=0.01`, the three-tier `DROP_REASON_*` taxonomy and its
  precise classification logic, generated `DROP INDEX CONCURRENTLY` SQL
  with identifier escaping).
- `gh api repos/devopam/MCPg/contents/src/mcpg/health.py` — exact
  `check_invalid_indexes` query: `SELECT count(*) AS invalid FROM pg_index
  WHERE NOT indisvalid`.
- `skills/postgresql-review/references/indexing.md` (this repo, pre-change
  version, 37 lines) — the shipped v0 stub this pass deepens; read to
  ensure no existing claim was contradicted.
- `skills/postgresql-review/references/mcpg-tooling.md` (this repo) — the
  tool map whose Indexing row this pass found incomplete (finding #1); not
  modified by this task, correction surfaced here instead.
- `research/postgresql-review/02-domain-baselines.md` §3 (this repo) — the
  baseline this reference deepens; in/out-of-scope framing carried forward
  unchanged.
