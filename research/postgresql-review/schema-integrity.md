# Research: Schema integrity

**Retrieved:** 2026-09-08
Starting point: `research/postgresql-review/02-domain-baselines.md` §2 (Schema
integrity) and the thin v0 doc at
`skills/postgresql-review/references/schema-integrity.md`. This pass verifies
the baseline's claims by direct fetch of PostgreSQL's own catalog docs, the
MCPg source tree (no live MCPg session available, so source is the closest
substitute for "live use"), and named industry tooling, then deepens the
reference doc with concrete queries and one real, sourced worked example.

## Headline verification findings (read before the rest)

1. **MCPg's `run_advisors` already implements exactly the rules this domain
   needs, byte-for-byte** — verified directly against
   `src/mcpg/advisors.py` (fetched via `gh api
   repos/devopam/MCPg/contents/src/mcpg/advisors.py`). Six rules run:
   `missing_primary_key`, `unindexed_foreign_key`, `duplicate_indexes`,
   `nullable_timestamp_without_tz`, `recommend_graph_indices` (Apache AGE
   graph label tables missing a `properties` index — degrades to an empty
   result set gracefully if AGE isn't installed), and `redundant_indexes`
   (one B-Tree index whose columns are a strict leading-prefix subset of
   another). The module's own docstring states the rules are "deliberately
   conservative — the goal is 'would a careful reviewer flag this?' rather
   than 'is this provably wrong?'". `duplicate_indexes` and
   `redundant_indexes` sit partly on the Indexing domain's territory too —
   dedupe with `recommend_index_drops` findings rather than double-reporting
   the same index under both domains.
2. **`run_advisors`' own severities are coarser than this skill's three-tier
   model.** Every `Finding` carries only `severity: "warning"` (five of the
   six rules) or `severity: "info"` (the timestamp rule) — there is no
   advisor-native "critical". The reference doc below maps these onto
   Critical/Important/Minor itself rather than assuming MCPg's severity
   string is the skill's severity.
3. **The `unindexed_foreign_key` rule uses a leading-column heuristic, not a
   full covering-index check** — confirmed in source: it looks for *any*
   index whose `indkey[0]` matches the FK's first constrained column
   (`con.conkey[1]`), not an index covering every FK column. For a
   composite FK this can under- or over-report versus a stricter
   "does an index exist with the FK's exact column list as a prefix" check
   — worth naming as a known limitation rather than presenting the rule as
   exhaustive.
4. **`pg-index-health` is real, verified, and confirms these are
   industry-standard checks, not MCPg's own invention** — but the baseline's
   phrase "pg-index-health class" undersold what's actually two related
   projects. `github.com/mfvanek/pg-index-health` is a Java library
   (current 0.41.2, requires Java 17+, targets PostgreSQL 14–18, Apache 2.0,
   Spring Boot integration) — not a generic multi-language CLI. Its sibling,
   `github.com/mfvanek/pg-index-health-sql`, is the closer match to what this
   domain actually needs: a dependency-free collection of ~47 pure-SQL
   diagnostic queries, whose own README enumerates checks including, verbatim,
   **"Tables without a primary key"** and **"Foreign keys without associated
   indexes"** — independently confirming both of MCPg's core rules are
   recognized, named anti-patterns in the wider Postgres tooling ecosystem,
   not this skill's invention. It also separately checks "Duplicated
   (completely identical) foreign keys" and "Intersected (partially
   identical) foreign keys" — patterns MCPg's `run_advisors` does not
   currently cover, worth noting as a known gap rather than claiming parity.
5. **A real, numbered production incident exists for the FK-without-index
   cost**, sourced from `mydba.dev/blog/cascading-delete-slow-postgres` (a
   named, dated incident write-up, not a generic "this can be slow"
   assertion): a 204-million-row `events` table with an unindexed
   `account_id` foreign key; deleting 612 parent `accounts` rows triggered
   612 sequential scans reading "roughly 125 billion tuples"; a routine
   cleanup job that normally finished in ~4 seconds ran 42 minutes and
   produced user-facing 504 errors; a single-row parent delete's FK-trigger
   time was measured at 48122.611 ms before the fix. The fix —
   `CREATE INDEX CONCURRENTLY idx_events_account_id ON events (account_id)`
   — took 1 hour 52 minutes to build (large table, concurrent build is
   slower but non-blocking) and dropped the same single-row delete's
   FK-trigger time to 31.442 ms, and the full cleanup job to 34.2 seconds.
   **This is one incident, not a universal benchmark** — the reference doc
   below cites it as a labeled, sourced illustration of the failure mode and
   its order of magnitude, not as a threshold every FK is guaranteed to hit.
6. **PostgreSQL's own docs, not just secondary blog commentary, back the
   `timestamptz` recommendation.** The project's own "Don't Do This" wiki
   page (`wiki.postgresql.org/wiki/Don't_Do_This`) states the mechanism
   directly: `timestamp` "just stores a date and time you give it... a
   picture of a calendar and a clock rather than a point in time," and
   "arithmetic between timestamps from different locations or between
   timestamps from summer and winter may give the wrong answer" without the
   timezone information `timestamptz` carries. This is a first-party
   PostgreSQL project source, stronger footing than a generic third-party
   "best practices" blog.
7. **PostgreSQL's own partitioning docs give the concrete mechanism behind
   two of the "partition anomalies" the baseline said to keep high-level.**
   Verified directly against `postgresql.org/docs/current/ddl-partitioning.html`
   §5.12.2.2: "specifying bounds such that the new partition's values would
   overlap with those in one or more existing partitions will cause an
   error" (overlap is a creation-time hard error, not a silent anomaly to
   detect after the fact); "inserting data into the parent table that does
   not map to one of the existing partitions will cause an error" when no
   `DEFAULT` partition exists (a routing gap surfaces as a runtime insert
   failure, not silent data loss); and a `DEFAULT`-partition-specific
   maintenance caveat — attaching a new partition while a `DEFAULT`
   partition exists requires PostgreSQL to scan the `DEFAULT` partition
   under an `ACCESS EXCLUSIVE` lock to verify it holds no rows belonging to
   the new range, *unless* the operator first adds a `CHECK` constraint
   excluding the new partition's range from the `DEFAULT` partition.
