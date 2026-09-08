# Baseline: Workload & Query Performance

Status: research pass (no live MCPg session available)      Date: 2026-09-08

Starting point: the shipped v0 reference
(`skills/postgresql-review/references/workload-and-query-performance.md`,
~35 lines) plus `research/postgresql-review/02-domain-baselines.md` section
4. That baseline explicitly deferred concrete thresholds and worked examples
to this authoring pass. In the absence of a live MCPg session, this pass
substitutes direct verification against official PostgreSQL documentation
and MCPg's own source (`gh api repos/devopam/MCPg/contents/...`) for the
"deepen from live use" instruction the index gives — every threshold,
column name, and tool behavior below is either a fetched doc quote or a
line read directly from MCPg source, not a memory guess.

## Headline verification findings (read before the rest)

1. **`pg_stat_statements` activation is a config-and-restart step, not just
   `CREATE EXTENSION`.** Confirmed by direct fetch of the current PostgreSQL
   docs: "The module must be loaded by adding `pg_stat_statements` to
   `shared_preload_libraries` in `postgresql.conf`, because it requires
   additional shared memory. This means that a server restart is needed to
   add or remove the module." This is the reason the domain needs an
   explicit Not-Implemented fallback at all — an operator who only ever ran
   `CREATE EXTENSION pg_stat_statements;` without the preload+restart step
   still has an empty/non-functioning view, indistinguishable from "not
   installed" to a downstream reviewer. `compute_query_id` (default `auto`)
   also has to compute an id for the module to populate rows, but `auto`
   already does this automatically once `pg_stat_statements` is loaded — no
   separate action is normally needed for that half.
2. **The column names changed at PostgreSQL 13, and the original thin doc's
   hedge ("confirm the real current column names") was justified.** Direct
   comparison of the PG12 and PG13 docs pages: PG12's `pg_stat_statements`
   view has `total_time` / `mean_time`; PG13 split timing into planning vs.
   execution and introduced `total_exec_time` / `mean_exec_time` (plus
   `total_plan_time` / `mean_plan_time`), which remain the current names
   through the latest docs (checked against the "current" docs page, which
   resolves to PostgreSQL 18). `calls` and `rows` are unchanged across both.
   A review running against a pre-13 server needs the older names — worth
   a one-line caution in findings rather than a silent assumption.
3. **`EXPLAIN` alone never executes; `EXPLAIN ANALYZE` always does — this is
   official, not a judgment call.** Docs, verbatim: "the statement is
   actually executed when the `ANALYZE` option is used... other side
   effects of the statement will happen as usual," with the documented safe
   pattern being `BEGIN; EXPLAIN ANALYZE ...; ROLLBACK;` for anything other
   than a plain `SELECT`.
4. **The standard blocking-chain query pattern is `pg_blocking_pids()` +
   `pg_stat_activity`, not a raw `pg_locks` self-join** — and this isn't a
   style preference, it's what the official `pg_locks` docs page says
   explicitly: "It is better to use the `pg_blocking_pids()` function... to
   identify which process(es) a waiting process is blocked behind," adding
   that a raw self-join on `pg_locks` "is very difficult to get right in
   detail" because such a query "would have to encode knowledge about which
   lock modes conflict with which others." MCPg's own `find_blocking_chains`
   (`src/mcpg/locks.py`) implements exactly the documented pattern: a
   `pg_stat_activity` self-join via `LATERAL unnest(pg_blocking_pids(blocked.pid))`,
   filtered to `wait_event_type = 'Lock'` — confirming the tool matches
   documented best practice rather than an ad hoc heuristic.
5. **MCPg's `detect_n_plus_one` heuristic has real, specific default
   thresholds**, read directly from `src/mcpg/workload.py`: `min_calls=100`,
   `max_rows_per_call=2.0`, `min_total_ms=50.0`, `limit=25`. A query template
   trips the detector only when it has been called ≥100 times, averages
   ≤2 rows per call, *and* has burned ≥50ms cumulative execution time —
   the cumulative-time filter exists specifically to exclude a query called
   once or twice with a single-row return (a normal lookup, not a loop).
   Results sort by `total_exec_time` descending, worst offender first. The
   original thin doc's "N+1 / repeated identical fingerprints" line was
   directionally correct but had no concrete threshold to cite.
