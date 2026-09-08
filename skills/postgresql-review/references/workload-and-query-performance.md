# Workload & query performance

## Intent

Top consumers and pathological patterns — not rewriting application code,
not a full query inventory of the app. This domain answers "what is the
database actually spending time on, and does any of it look pathological,"
using evidence MCPg can gather (`pg_stat_statements`, live plan/lock
snapshots) rather than static analysis of application code.

## MCPg tools

| Tool | What it actually does |
|---|---|
| `analyze_workload` | Top queries by `mean_exec_time` from `pg_stat_statements`. Returns `available: false` (no queries) if the extension isn't installed — never fails outright. |
| `detect_n_plus_one` | Heuristic scan of `pg_stat_statements` for a normalized query template called often, returning few rows per call, with real cumulative time burned (thresholds below). A candidate list, not a verdict. |
| `why_is_this_slow` | The headline single-call diagnosis for one user-supplied SQL statement. Composes an `EXPLAIN (FORMAT JSON)` plan, a snapshot of concurrent activity, blocking-lock pairs, and the cluster buffer-cache hit ratio into one categorized report (`plan` / `contention` / `cache` suggestions). Does **not** execute the query. |
| `explain_query` / `analyze_query_plan` | Lower-level building blocks `why_is_this_slow` is built from — useful when you want the raw plan tree or a structured summary (total cost, estimated rows, node types, sequentially-scanned relations) directly. Both default to plan-only (no execution); an explicit `io=True` switches to `EXPLAIN (ANALYZE, BUFFERS, TIMING)`, which **does** execute the query — see Limitation below before requesting it. |
| `list_active_queries` | Live snapshot of `pg_stat_activity` — pid, state, wait event, duration, `blocked_by`. Context for "what else is competing right now," not a standalone finding source. |
| `list_locks` / `find_blocking_chains` | Optional live-pressure context. `list_locks` reads `pg_locks` (waiters sorted first); `find_blocking_chains` is the standard `pg_blocking_pids()` + `pg_stat_activity` self-join pattern — use this, never a raw `pg_locks` self-join (see Limitation). |

`audit_database`'s **Slow Query Profiling** category (and optionally
**Concurrency & Lock Contention** as live-pressure context) also lands here
per `mcpg-tooling.md`'s mapping — dedupe its findings against what the
dedicated tools above already surfaced rather than double-counting.

## What to look for

**Slow statements by total/mean time.** `analyze_workload` orders
`pg_stat_statements` by `mean_exec_time` — the current column name as of
PostgreSQL 13 (pre-13 servers use `total_time`/`mean_time` instead; note
which applies if the server version is known). A single query with a high
`mean_exec_time` and modest `calls` is a candidate for `why_is_this_slow`
or `explain_query`; a query with very high `calls` and a *low* `mean_exec_time`
that still dominates `total_exec_time` is a candidate for batching or
caching rather than per-query tuning — the two shapes call for different
remediations even though both show up at the top of the same report.

**N+1 / repeated identical fingerprints.** Concretely: the same normalized
query template (same `queryid`/query shape, e.g. `SELECT * FROM orders
WHERE id = $1`) executed a very large number of times, each call returning
at most a row or two — the signature of a per-row lookup loop upstream
(a classic ORM lazy-load, or hand-rolled per-iteration SQL) rather than one
batched query. `detect_n_plus_one` operationalizes this with concrete
default thresholds: `min_calls=100`, `max_rows_per_call=2.0`,
`min_total_ms=50.0`. All three must hold — the call-count and
rows-per-call filters alone would also catch a legitimately-hot,
single-row primary-key lookup served mostly from cache; the cumulative
`total_exec_time ≥ 50ms` filter is what separates "this loop is actually
costing something" from "this is just a very popular, very cheap query."
Treat a match as a candidate to hand back to the user for investigation,
not a confirmed defect — the heuristic can't see the application code that
issued the calls.