8. **MCPg's `list_partitions` is descriptive, not diagnostic** — confirmed
   directly against `mcpg/introspection.py`: it returns `partitioned` (bool),
   `strategy` (`range`/`list`/`hash`/`null`, from `pg_partitioned_table`), and
   a `partitions` list of `{name, bounds}` pairs (`bounds` from
   `pg_get_expr(child.relpartbound, child.oid)` via `pg_inherits`). It does
   **not** itself flag overlaps, gaps, or a missing default — that reasoning
   is left to whoever consumes the tool's output. The reference doc below is
   written to reflect that: the agent inspects the returned bounds itself
   rather than expecting MCPg to pre-flag an anomaly.
9. **`summarize_table` and `list_foreign_keys` confirmed by source read**
   (`mcpg/composite.py`, `mcpg/introspection.py`): `summarize_table` composes
   `describe_table` + `list_constraints` + `list_indexes` + a
   table-filtered slice of `list_foreign_keys`, plus `pg_class`/
   `pg_stat_user_tables` storage stats and an optional `LIMIT`-based row
   sample — useful as the single call to pull FK/PK/index context for one
   hot table rather than composing four calls by hand. `list_foreign_keys`
   resolves `from_columns`/`to_columns` as ordinal-aligned arrays per FK,
   built from `unnest(conkey)`/`unnest(confkey)` joined back to
   `pg_attribute` — the pattern the reference doc's worked example reuses.

## Sources

