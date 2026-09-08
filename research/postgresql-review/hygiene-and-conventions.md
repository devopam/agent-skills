# Hygiene & conventions — research notes

**Retrieved:** 2026-09-08

Deliberately the smallest domain (baseline target: ~60–90 lines authored).
This note exists to give the authored reference doc real citations instead
of memory-based claims, per `00-index.md`'s "deepen references... rather
than inventing thresholds from memory alone."

## Headline findings

1. **Postgres itself is naming-agnostic; the risk is quoting inconsistency,
   not correctness.** Per the official docs, an unquoted identifier is
   always folded to lower case, while a double-quoted identifier is
   case-sensitive and stored as written — so `Foo`, `foo`, and `"foo"` all
   resolve to the same object, but `"Foo"` is a distinct one
   ([PostgreSQL 18 docs, §4.1.1 Identifiers and Key Words](https://www.postgresql.org/docs/current/sql-syntax-lexical.html)).
   The PostgreSQL wiki's "Don't Do This" page draws the practical
   consequence: mixed-case or special-character names force every caller
   (humans, ORMs, migration tools) to either always double-quote or never
   quote, and getting this wrong across a codebase is where real bugs come
   from — not from the naming style itself
   ([wiki.postgresql.org/wiki/Don't_Do_This](https://wiki.postgresql.org/wiki/Don%27t_Do_This)).
   Its recommendation: stick to `a-z`, `0-9`, and `_` so quoting never
   matters. This directly supports the existing doc's framing that naming
   severity is project-dependent (a team-consistency concern) rather than
   a correctness one — now with a citable reason why.

2. **Reserved words are a real, checkable risk, distinct from style.**
   The SQL Key Words appendix lists tokens Postgres reserves outright
   (never usable as unquoted column/table names) versus non-reserved
   words usable in most contexts
   ([PostgreSQL 18 docs, Appendix C](https://www.postgresql.org/docs/current/sql-keywords-appendix.html)).
   A table or column literally named `user`, `order`, `group`, `check`, or
   `references` forces quoting everywhere or breaks unquoted SQL — this is
   a legitimate lint target distinct from "I don't like this casing."

3. **MCPg's own tool descriptions confirm the split this domain needs.**
   From MCPg's `docs/tour.md` "Lint the schema" section (verified via
   `gh api repos/devopam/MCPg/contents/docs/tour.md`, 2026-09-08):
   - `lint_naming_conventions(schema)` — *"snake_case vs camelCase outliers
     + index prefix rule"*. So the tool checks both general
     identifier casing **and** a specific index-naming convention (e.g. an
     expected `idx_`/`ix_`-style prefix), not casing alone.
   - `find_unused_objects(schema)` — *"zero-scan tables and user indexes"*.
     The tool returns **both** object classes in one call: tables with zero
     recorded scans, and indexes with zero recorded scans. It does not
     pre-split them by domain — that split is left to the caller.

   This confirms the dedup rule the task asked to verify: the same tool
   backs two domains only because it returns two different object classes.
   `docs/tools.md`'s capability table lists `find_unused_objects` and
   `lint_naming_conventions` under the "Health, tuning & advisors" group,
   with no per-parameter detail beyond the tour's one-line summaries — so
   the dedup rule below is inferred from the tour description plus the
   domain-baseline's own explicit dual listing (both Indexing and Hygiene
   name `find_unused_objects` in `research/postgresql-review/02-domain-baselines.md`),
   not from a deeper MCPg spec that doesn't exist yet.

4. **The concrete dedup rule to state in the reference doc:** when
   `find_unused_objects` returns zero-scan **indexes**, that's an Indexing
   finding (write/vacuum/WAL carrying cost of a structure nobody reads —
   see `references/indexing.md`). When it returns zero-scan **tables**,
   that's a Hygiene finding (schema clutter, unclear ownership, ops
   confusion — no write-cost angle implied). An agent running both domains
   in one review must not list the same zero-scan index twice under both
   headings.

5. **"Noise objects in production schemas"** — no external citation needed;
   this is the baseline's own framing plus ordinary practice. Concretely:
   tables/views suffixed `_backup`, `_bak`, `_old`, `_tmp`, `_test`,
   `_copy`, or dated (`orders_20240101`) that persist in a schema alongside
   live objects; objects with no FK relationships and no app-role grants
   that nothing else in the schema references. These are low-risk to flag
   (Minor) precisely because they cost storage/vacuum/catalog-scan
   attention rather than correctness.

## Out of scope (per baseline, unchanged)

Enforcing one corporate naming standard without user context. The domain
flags outliers and inconsistency, not a specific "correct" style — a team
that consistently uses e.g. Pascal-ish quoted identifiers throughout is
internally consistent even if it fights Postgres's default folding.

## Sources

- [PostgreSQL 18 docs — §4.1.1 Identifiers and Key Words](https://www.postgresql.org/docs/current/sql-syntax-lexical.html) — case folding of unquoted vs. quoted identifiers. Retrieved 2026-09-08.
- [PostgreSQL wiki — "Don't Do This"](https://wiki.postgresql.org/wiki/Don%27t_Do_This) — practical case against mixed-case/quoted identifiers. Retrieved 2026-09-08.
- [PostgreSQL 18 docs — Appendix C, SQL Key Words](https://www.postgresql.org/docs/current/sql-keywords-appendix.html) — reserved vs. non-reserved key words. Retrieved 2026-09-08.
- MCPg `docs/tour.md`, "Lint the schema" section — one-line tool descriptions for `lint_naming_conventions` and `find_unused_objects`, verified via `gh api repos/devopam/MCPg/contents/docs/tour.md`. Retrieved 2026-09-08.
- MCPg `docs/tools.md`, capability-gate table — confirms both tools are `read` mode under "Health, tuning & advisors"; no deeper per-tool spec found there for these two. Retrieved 2026-09-08.
- `research/postgresql-review/02-domain-baselines.md` §7 — existing baseline scope statement (unchanged, cross-checked here).