**EXPLAIN mechanics and the sequential-scan signal.** `EXPLAIN` (plan only)
never runs the statement; `EXPLAIN ANALYZE` always does — official Postgres
guidance is explicit that "the statement is actually executed when the
ANALYZE option is used" and other side effects happen as usual, so
`ANALYZE` against an `INSERT`/`UPDATE`/`DELETE` (or an expensive `SELECT`
you don't want to materialize) should only run inside `BEGIN; ...;
ROLLBACK;` if it must run at all. In this domain that maps directly onto
MCPg's own `io` flag: leave `explain_query`/`analyze_query_plan` at their
default (plan-only) unless the user specifically wants real timing/buffer
numbers and accepts that the query will actually run. A `Seq Scan` node
against a large table in the plan — especially one carrying a high cost or
row estimate, and especially one repeated inside a nested loop — signals
the planner had no usable index for that relation's filter/join condition;
that's this domain's cue to *suggest* an index (never create one) or defer
entirely to the Indexing domain's own tools when the same table keeps
recurring across findings.

**Live blocking as optional context, not a primary finding.** `list_locks`
and `find_blocking_chains` describe pressure *right now* — a point-in-time
snapshot, not a trend. Use `find_blocking_chains`'s
`pg_blocking_pids()`-based pattern; official Postgres guidance explicitly
discourages a raw `pg_locks`-against-itself join for this because it "would
have to encode knowledge about which lock modes conflict with which
others," and the view doesn't expose wait-queue ordering either. A wide or
deep blocking chain found this way is worth reporting, but treat it as
corroborating evidence for a slow-query finding (or a bridge to the
Concurrency & Lock Contention live-pressure context this domain optionally
owns) rather than inventing a workload-performance finding out of a single
snapshot alone.

## Worked examples

**N+1 candidate, concretely.** `detect_n_plus_one` returns a template
`SELECT * FROM order_items WHERE order_id = $1` with `calls=4,812`,
`rows=4,790` (≈1.0 row/call), `total_exec_time≈612ms`, `mean_exec_time≈0.13ms`.
Each call is individually trivial (sub-millisecond, presumably an indexed
PK/FK lookup) — but nearly 5,000 calls for what should be one query per
page of orders is the per-row-loop signature: an application-layer loop
issuing one `order_items` lookup per `order` row instead of a single
`WHERE order_id IN (...)` or an eager-loaded join. **Suggested
remediation** (never applied): report the finding with the fingerprint,
call count, and total time; suggest the application batch the lookup
(`WHERE order_id = ANY($1)`/`IN (...)`) or use the ORM's eager-loading
equivalent — the specific code change is out of this domain's remit, only
the pattern and its cost are.

**`pg_stat_statements` unavailable.** `analyze_workload` and
`detect_n_plus_one` both return `available: false`; `audit_database`'s Slow
Query Profiling category degrades its "Top Time Consumer" metric to
`WARNING` with evidence `"pg_stat_statements extension is not installed or
enabled"` and the suggestion `"Add pg_stat_statements to
shared_preload_libraries, restart, and run 'CREATE EXTENSION
pg_stat_statements;'"` (in that order — the preload step is required
first). This domain scores **Not Implemented** rather than inventing a
"no hotspots found" conclusion from `list_active_queries` alone — a live
snapshot of currently-running queries is not evidence about historical
hotspots, and reporting 9-10 here would misrepresent an absence of
evidence as a clean bill of health.

## Limitation

`pg_stat_statements` requires `shared_preload_libraries` (a config change
plus a server restart), not merely `CREATE EXTENSION` — an operator who ran
only the latter still has no working extension, indistinguishable from
"never installed" to this review. If `pg_stat_statements` (or the workload
tools built on it) is unavailable: score with explicit **Not Implemented**
/ reduced confidence; do not invent hot queries or infer a clean workload
from unrelated live-pressure tools (`list_active_queries`, `list_locks`).
Separately: requesting `explain_query`/`analyze_query_plan` with `io=True`
(or any hand-written `EXPLAIN ANALYZE`) actually executes the statement —
flag this to the user before running it against a write statement or a
query expensive enough that materializing it is itself a cost worth
avoiding during a review.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | No severe hotspots found across the evidence actually gathered |
| 7–8 | Moderate hotspots with clear index/plan suggestions |
| 5–6 | Clear N+1 or dominant sequential scans on large tables |
| 1–4 | Pathological load without mitigation path |
| Not Implemented | `pg_stat_statements` (or workload tool) unavailable — exclude from composite average, never award 9–10 in its place |

## Sources

Full provenance and quoted verification: `research/postgresql-review/workload-and-query-performance.md`.

- <https://www.postgresql.org/docs/current/pgstatstatements.html> — `shared_preload_libraries` + restart requirement; current columns (`calls`, `total_exec_time`, `mean_exec_time`, `rows`) — retrieved 2026-09-08
- <https://www.postgresql.org/docs/13/pgstatstatements.html> / <https://www.postgresql.org/docs/12/pgstatstatements.html> — confirms the `total_time`/`mean_time` → `total_exec_time`/`mean_exec_time` rename at PostgreSQL 13 — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/sql-explain.html> — `EXPLAIN ANALYZE` execution warning and the `BEGIN; ...; ROLLBACK;` safe pattern — retrieved 2026-09-08
- <https://www.postgresql.org/docs/current/view-pg-locks.html> — recommends `pg_blocking_pids()` over a raw `pg_locks` self-join — retrieved 2026-09-08
- MCPg source (`src/mcpg/workload.py`, `src/mcpg/locks.py`, `src/mcpg/composite.py`, `src/mcpg/query.py`, `src/mcpg/audit.py`, `src/mcpg/extensions.py`) — exact tool queries, `detect_n_plus_one` default thresholds, `why_is_this_slow` suggestion thresholds, `audit_database` category checks — read 2026-09-08
- MCPg `docs/cookbook.md` — tool-sequencing recipe for slow-query investigation — read 2026-09-08
