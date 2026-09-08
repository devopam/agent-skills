# Hygiene & conventions

## Intent

Naming outliers and unused clutter — low blast radius but real ops cost
(extra objects to reason about, catalog/backup noise, onboarding confusion).
Deliberately the lightest domain: most findings are Minor, and the goal is
flagging inconsistency and dead weight, not enforcing one "correct" style.

## MCPg tools

`lint_naming_conventions(schema)` — per MCPg's own tool tour, reports
"snake_case vs camelCase outliers + index prefix rule": casing **and** a
naming convention for index names (e.g. an expected `idx_`/`ix_`-style
prefix).

`find_unused_objects(schema)` — reports "zero-scan tables and user
indexes". One call returns both object classes; see the dedup rule below
for how to split its output across domains.

## What to look for

- **Casing/style outliers.** A schema that's mostly `snake_case` with a
  few `camelCase` or `PascalCase` tables/columns mixed in. Postgres folds
  unquoted identifiers to lower case and treats quoted ones as
  case-sensitive, so mixed casing usually means someone had to
  double-quote a name to preserve it — a real quoting-consistency cost,
  not just an aesthetic one.
- **Reserved-word collisions.** Tables/columns literally named `user`,
  `order`, `group`, `check`, `references`, etc. force quoting everywhere
  they're used. Flag as a naming outlier, not a schema-integrity bug.
- **Noise objects in production schemas** — concretely: tables or views
  suffixed `_backup`, `_bak`, `_old`, `_tmp`, `_test`, `_copy`, or
  date-stamped (`orders_20240101`) that persist alongside live objects;
  objects with no FK references and no app-role grants that nothing else
  in the schema touches. These are classic leftovers from a migration or
  a one-off investigation that never got dropped.
- **Index naming convention drift** — indexes that don't follow whatever
  prefix/suffix pattern the rest of the schema uses (surfaced directly by
  `lint_naming_conventions`'s index-prefix check).
- **Unused *tables*** from `find_unused_objects` — zero-scan tables with
  no evident purpose. This is a clutter/ops-confusion finding, not a
  performance one.

### Dedup rule vs. Indexing (important — read before scoring)

`find_unused_objects` returns **both** zero-scan tables and zero-scan
indexes in a single call. Split its output by object type, not by tool:

- Zero-scan **indexes** → belongs to **Indexing**
  (`references/indexing.md`). The angle there is write/vacuum/WAL cost: an
  unused index still slows every insert/update and adds vacuum work.
- Zero-scan **tables** → belongs to **Hygiene**. The angle here is schema
  clutter and ops confusion: nobody queries it, but it isn't costing
  writes the way an unused index does.

Never list the same zero-scan index under both domains. If you're unsure
which bucket a finding belongs in, ask "does dropping this reduce write/
vacuum cost (Indexing) or just remove visual clutter (Hygiene)?"

## Worked example

`find_unused_objects` returns `orders_backup_2024` (0 scans, 40k rows) and
index `ix_orders_status_old` (0 scans, 1.2 GB) in the same call.

- **Hygiene (Minor):** `orders_backup_2024` — abandoned backup table, no
  FKs or app-role grants reference it. Suggest confirming with the owning
  team, then `DROP TABLE orders_backup_2024;`.
- **Indexing, not Hygiene (Minor–Important by size/write rate):**
  `ix_orders_status_old` — zero scans, non-trivial size; suggest
  `DROP INDEX CONCURRENTLY ix_orders_status_old;` after confirming no code
  path relies on it. Reported once, under Indexing only.

## Scoring guide

| Score | Guide |
|------:|-------|
| 9–10 | Clean, consistent conventions; no leftover clutter found |
| 7–8 | A few casing/reserved-word outliers or one or two stale objects |
| 5–6 | Widespread inconsistency, or several obviously abandoned objects |
| 1–4 | Rare for hygiene alone — reserve for extreme, schema-wide clutter |

Most hygiene findings are **Minor**. Naming-convention severity is
project-dependent: a team that's internally consistent (even if it fights
Postgres's default folding) shouldn't be marked down for not matching an
external style guide — flag inconsistency and collisions, not a
particular preferred style.

Out of scope: enforcing one corporate naming standard without user
context; renaming production objects (suggest only — never apply DDL).

## Sources

- [PostgreSQL 18 docs — §4.1.1 Identifiers and Key Words](https://www.postgresql.org/docs/current/sql-syntax-lexical.html) — unquoted identifiers fold to lower case, quoted ones are case-sensitive. Retrieved 2026-09-08.
- [PostgreSQL wiki — "Don't Do This"](https://wiki.postgresql.org/wiki/Don%27t_Do_This) — practical cost of mixed-case/quoted identifiers, recommends `a-z`/`0-9`/`_`. Retrieved 2026-09-08.
- [PostgreSQL 18 docs — Appendix C, SQL Key Words](https://www.postgresql.org/docs/current/sql-keywords-appendix.html) — reserved vs. non-reserved key words. Retrieved 2026-09-08.
- MCPg `docs/tour.md` ("Lint the schema" section) and `docs/tools.md` (capability-gate table) — tool behavior for `lint_naming_conventions` and `find_unused_objects`, verified via `gh api repos/devopam/MCPg/contents/docs/...`. Retrieved 2026-09-08.
- Full detail: `research/postgresql-review/hygiene-and-conventions.md`.