6. **`why_is_this_slow` does not execute the query by default — only
   `explain_query(..., io=True)` / `analyze_query_plan(..., io=True)` do, and
   that's opt-in.** Read directly from `src/mcpg/composite.py` and
   `src/mcpg/query.py`: the composite tool's docstring states plainly "The
   query is NOT executed — only EXPLAIN-ed." Its default plan call is
   `EXPLAIN (FORMAT JSON)`; passing `io=True` switches to
   `EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT JSON)`, which the source
   comments flag explicitly: "`io=True` runs `ANALYZE`, which executes the
   query." This matters for scope: this domain's tools are safe to run
   against arbitrary user-supplied SQL by default, but the reviewer should
   not casually request the `io=True` / `ANALYZE` variant against a write
   statement or an expensive query without the user's awareness that it
   actually runs.
7. **`why_is_this_slow`'s own suggestion thresholds are concrete and
   readable from source**, not invented for this doc:  a sequential scan
   flagged only when `seq_scans > 0` *and* `total_cost > 1_000`; a separate
   "high planner cost" suggestion at `total_cost > 100_000`; a contention
   suggestion whenever any blocking-lock pair exists, or when 25+ concurrent
   active queries are seen; a cache-pressure suggestion when the
   cluster-wide buffer cache hit ratio (`sum(blks_hit) / (blks_hit +
   blks_read)` from `pg_stat_database`) drops below 95%.
8. **`audit_database`'s "Slow Query Profiling" and "Concurrency & Lock
   Contention" categories have concrete, source-verified check thresholds**
   this domain should recognize when dedupe-mapping `audit_database`
   findings (per `mcpg-tooling.md`'s mapping table): Slow Query Profiling
   flags "Queries Running > 60s" (target `< 3`) and a "Top Time Consumer"
   metric from `pg_stat_statements` ordered by `total_exec_time DESC LIMIT
   1`; on the extension being absent it degrades gracefully with the exact
   suggested remediation "Add pg_stat_statements to shared_preload_libraries,
   restart, and run `CREATE EXTENSION pg_stat_statements;`" — the same
   ordering (preload+restart *before* `CREATE EXTENSION`) confirmed in
   finding 1. Concurrency & Lock Contention flags "Lock Wait Count" (target
   `< 5` blocked backends), "Longest Lock Wait Duration" (target `< 60`
   seconds, from `pg_stat_activity` where `wait_event_type = 'Lock'`), and
   "Deadlock Count" (target `0`, from `pg_stat_database.deadlocks`).

## Supporting detail

**On the Not-Implemented fix already applied to the shipped doc:** this
research pass confirms rather than revises it. `pg_stat_statements`
unavailability is a real, common, and entirely legitimate operational state
(many managed Postgres tiers don't expose `shared_preload_libraries` to
tenants at all), and MCPg's own tools (`analyze_workload`,
`detect_n_plus_one`) return a typed `available: false` rather than raising —
this domain's reviewer has no path to "no hotspots found" evidence in that
state, only "no evidence gathered," which is exactly what Not Implemented
means. The fix stands.

