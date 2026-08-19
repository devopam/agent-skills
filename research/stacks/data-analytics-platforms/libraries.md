# Baseline: Data & Analytics Platforms — Preferred Libraries
Status: user-approved      Date: 2026-08-19      Snapshot date: 2026-08-19

This is the companion library-pick baseline to `stack.md` (architecture/
patterns, already authored). It assumes that doc's conclusions — ELT as
default, lakehouse-with-open-table-format as the 2025-2026 consensus
default, DAG orchestration as the default with event-triggering layered on,
data quality checks wired at three specific pipeline points, unit tests +
data tests as complementary testing layers — and names the concrete
tool for each slot. All license/star/commit figures below were verified by
direct fetch (GitHub REST API, raw LICENSE files, or PyPI JSON) on
2026-08-19, not taken from secondary blog aggregation, except where
explicitly flagged otherwise.

**Note for the author of the target skill doc**: this baseline carries one
global snapshot date for research-pass convenience. The authored doc
itself should give each entry its own "last reviewed" date rather than
inheriting a single shared date — otherwise every entry re-ages together
at the next review even though (as this pass found directly) different
tools in this category are moving at very different speeds: dbt and Great
Expectations changed license/ownership terms multiple times within the
same ~12-month window this research covered, while Airflow/pandas/Apache
Superset did not.

## In scope

