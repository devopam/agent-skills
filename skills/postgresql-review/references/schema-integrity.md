# Schema integrity

## Intent

Structural soundness of the schema itself: keys, foreign-key graph
integrity, catalog-level advisor rules, and high-level partition sanity —
not product data modeling, not naming of every business entity, and not
green-field schema redesign.

## MCPg tools

`run_advisors`, `list_constraints`, `list_foreign_keys`, `list_partitions`,
`summarize_table` for hot tables. `audit_database` does **not** cover this
domain (see `mcpg-tooling.md`'s mapping table) — it relies entirely on its
own dedicated tools.

`run_advisors(schema)` runs six catalog-driven rules and returns findings
with a `rule` id, an MCPg-native `severity` (`"warning"` or `"info"` —
coarser than this skill's scale, see Scoring guide), `object`, `message`:

| Rule | What it flags |
|---|---|
| `missing_primary_key` | Table (`relkind` `r`/`p`) with no `pg_constraint` row where `contype='p'` |
| `unindexed_foreign_key` | FK (`contype='f'`) whose first constrained column has no index with a matching leading column |
| `duplicate_indexes` | Two indexes, same access method, identical columns/opclasses/sort options/uniqueness/predicate/expressions |
| `nullable_timestamp_without_tz` | Nullable column of type `timestamp` (i.e. without time zone) |
| `redundant_indexes` | A B-Tree index whose columns are a strict leading-prefix subset of another's |
| `recommend_graph_indices` | (Apache AGE only) graph label table with no index on `properties` |

`duplicate_indexes`/`redundant_indexes` also touch Indexing's territory —
**dedupe** against `recommend_index_drops` rather than double-reporting.

`list_constraints(schema, table)` returns each constraint's `type`
(`primary_key`/`foreign_key`/`unique`/`check`/`exclusion`/`other`) plus its
`pg_get_constraintdef()` text. `list_foreign_keys(schema)` resolves every
FK to `from_table`/`from_columns` and `to_schema`/`to_table`/`to_columns`,
column arrays aligned by ordinal position. `list_partitions(schema,
table)` is **descriptive, not diagnostic** — `partitioned` (bool),
`strategy` (`range`/`list`/`hash`/`null`), and each partition's `name` +
rendered `bounds`; it does not itself flag overlap, gaps, or a missing
default — that reasoning is on the reviewer. `summarize_table(schema,
table)` is the single-call composite for one hot table (columns, PK, FKs,
constraints, indexes, storage stats, optional row sample) — use it instead
of chaining four calls by hand.

## What to look for

**Missing primary keys.** A base or partitioned table with no `PRIMARY
KEY`. Real, mutable business tables need one — ORM patterns, logical
replication (`DEFAULT` `REPLICA IDENTITY` *is* the PK), and maintenance
tooling assume one exists. Pure append-only log/staging tables are a
legitimate exception — check whether the table is actually mutated by
identity before flagging.

**Foreign keys without a supporting index on the referencing side.**
PostgreSQL automatically indexes the *referenced* side of an FK (it must
be a PK or unique constraint) but never the *referencing* side. Every
`UPDATE`/`DELETE` on a parent row that must check or cascade to children
scans the child table's FK column if unindexed — for `CASCADE` or a
`RESTRICT`/`NO ACTION` check alike. Diagnostic pattern (the same join
`run_advisors` runs internally):

```sql
SELECT con.conname AS fk_name,
       nsp.nspname || '.' || cls.relname AS referencing_table,
       att.attname AS first_fk_column
FROM   pg_constraint con
JOIN   pg_class      cls ON cls.oid = con.conrelid
JOIN   pg_namespace  nsp ON nsp.oid = cls.relnamespace
JOIN   pg_attribute  att ON att.attrelid = con.conrelid
                        AND att.attnum   = con.conkey[1]
WHERE  con.contype = 'f' AND nsp.nspname = 'public'
  AND  NOT EXISTS (
        SELECT 1 FROM pg_index idx
        WHERE idx.indrelid = con.conrelid AND idx.indkey[0] = con.conkey[1])
ORDER BY referencing_table, fk_name;
```

This is a **leading-column heuristic**, not a full covering-index check —
a composite FK can pass with an index covering only its first column, or
get flagged despite a suitable multi-column index that doesn't lead with
that column; verify composite-key findings by hand.

*Why it matters, concretely* — a documented incident (mydba.dev): a
204M-row `events` table had an unindexed `account_id` FK. Deleting 612
parent rows triggered 612 sequential scans reading ~125 billion tuples; a
job that normally took ~4s ran 42 minutes with user-facing errors. Fix:

```sql
-- Suggested remediation (never applied automatically)
CREATE INDEX CONCURRENTLY idx_events_account_id ON events (account_id);
```

Post-fix, single-row delete FK-trigger time dropped from 48,122.6 ms to
31.4 ms (`CONCURRENTLY` avoided blocking writes; the build itself took
1h52m at this table's size — plan for it). Treat these numbers as one
sourced illustration of the order of magnitude, not a universal threshold
— cost scales with parent-mutation volume × child-table size, which is
what generalizes.

**Duplicate or redundant indexes flagged by advisors.** Both indicate
wasted write/vacuum/WAL cost with no planner benefit lost by dropping the
smaller one — confirm against Indexing findings before double-reporting.

**`timestamp` without time zone on business columns.** PostgreSQL's own
"Don't Do This" wiki page: `timestamp` "just stores a date and time you
give it... a picture of a calendar and a clock rather than a point in
time" — "arithmetic between timestamps from different locations or
between timestamps from summer and winter may give the wrong answer."
`nullable_timestamp_without_tz` catches the nullable case at `info`
severity; a `NOT NULL` `timestamp` on a business-meaningful column
(created-at, occurred-at) carries the same risk and is worth flagging
manually — `run_advisors` doesn't catch that case itself. Fix is always a
type change, never a silent reinterpretation:

```sql
-- Confirm existing values are genuinely UTC before applying — a bare
-- type change reinterprets naive timestamps as the session's timezone.
ALTER TABLE orders
  ALTER COLUMN placed_at TYPE timestamptz USING placed_at AT TIME ZONE 'UTC';
```

**Partition sanity, high-level only** (partitioning tuning itself is a
different domain's altitude). From `list_partitions`' `strategy` and
`bounds`, watch for:

- **No `DEFAULT` partition** on a range/list table taking externally-driven
  values (dates, tenant IDs) — PostgreSQL's docs: a non-matching insert
  "will cause an error" with no default, surfacing as a production insert
  failure rather than a pre-flagged anomaly.
- **A `DEFAULT` partition present but overgrown** from lapsed maintenance
  (next period's partition not pre-created). Attaching a new partition
  while `DEFAULT` exists requires scanning `DEFAULT` under `ACCESS
  EXCLUSIVE` to confirm no rows belong to the new range — unless a `CHECK`
  constraint excluding that range was added to `DEFAULT` first.
- **An apparently-unpartitioned table whose naming implies otherwise**
  (`_2024`, `_archive` siblings with no real `pg_partitioned_table` entry
  tying them together) — Minor note.
- Overlapping ranges are rejected by PostgreSQL itself at creation time —
  can't exist in a live schema, so don't spend review effort re-detecting it.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | `run_advisors` clean everywhere in scope; no missing PKs on mutable tables; every FK has a leading-column-matching index |
| 7–8 | Minor findings only (an `info`-level timestamp hit, one redundant index) — no Important/Critical |
| 5–6 | Multiple missing PKs on real tables, or one or more hot-path FKs unindexed |
| 3–4 | Systemic gaps across core tables, or a no-default-partition insert-failure risk on an actively-written table |
| 1–2 | Foundational integrity absent where the app depends on it (e.g. no PK/unique on an FK target, or `list_foreign_keys` shows a broken/orphaned reference) |

Severity mapping onto Critical/Important/Minor: `missing_primary_key` on a
clearly-mutated table and `unindexed_foreign_key` on a demonstrably hot
path → **Important**; the same two rules on low-traffic/append-only
tables → **Minor**; `duplicate_indexes`/`redundant_indexes` → **Minor**
(cost, not correctness); `nullable_timestamp_without_tz` → **Minor** even
on business-critical columns (footgun, not an active defect). Nothing in
this domain's own tools produces **Critical** on its own — a broken FK
graph found via manual `list_foreign_keys` inspection would be the
exception, and is rare since the tool typically can't resolve one anyway.

## Evidence

Object identity (`schema.table`/`schema.table.column`), the advisor `rule`
id and native severity when from `run_advisors`, the exact query used for
anything found by manual catalog inspection, and a suggested SQL fix as
text — never applied. For FK-without-index, include the FK name and first
referencing column; for a partition finding, include `strategy` and the
specific gap or `DEFAULT`-partition growth observed.

## Sources

- MCPg `src/mcpg/advisors.py` (`run_advisors`, its six rules) — verified
  directly against source, 2026-09-08.
- MCPg `src/mcpg/introspection.py` (`list_constraints`, `list_foreign_keys`,
  `list_partitions`) and `src/mcpg/composite.py` (`summarize_table`) —
  verified directly, 2026-09-08.
- PostgreSQL docs, `pg_constraint` / `pg_index` catalogs — `contype` codes,
  `conkey`/`confkey`, `indkey` leading-column semantics — retrieved
  2026-09-08.
- PostgreSQL docs, Table Partitioning §5.12.2.2 — overlap-at-creation
  error, no-default insert error, `DEFAULT`-partition attach-time
  lock/scan — retrieved 2026-09-08.
- PostgreSQL wiki, "Don't Do This" — guidance against `timestamp without
  time zone` — retrieved 2026-09-08.
- mydba.dev, "Why ON DELETE CASCADE Slows Postgres to a Crawl" — named
  incident behind the worked-example numbers — retrieved 2026-09-08.
- `github.com/mfvanek/pg-index-health` (Java library, v0.41.2, PG14–18)
  and its pure-SQL sibling `pg-index-health-sql` (~47 checks, confirming
  "Tables without a primary key" / "Foreign keys without associated
  indexes" as named industry checks) — retrieved 2026-09-08.
- Full provenance: `research/postgresql-review/schema-integrity.md` (this
  repo).