**On scope:** the baseline's in/out lines hold up under research — nothing
found here pushes this domain toward rewriting application code or
inventorying every query the app issues. `optimize_query` and
`recommend_headline_tools` exist in MCPg's tool surface but are read-only
*advisors* (they recommend, they don't rewrite anything used by the app),
consistent with "suggested, never applied."

## Sources

- <https://www.postgresql.org/docs/current/pgstatstatements.html> —
  `shared_preload_libraries` + restart requirement, `compute_query_id`
  interaction, current column table (`calls`, `total_exec_time`,
  `mean_exec_time`, `rows`) — retrieved 2026-09-08
- <https://www.postgresql.org/docs/13/pgstatstatements.html> — confirms
  `total_exec_time` / `mean_exec_time` already current at PG13 — retrieved
  2026-09-08
- <https://www.postgresql.org/docs/12/pgstatstatements.html> — confirms the
  pre-13 names were `total_time` / `mean_time`, establishing PG13 as the
  rename boundary — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/runtime-config-statistics.html> /
  search corroboration on `compute_query_id` — default `auto`, computes a
  query id automatically once a loaded module (in practice
  `pg_stat_statements`) requests one — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/sql-explain.html> — verbatim
  `EXPLAIN ANALYZE` execution warning and the `BEGIN; ...; ROLLBACK;` safe
  pattern for non-`SELECT` statements — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/view-pg-locks.html> — recommends
  `pg_blocking_pids()` over a raw `pg_locks` self-join, quotes the exact
  caution about lock-mode-conflict knowledge and wait-queue-ordering
  information the view doesn't expose; confirms `pg_locks` columns `pid`,
  `locktype`, `mode`, `granted`, `relation` — retrieved 2026-09-08
- `gh api repos/devopam/MCPg/contents/src/mcpg/workload.py` (MCPg source) —
  `analyze_workload` query (`pg_stat_statements` ordered by
  `mean_exec_time DESC`) and `detect_n_plus_one`'s exact default thresholds
  (`min_calls=100`, `max_rows_per_call=2.0`, `min_total_ms=50.0`,
  `limit=25`) and its SQL filter — read 2026-09-08
- `gh api repos/devopam/MCPg/contents/src/mcpg/locks.py` (MCPg source) —
  `list_locks` (ordered `granted ASC, pid` — waiters first) and
  `find_blocking_chains` (`pg_stat_activity` self-join via
  `unnest(pg_blocking_pids(...))`, `wait_event_type = 'Lock'` filter) exact
  queries and returned fields — read 2026-09-08
- `gh api repos/devopam/MCPg/contents/src/mcpg/composite.py` (MCPg source) —
  `why_is_this_slow`'s composed signals (plan summary, active queries,
  blocking locks, cache hit ratio) and its exact suggestion thresholds
  (`total_cost > 1_000` w/ seq scans, `total_cost > 100_000`, 25+ active
  queries, cache hit ratio `< 0.95`) — read 2026-09-08
- `gh api repos/devopam/MCPg/contents/src/mcpg/query.py` (MCPg source) —
  `explain_query`'s default (`EXPLAIN (FORMAT JSON)`, no execution) vs.
  `io=True` (`EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT JSON)`, which
  executes) and `analyze_query_plan`'s `sequential_scans` extraction
  (`Node Type == "Seq Scan"` → `Relation Name`) — read 2026-09-08
- `gh api repos/devopam/MCPg/contents/src/mcpg/audit.py` (MCPg source) —
  `audit_database`'s "Slow Query Profiling" (`Queries Running > 60s` target
  `< 3`; Top Time Consumer via `total_exec_time DESC LIMIT 1`) and
  "Concurrency & Lock Contention" (`Lock Wait Count` target `< 5`,
  `Longest Lock Wait` target `< 60`s, `Deadlock Count` target `0`)
  categories, including their exact evidence/suggestion strings — read
  2026-09-08
- `gh api repos/devopam/MCPg/contents/src/mcpg/extensions.py` (MCPg source)
  — confirms `extension_installed` (used to gate `analyze_workload` /
  `detect_n_plus_one`) checks `pg_extension`, i.e. whether `CREATE
  EXTENSION` has run — a distinct check from the `shared_preload_libraries`
  GUC, sharpening why both steps are needed together — read 2026-09-08
- `gh api repos/devopam/MCPg/contents/docs/cookbook.md` (MCPg docs) — the
  "Why is THIS query slow?" recipe ordering (`why_is_this_slow` first, then
  `analyze_query_plan` / `list_active_queries` / `find_blocking_chains` /
  `list_locks` for deeper investigation; `analyze_workload` /
  `detect_n_plus_one` for workload-level patterns) — read 2026-09-08
- `research/postgresql-review/02-domain-baselines.md` (this repo) — the
  baseline this document deepens, section 4 — read 2026-09-08
- `skills/postgresql-review/references/workload-and-query-performance.md`
  (this repo, pre-rewrite) — the shipped v0 starting point, including the
  already-applied Not-Implemented scoring fix this pass preserves — read
  2026-09-08