- **Dataframe/processing libraries: pandas vs. polars vs. DuckDB, with a
  concrete decision rule, not a "polars is faster" hand-wave** — impact:
  high — depth: section.

  | Library | License | GitHub stars (verified 2026-08-19) | Monthly PyPI downloads (pypistats.org, verified 2026-08-19) |
  |---|---|---|---|
  | **pandas** | BSD-3-Clause | 49,519 | ~796M |
  | **polars** | MIT | 39,394 | ~79M |
  | **DuckDB** | MIT | 40,430 | (embedded engine, not a dataframe lib — see below) |

  The download gap (~10x) is a real signal but needs the caveat stated
  plainly: PyPI download counts are install *events*, heavily inflated for
  pandas by the thousands of downstream packages that pull it in
  transitively (it is the ecosystem's default dependency, not necessarily
  10x more teams' primary tool of choice) — this figure supports
  "pandas remains the ecosystem default," not a literal 10x usage-intensity
  claim. Star growth is the cleaner momentum signal — pandas (49.5k stars)
  is a much older project than polars (39.4k stars, within ~10k of pandas
  despite starting later; exact founding dates not independently verified
  this pass and not stated as fact here), and it points the same direction
  search-level sources converged on independently: polars is the
  fastest-growing alternative, not yet the
  incumbent.

  **Decision rule for this skill's authored doc**: default to **pandas**
  for compatibility — it remains the lingua franca that the widest range of
  other libraries (plotting, ML, BI-tool connectors, notebook tooling)
  accept natively without a conversion step, and for datasets that
  comfortably fit in memory the ergonomics/ecosystem win outweighs the
  performance gap. Switch to **polars** specifically when at least one of
  these holds: (1) the dataset doesn't comfortably fit in memory and needs
  polars' lazy execution + streaming/out-of-core query engine rather than a
  hand-rolled chunking loop; (2) the pipeline is CPU-bound on
  transformation and polars' native multi-core parallelism (pandas is
  single-threaded by default) meaningfully changes wall-clock time; (3) the
  team is starting a genuinely new pipeline with no existing pandas-specific
  dependency chain to preserve — greenfield is the cheapest time to pick the
  faster default. Do not migrate an existing working pandas pipeline to
  polars on performance grounds alone without first profiling — the
  migration cost (API differences: no index, different mutation semantics)
  is real and unforced-conversion is a common false-economy mistake teams
  report.

  **DuckDB is a different category — an in-process OLAP SQL engine, not a
  dataframe library** — worth naming explicitly since it's easy to lump in
  with pandas/polars. Its concrete fit here: (1) it queries Parquet/CSV/
  Iceberg/Delta files directly with SQL, with no server to stand up, making
  it the natural tool for the notebook-to-production exploration phase
  (stack.md's guidance) and for local dev/CI testing of a pipeline stage
  without provisioning a real warehouse; (2) both polars and pandas
  interoperate with it via Arrow with zero-copy handoff, so it composes
  with either rather than competing; (3) dbt has a DuckDB adapter, making it
  a legitimate lightweight target for dbt development/testing before
  pointing the same project at a production warehouse.

- **Orchestration: Airflow vs. Dagster vs. Prefect — current maturity/
  license/adoption, with the decision keyed to team shape and mental
  model, not a feature checklist** — impact: high — depth: table + section.

  | Tool | License | GitHub stars | Forks | Governance | What it's for |
  |---|---|---|---|---|---|
  | **Apache Airflow** | Apache-2.0 | 46,536 | 17,619 | Apache Software Foundation top-level project | Task-based DAG orchestration; the incumbent |
  | **Dagster** | Apache-2.0 (core repo) | 16,025 | 2,247 | Dagster Labs (VC-backed company); Dagster+ is a separate commercial hosted offering, not asserted here to carry a different OSS license | Asset-based orchestration (software-defined data assets, not just tasks) |
  | **Prefect** | Apache-2.0 (confirmed via direct LICENSE fetch; copyright Prefect Technologies, Inc.) | 23,642 | 2,470 | Prefect (VC-backed company); Prefect Cloud is a separate commercial hosted offering | Lightweight, Python-native (decorator-based) workflow orchestration |

  All three are permissively licensed for the open-source core as of this
  snapshot. Prefect is worth a specific licensing note since, like dbt and
  Great Expectations, this category has moved licenses before: Prefect's
  server/UI briefly used a non-OSI "Prefect Community License" in the
  Prefect 1.x era before the project consolidated on Apache-2.0 for
  Prefect 2.0+ — the LICENSE file at `main` today is unambiguously
  Apache-2.0, but this is a category where re-checking at authoring time
  (not just trusting this pass) is the right habit, per the task's own
  instruction.

  **Decision rule**: **Airflow** is the safe default when the deciding
  factor is ecosystem breadth — it is the oldest and most widely deployed
  of the three (star count and fork count both lead by a wide margin,
  meaning the widest range of third-party tools ship an Airflow
  operator/provider first) and is the most likely to have institutional
  buy-in already in a larger organization. **Dagster** is the better fit
  when a team is starting fresh and wants to think in terms of *data
  assets* (a table, a file, a model) as the unit of orchestration rather
  than *tasks* — this maps directly onto stack.md's notebook-to-production
  guidance (extract validated notebook logic into a typed function that
  produces a named asset) and its layered bronze/silver/gold framing more
  naturally than a pure task-DAG does; it also supports direct in-process
  testing of individual assets (confirmed via Dagster's own docs: an
  asset is invocable as a plain Python function with test inputs and
  mocked resources, and `job.execute_in_process()` covers multi-asset
  integration-style tests), which matters for the unit-test layer
  described below. **Prefect** is the better fit for a smaller team or a
  simpler pipeline set that wants to avoid Airflow's configuration/
  deployment overhead — plain Python functions decorated as flows/tasks,
  and a notably lighter local dev loop, at the cost of a smaller
  operator/integration ecosystem than Airflow's.

- **Transformation layer: dbt — current licensing state is genuinely
  mid-transition, and the authored doc needs to say so rather than pick
  one snapshot and present it as settled** — impact: high — depth: section.
  This is the single most load-bearing licensing check in this pass, since
  the task named dbt explicitly as a project with licensing history.

  **What's stable and safe to state as fact**: `dbt-core` (the package a
  project actually installs — `pip install dbt-core`) is Apache-2.0 and has
  been since 2016, confirmed by direct GitHub API fetch (13,663 stars,
  2,510 forks, not archived) and by dbt Labs' own licensing FAQ page
  (direct fetch: "dbt Core... is completely open source. Its code and
  binary are subject to the Apache 2.0 license"). **What's in flux, stated
  precisely rather than glossed**: dbt Labs shipped a separate, faster
  Rust-based execution engine called **dbt Fusion** as a public beta in May
  2025 under the **Elastic License v2** (source-available, not OSI-approved
  — restricts running it as a competing hosted service) — a genuine
  license-tightening move worth naming as precedent for this category's
  volatility. On June 1, 2026 dbt Labs announced **dbt Core v2**, which
  merges the Fusion engine's Rust runtime *source* back into the
  `dbt-core` repository under Apache-2.0 — so the underlying engine code
  is open again — while the *distributed Fusion binary itself* (the
  compiled artifact with premium, login-gated features) is now governed by
  a separate "dbt Product Licensing Agreement" that is still proprietary,
  just less restrictive than the ELv2 predecessor (no explicit
  anti-competitive-hosting clause, but premium features remain
  gated behind authentication). These are two different things under two
  different terms — engine *source in dbt-core* is Apache-2.0; the
  *premium Fusion binary distribution* is a proprietary commercial
  agreement — and conflating them would misstate the actual position.
  **Practical, version-less mandate for the authored doc**: install and
  build on `dbt-core` (Apache-2.0) as the default — direct PyPI fetch
  confirms the latest released, installable version as of this snapshot is
  the 1.12.x line (1.12.2); dbt Core v2 was announced as an alpha release
  June 1, 2026 and had not shipped a stable PyPI release as of this
  snapshot (Aug 19, 2026) — so "dbt Core, 1.x today, with a Rust-engine
  v2 in alpha" is the accurate, non-version-pinned framing, and the doc
  should flag re-checking v2's stable-release status at authoring time
  given how recent this transition is. `dbt Cloud`/`dbt Platform` (the
  hosted product) remains separately proprietary/commercial and is out of
  scope for a "preferred open-source library" recommendation.

- **Lakehouse table-format Python libraries — the concrete package a
  project actually installs, one layer more specific than stack.md's
  format-choice discussion** — impact: med — depth: table. stack.md
  already made the Iceberg-vs-Delta architectural call (Iceberg: safer
  neutral default; Delta: better fit already-on-Databricks); this entry
  names the Python-facing libraries and flags a real maturity gap between
  them that matters for a Python-first project.

  | Library | For | License | Stars (verified) | Note |
  |---|---|---|---|---|
  | Apache Iceberg (format/spec) | Table format | Apache-2.0 | 9.2k (per stack.md, same-day verification, reused here rather than re-fetched to avoid the two docs drifting) | ASF top-level project |
  | `pyiceberg` | Python read/write client for Iceberg | Apache-2.0 | 1,118 (verified 2026-08-19) | Materially thinner than the Java/Spark-side Iceberg ecosystem — a real maturity gap worth flagging, not just a smaller-number footnote; expect gaps vs. Spark-based Iceberg tooling for advanced write patterns |
  | Delta Lake (format/spec) | Table format | Apache-2.0 | 8.9k (per stack.md, reused here) | Best integrated with Databricks/Spark |
  | `deltalake` (delta-rs) | Native Rust engine with Python bindings for Delta Lake | Apache-2.0 | 3,284 (verified 2026-08-19) | More mature/more capable from plain Python (no Spark/JVM dependency required) than `pyiceberg` is for Iceberg at this snapshot |

  **Practical note for a Python-first, non-Spark project**: `deltalake`
  (delta-rs) currently offers a more complete pure-Python read/write
  experience than `pyiceberg` does for Iceberg — worth weighing against
  stack.md's format-neutrality argument specifically when the team has no
  Spark/JVM infrastructure and wants to read/write table-format files
  directly from Python/polars/pandas without standing up a Spark cluster.

- **Data validation: Great Expectations (GX Core) and Pandera — GX's
  ownership/stewardship is mid-transition right now, verified directly
  rather than assumed stable** — impact: high — depth: section. This is
  the second major licensing/status finding of this pass and needed a
  second verification round after an initial pass understated it.

  **Great Expectations / GX Core**: License confirmed by direct fetch of
  the raw `LICENSE` file at `great-expectations/great_expectations`
  (`main` branch) — Apache License, Version 2.0, unambiguous. GitHub:
  11,719 stars, 1,798 forks. **Ownership is actively changing as of this
  snapshot**: GX's own blog post (fetched directly, dated May 6, 2026)
  states Great Expectations and FICO completed an agreement for FICO to
  acquire **GX Cloud** (the commercial SaaS product) and fold it into the
  FICO platform — GX Cloud stops being publicly available starting June 1,
  2026. Separately, **Fivetran becomes the new steward of GX Core**, the
  open-source project this recommendation actually concerns — the blog
  states GX Core "will continue as an open source, community-driven
  project" under Fivetran's stewardship. The open-issue count (28) on an
  11.7k-star repo is unusually low compared to peers of similar size in
  this doc (Pandera: 443 open issues; Dagster: 2,596) — checked directly
  rather than taken as a red flag at face value: commit history shows
  active, near-daily commits through August 19, 2026 (the date of this
  snapshot), so the low issue count reads as a triage/bulk-close artifact
  around the ownership transition, not evidence of a maintenance stall —
  but this is exactly the kind of transition where re-verifying commit
  cadence a few months out, before finalizing the skill's guidance, is
  warranted rather than optional. **Practical mandate**: GX Core (the
  open-source validation library, Apache-2.0) remains a reasonable
  recommendation today; do not recommend GX Cloud (being discontinued);
  flag in the authored doc that GX's stewardship changed hands in mid-2026
  and is worth a fresh check before the skill ships.

  **Pandera**: MIT license (confirmed via PyPI JSON metadata — OSI-approved
  MIT classifier), 4,436 stars, 434 forks, latest release 0.32.1. Now
  maintained under the `unionai-oss` GitHub org (Union.ai) rather than an
  independent maintainer — a real, checkable maintenance-continuity signal
  (corporate backing rather than a single-maintainer bus-factor risk).
  Pandera validates pandas/polars/PySpark DataFrames via Python type hints
  or a schema-class API, runs in-process (no external service), and is
  meaningfully lighter-weight than GX for the specific case of validating
  a DataFrame already in memory mid-pipeline.

  **Decision rule, tied directly to stack.md's three-enforcement-point
  architecture**: use **Pandera** for validation that lives *inside*
  Python transformation code (the unit-test-adjacent, in-memory checks at
  stack.md's between-stage enforcement point, e.g. inside a Dagster asset
  or a Prefect task) — it is lightweight, fast, and expressed as ordinary
  Python. Use **GX Core** for validation that needs to run against data
  already landed in a warehouse/lake, wants a shareable
  human-readable expectation suite independent of a specific pipeline
  script, or needs GX's built-in profiling/data-docs output as an
  artifact reviewers can read. The two are not mutually exclusive — a
  pipeline commonly uses Pandera at the in-code transformation boundary
  and GX (or plain warehouse-native `dbt test` assertions) at the
  landed-data boundary.

- **The unit-test layer stack.md's testing table explicitly deferred here
  ("library/tool names for both layers live in libraries.md") — closing
  that forward reference** — impact: med — depth: paragraph. For the
  Python-side unit-test layer (testing a transformation function against
  fixture input, independent of any live warehouse), **pytest** (MIT
  license, 14,429 stars, verified 2026-08-19; the de facto standard Python
  test runner, used the same way here as in every other baseline in this
  repo) is the tool — nothing category-specific beyond ordinary pytest
  usage against plain functions extracted per stack.md's notebook-to-
  production guidance. For the SQL/dbt-model side, dbt's **built-in unit
  testing** (introduced in dbt Core v1.8, confirmed via direct fetch of
  dbt's own docs; run via `dbt test --select "test_type:unit"`, or scoped
  to one model with `dbt test --select "model_name,test_type:unit"` —
  there is no separate `dbt unit_test` command; unit tests are a selector
  on the ordinary `dbt test` command, distinguished from data tests by the
  `test_type` selector, and dbt Labs' own docs recommend running them in
  dev/CI only, not against production builds) is the dbt-native equivalent
  stack.md already named at the architecture level — no separate library
  to install, since it ships inside `dbt-core` itself.

- **BI/visualization — one default for this skill's likely audience,
  named plainly, with the others keyed to specific named conditions
  rather than presented as four coequal options** — impact: high — depth:
  section.

  | Tool | License | Stars | Forks | Model |
  |---|---|---|---|---|
  | Apache Superset | Apache-2.0 | 74,311 | 18,127 | ASF top-level project |
  | Metabase | Dual: AGPL-3.0 (core, outside `enterprise/`) + proprietary Metabase Commercial License (`enterprise/` dir) — confirmed via direct fetch of `LICENSE.txt`, not the GitHub API's summary field | 48,831 | 6,750 | Company-backed (Metabase, Inc.) |
  | Lightdash | Dual: MIT (core) + proprietary (`packages/backend/src/ee/`) — confirmed via direct fetch of `LICENSE` | 6,056 | 767 | Company-backed; dbt-native (reads dbt-defined metrics) |
  | Evidence | MIT | 6,862 | 394 | Company-backed; "BI as code" — SQL + Markdown reports, git-versioned, no drag-drop canvas |

  **Default recommendation for this skill's audience** (a project just
  incubating a data platform, per the shared framing across this repo's
  baselines): **Apache Superset** when the team wants a full, mature,
  self-hosted BI platform with the broadest connector/chart-type coverage
  and no per-seat licensing question to resolve (Apache-2.0, no dual-
  license carve-out) — it is also, by a wide margin, the most-starred
  tool in this table, the clearest incumbent among purely open options.

  **The one licensing discriminator worth foregrounding, verified
  directly rather than inferred from the GitHub API's unreliable
  `license` summary field**: Metabase's core is **AGPL-3.0**, not a
  permissive license — the practical trigger is *how* it's deployed, not
  whether it's used at all. Running Metabase internally (employees only,
  self-hosted, never modified-and-redistributed-as-a-service to external
  users) does not trigger AGPL's network-copyleft obligations in the way
  that matters for most teams. It becomes a real question the moment a
  team modifies Metabase and offers it (or a derivative) as a hosted
  service to *external* users/customers — AGPL's source-disclosure
  obligation extends over the network in that case, unlike GPL. This is a
  practical characterization for the authored doc's own decision-making,
  not a substitute for actual legal review before a real redistribution
  decision: **internal-only self-hosting → AGPL is a non-issue;
  embedding/redistributing Metabase (or a fork of it) as part of a
  product offered to outside users → AGPL's obligations bite, and either
  compliance or Metabase's commercial license is required.** Lightdash's
  core is plain MIT (only its enterprise-feature directory is
  proprietary), which is the more permissive choice of the two dashboard
  tools if the AGPL question is itself a blocker.

  **Named condition for reaching for Lightdash or Evidence instead of
  Superset**: when the team's transformation layer is already dbt-based
  (this doc's default per the dbt section above) and they want metrics/
  charts defined *as code, versioned in the same git repo as the dbt
  project* rather than point-and-click in a separate BI server — Lightdash
  reads metric definitions directly from dbt's own YAML, and Evidence
  builds reports from SQL+Markdown files reviewed the same way a pull
  request is. This is a smaller (6-7k star), more recent, more
  opinionated pick than Superset/Metabase, appropriate specifically for a
  team that has already bought into "everything as code" (which is the
  same ethos stack.md's notebook-to-production section argues for) rather
  than a general-purpose default.

## Explicitly out of scope

- **Ingestion/EL connector tooling** (Airbyte, Meltano, `dlt`/`dlthub`) —
  stack.md names Airbyte in passing as an example connector-swap point for
  the hexagonal-boundary argument, but a full EL-tool comparison (Airbyte
  vs. Meltano vs. `dlt`, self-hosted vs. cloud, connector-catalog breadth)
  was not researched this pass and would be a natural next slot in this
  same libraries.md if the skill's scope grows to cover it.
- **Streaming-engine libraries** (Kafka client libraries, Flink, Spark
  Structured Streaming) — matches stack.md's own scoping to the sibling
  Integration & Event-Driven Systems baseline; not revisited here.
- **ML/feature-store/experiment-tracking libraries** (Feast, MLflow,
  Weights & Biases) — matches stack.md's exclusion to the separate MLOps
  roadmap category.
- **Cloud data-warehouse platform comparison** (Snowflake vs. BigQuery vs.
  Redshift vs. Databricks SQL) — these are managed platforms, not
  installable open-source libraries, and pricing/vendor comparison is
  explicitly out of scope per this repo's no-pricing convention (also
  stated in stack.md).
- **Spark/PySpark itself** as a distributed processing engine — genuinely
  adjacent to the dataframe-library question but a materially larger
  research topic (cluster-based distributed compute vs. single-node
  dataframe libraries is a different axis than pandas-vs-polars) than this
  pass had room for; flagged as an open question below rather than silently
  omitted.
- **Data catalog/governance/lineage tooling** (OpenMetadata, DataHub,
  Amundsen) — matches stack.md's own out-of-scope call on deep
  catalog/governance-platform comparison.

## Sources

- https://api.github.com/repos/pola-rs/polars — direct fetch: MIT, 39,394
  stars, 3,028 forks — retrieved 2026-08-19
- https://api.github.com/repos/pandas-dev/pandas — direct fetch: BSD-3,
  49,519 stars, 20,280 forks — retrieved 2026-08-19
- https://api.github.com/repos/duckdb/duckdb — direct fetch: MIT, 40,430
  stars, 3,582 forks — retrieved 2026-08-19
- https://pypistats.org/api/packages/polars/recent and
  https://pypistats.org/api/packages/pandas/recent — direct fetch: ~79M
  and ~796M monthly PyPI downloads respectively — retrieved 2026-08-19
  (primary source used instead of a secondary aggregator's conflicting,
  materially lower figures found via WebSearch and explicitly discarded)
- https://api.github.com/repos/apache/airflow — direct fetch: Apache-2.0,
  46,536 stars, 17,619 forks — retrieved 2026-08-19
- https://api.github.com/repos/dagster-io/dagster — direct fetch:
  Apache-2.0, 16,025 stars, 2,247 forks — retrieved 2026-08-19
- https://api.github.com/repos/PrefectHQ/prefect and
  https://raw.githubusercontent.com/PrefectHQ/prefect/main/LICENSE —
  direct fetch: Apache-2.0 confirmed via LICENSE file (not just API
  summary field), 23,642 stars, 2,470 forks — retrieved 2026-08-19
- https://api.github.com/repos/dbt-labs/dbt-core — direct fetch:
  Apache-2.0, 13,663 stars, 2,510 forks, not archived — retrieved
  2026-08-19
- https://www.getdbt.com/licenses-faq — direct fetch: dbt Core Apache-2.0
  "indefinitely," dbt Fusion licensing history (ELv2 → dbt Product
  Licensing Agreement as of June 1, 2026) — retrieved 2026-08-19
- https://docs.getdbt.com/blog/dbt-core-v2-is-here — direct fetch: dbt
  Core v2 announced June 1, 2026 as alpha, Rust/Fusion engine merged into
  dbt-core under Apache-2.0, dbt Product Licensing Agreement governs the
  distributed premium Fusion binary — retrieved 2026-08-19
- https://pypi.org/pypi/dbt-core/json — direct fetch: latest released
  version 1.12.2, no stable 2.0.x release as of this snapshot —
  retrieved 2026-08-19
- https://api.github.com/repos/apache/iceberg-python and
  https://api.github.com/repos/delta-io/delta-rs — direct fetch:
  `pyiceberg` Apache-2.0, 1,118 stars; `deltalake`/delta-rs Apache-2.0,
  3,284 stars — retrieved 2026-08-19
- https://github.com/apache/iceberg and https://github.com/delta-io/delta
  figures (9.2k / 8.9k stars) reused verbatim from stack.md's same-day
  (2026-08-19) direct-fetch verification rather than re-fetched, to avoid
  the two companion docs drifting on the same numbers
- https://api.github.com/repos/great-expectations/great_expectations and
  https://raw.githubusercontent.com/great-expectations/great_expectations/main/LICENSE
  — direct fetch: Apache-2.0 confirmed via LICENSE file, 11,719 stars,
  1,798 forks, 28 open issues — retrieved 2026-08-19
- https://github.com/great-expectations/great_expectations/commits/develop
  — direct fetch: near-daily commit activity through 2026-08-19, used to
  contextualize the low open-issue count as a triage artifact rather than
  a maintenance stall — retrieved 2026-08-19
- https://greatexpectations.io/blog/an-update-from-great-expectations/ —
  direct fetch, dated May 6, 2026: FICO acquisition of GX Cloud (public
  availability ends June 1, 2026), Fivetran becomes GX Core's open-source
  steward — retrieved 2026-08-19
- https://api.github.com/repos/unionai-oss/pandera and
  https://pypi.org/pypi/pandera/json — direct fetch: MIT license
  (confirmed via PyPI classifier), 4,436 stars, 434 forks, latest release
  0.32.1, maintained under the unionai-oss (Union.ai) org — retrieved
  2026-08-19
- https://api.github.com/repos/pytest-dev/pytest — direct fetch: MIT,
  14,429 stars, 3,307 forks — retrieved 2026-08-19
- https://api.github.com/repos/apache/superset — direct fetch: Apache-2.0,
  74,311 stars, 18,127 forks — retrieved 2026-08-19
- https://api.github.com/repos/metabase/metabase and
  https://raw.githubusercontent.com/metabase/metabase/master/LICENSE.txt
  — direct fetch: dual AGPL-3.0 (core) / proprietary Metabase Commercial
  License (`enterprise/` dir), confirmed via LICENSE file text (GitHub
  API's own `license` field incorrectly returns "Other/NOASSERTION" for
  this repo and was not relied on) — 48,831 stars, 6,750 forks —
  retrieved 2026-08-19
- https://api.github.com/repos/lightdash/lightdash and
  https://raw.githubusercontent.com/lightdash/lightdash/main/LICENSE —
  direct fetch: dual MIT (core) / proprietary (`packages/backend/src/ee/`),
  confirmed via LICENSE file text (API field also returns
  "Other/NOASSERTION") — 6,056 stars, 767 forks — retrieved 2026-08-19
- https://api.github.com/repos/evidence-dev/evidence — direct fetch: MIT,
  6,862 stars, 394 forks — retrieved 2026-08-19

## Open questions for the user

- **dbt Core v2's stable-release timing** was out of reach for this pass
  (alpha as of June 1, 2026, still 1.x-only on PyPI as of Aug 19, 2026) —
  the authored doc should state "1.x today, v2/Rust engine in alpha, watch
  for stable release" rather than a fixed claim, and this is worth a fresh
  PyPI check at actual authoring time given how fast this specific area is
  moving (three license/architecture changes in about 12 months: ELv2
  Fusion beta → dbt Core v2 announcement → Apache-2.0 merge, plus GX's
  ownership transition, both in the same research window).
- **GX Core's post-Fivetran-stewardship trajectory** is confirmed stable
  and Apache-2.0 as of this snapshot, with active daily commits, but the
  ownership handoff is only ~3.5 months old (announced May 6, 2026) as of
  this research date — worth a fresh maintenance-cadence check
  immediately before the skill ships rather than trusting this snapshot to
  still hold by then.
- **Spark/PySpark** was flagged as out of scope for space reasons rather
  than a considered exclusion — confirm whether this skill's audience
  (per its "project incubation" framing, likely smaller/earlier-stage
  projects) is correctly assumed to not need distributed-cluster compute
  guidance, or whether a brief "when you outgrow single-node polars/DuckDB,
  here's the Spark on-ramp" pointer is worth adding even at this skill's
  target scale.
- **BI tool default**: Superset was picked as the single default for
  breadth/no-license-question reasons; confirm that's the right call for
  this skill's actual audience versus Metabase's materially gentler
  onboarding/UX, which some teams may value over Superset's broader but
  more complex feature surface — this is a judgment call between two
  legitimately strong options, not a case where one is objectively
  better.
- Should the two companion docs (`stack.md` and this one) be cross-linked
  more explicitly at authoring time (e.g., this doc's dbt/Iceberg/Delta
  entries pointing back to stack.md's architectural rationale by section
  name) so a reader landing on either doesn't have to guess where the
  other half of the reasoning lives?

## Resolutions (Checkpoint D review, 2026-08-19)

- **dbt Core v2 / GX Core stewardship**: both deferred to a fresh check at
  Phase 2 authoring time, per the standing verify-before-publish policy —
  and per the new 6-month staleness-threshold policy (see
  `research/skill-flow-decisions.md`), the authored entries for both will
  need re-verification well before a typical audit cycle would otherwise
  flag them, given how recent both transitions are.
- **Spark/PySpark**: confirmed out of scope for v1 — flagged as a natural
  future addition to this file (not a new roadmap category) once single-
  node polars/DuckDB guidance proves insufficient for this skill's actual
  audience.
- **BI tool default**: Superset confirmed as the named default (breadth,
  no dual-license question) — matches this repo's established
  opinionated-default convention; Metabase's AGPL trade-off stays
  documented as the alternative.
- **Cross-linking stack.md/libraries.md**: yes, add explicit section-name
  cross-references between the two authored files at Phase 2 authoring
  time.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/data-analytics-platforms.md
  — est. 340–420 lines (7 major entries above; the dbt-licensing and
  GX-stewardship sections are the longest given how much precision the
  "verify, don't assume" mandate required for both, the BI section is
  next-longest given the four-tool table plus the AGPL decision rule).