- `src/mcpg/advisors.py` (MCPg repo, fetched via `gh api
  repos/devopam/MCPg/contents/src/mcpg/advisors.py`) — full source of
  `run_advisors` and its six rule functions, including the exact
  `pg_constraint`/`pg_class`/`pg_attribute`/`pg_index` queries reused below
  — retrieved 2026-09-08.
- `src/mcpg/introspection.py` (same repo) — source of `list_constraints`,
  `list_foreign_keys`, `list_partitions` — retrieved 2026-09-08.
- `src/mcpg/composite.py` (same repo) — source of `summarize_table` —
  retrieved 2026-09-08.
- `docs/tools.md` (same repo) — tool index confirming `list_constraints`,
  `list_foreign_keys`, `list_partitions` are READ-capability, available in
  every access mode; confirms the doc predates `run_advisors`/
  `summarize_table` (added after the "v0.4.0-era" doc's writing) so those
  two were verified from source directly instead — retrieved 2026-09-08.
- <https://www.postgresql.org/docs/current/catalog-pg-constraint.html> —
  `contype` code meanings (`p`, `f`, `u`, `c`, `x`, `t`, and PG17+'s `n` for
  not-null constraints now tracked in `pg_constraint`), `conkey`/`confkey`/
  `conrelid`/`confrelid` semantics — retrieved 2026-09-08.
- <https://www.postgresql.org/docs/current/catalog-pg-index.html> — `indkey`
  ordering and the "leading column" semantics (`indkey[0]` / first array
  element = first index column) — retrieved 2026-09-08.
- <https://www.postgresql.org/docs/current/ddl-partitioning.html> §5.12.2.2 —
  overlap-at-creation error, no-default-partition insert error, and the
  `DEFAULT`-partition `ACCESS EXCLUSIVE` scan-on-attach caveat — retrieved
  2026-09-08.
- <https://wiki.postgresql.org/wiki/Don%27t_Do_This> — first-party
  PostgreSQL project guidance against `timestamp without time zone`, exact
  "picture of a calendar and a clock" / "arithmetic... may give the wrong
  answer" wording — retrieved 2026-09-08.
- <https://mydba.dev/blog/cascading-delete-slow-postgres> — named, dated
  incident write-up with concrete numbers (204M-row table, 612 sequential
  scans, ~125B tuples read, 42-minute vs 4-second job, 48122ms→31ms per-row
  delete latency, 1h52m concurrent index build) — retrieved 2026-09-08.
- <https://www.yellowduck.be/posts/why-indexing-foreign-key-columns-matters-for-cascade-deletes-in-postgresql>
  — corroborating (hypothetical, not incident-sourced) explanation of the
  same mechanism; used only to confirm the general "100x or more"
  improvement framing is common commentary, not cited as a number in the
  reference doc since it's explicitly illustrative, not measured — retrieved
  2026-09-08.
- <https://github.com/mfvanek/pg-index-health> — project identity, current
  version 0.41.2, Java 17+, PostgreSQL 14–18, Apache 2.0 — retrieved
  2026-09-08.
- <https://github.com/mfvanek/pg-index-health-sql> — the pure-SQL sibling
  project; verbatim enumerated check list confirming "Tables without a
  primary key" and "Foreign keys without associated indexes" as named,
  recognized checks, plus the additional duplicate/intersected-FK checks
  MCPg does not currently run — retrieved 2026-09-08.

## Not verified / left qualitative

- No general, source-backed numeric threshold for "how large must the
  referencing table get before an unindexed FK becomes a real problem"
  exists in any source fetched — the mydba.dev incident (204M rows) is one
  real data point, not a general rule; the reference doc states the failure
  mode qualitatively (cost scales with parent-delete/-update volume ×
  child-table size) and cites the incident as an order-of-magnitude
  illustration only.
- No MCPg tool or PostgreSQL doc page computes partition-bound overlap or
  gap detection automatically — confirmed absent from `list_partitions`
  (finding 8 above). The reference doc's partition-sanity guidance is
  written as agent-side reasoning over `list_partitions`' returned bounds,
  not as a claim that MCPg does this arithmetic for you.
