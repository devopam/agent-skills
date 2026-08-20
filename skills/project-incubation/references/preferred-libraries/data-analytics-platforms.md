# Data & Analytics Platforms — Preferred Libraries

This is the companion library-pick reference to
[`stacks/data-analytics-platforms.md`](../stacks/data-analytics-platforms.md)
(architecture and patterns). It assumes that document's conclusions — ELT
as default, lakehouse-with-open-table-format as the 2025–2026 consensus
default, DAG orchestration as the default with event-triggering layered on,
data-quality checks wired at three specific pipeline points, unit tests and
data tests as complementary testing layers — and names the concrete tool
for each slot. Each entry below carries its own last-reviewed date rather
than one shared snapshot date, because different tools in this category
move at very different speeds: dbt and Great Expectations changed
license/ownership terms multiple times within the same twelve-month window
this reference was written in, while Airflow, pandas, and Apache Superset
did not. Treat entries with a recent last-reviewed date as more likely to
need a re-check before you rely on them.

## Table of contents

1. [Dataframe/processing libraries](#dataframe-processing-libraries-pandas-vs-polars-vs-duckdb)
2. [Orchestration: Airflow vs. Dagster vs. Prefect](#orchestration-airflow-vs-dagster-vs-prefect)
3. [Transformation layer: dbt](#transformation-layer-dbt)
4. [Lakehouse table-format Python libraries](#lakehouse-table-format-python-libraries)
5. [Data validation: Great Expectations (GX Core) and Pandera](#data-validation-great-expectations-gx-core-and-pandera)
6. [The unit-test layer](#the-unit-test-layer)
7. [BI/visualization](#bi-visualization)
8. [Explicitly out of scope](#explicitly-out-of-scope)
9. [Sources](#sources)

## Dataframe/processing libraries: pandas vs. polars vs. DuckDB

*Last reviewed 2026-08-19.*

| Library | License | GitHub stars | Monthly PyPI downloads |
|---|---|---|---|
| **pandas** | BSD-3-Clause | 49,519 | ~796M |
| **polars** | MIT | 39,394 | ~79M |
| **DuckDB** | MIT | 40,430 | embedded engine, not a dataframe library — see below |

The download gap (roughly 10x) is a real signal but needs its caveat
stated plainly: PyPI download counts are install *events*, heavily
inflated for pandas by the thousands of downstream packages that pull it
in transitively — it's the ecosystem's default dependency, not necessarily
10x more teams' primary tool of choice. Read this figure as supporting
"pandas remains the ecosystem default," not a literal 10x
usage-intensity claim. Star growth is the cleaner momentum signal: pandas
(49.5k stars) is a much older project than polars (39.4k stars, within
~10k of pandas despite starting later), and it points the same direction
independent sources converge on — polars is the fastest-growing
alternative, not yet the incumbent.

**Decision rule**: default to **pandas** for compatibility. It remains the
lingua franca that the widest range of other libraries — plotting, ML,
BI-tool connectors, notebook tooling — accept natively without a
conversion step, and for datasets that comfortably fit in memory the
ergonomics/ecosystem win outweighs the performance gap. Switch to
**polars** specifically when at least one of these holds:

1. The dataset doesn't comfortably fit in memory and needs polars' lazy
   execution plus streaming/out-of-core query engine, rather than a
   hand-rolled chunking loop.
2. The pipeline is CPU-bound on transformation, and polars' native
   multi-core parallelism (pandas is single-threaded by default)
   meaningfully changes wall-clock time.
3. The team is starting a genuinely new pipeline with no existing
   pandas-specific dependency chain to preserve — greenfield is the
   cheapest time to pick the faster default.

Do not migrate an existing working pandas pipeline to polars on
performance grounds alone without first profiling. The migration cost —
API differences: no index, different mutation semantics — is real, and
unforced conversion is a common false-economy mistake teams report.

**DuckDB is a different category: an in-process OLAP SQL engine, not a
dataframe library.** It's worth naming explicitly since it's easy to lump
in with pandas/polars. Its concrete fit here:

- It queries Parquet, CSV, Iceberg, or Delta files directly with SQL, with
  no server to stand up, making it the natural tool for stack.md's
  [notebook-to-production](../stacks/data-analytics-platforms.md#the-notebook-to-production-transition)
  exploration phase, and for local dev/CI testing of a pipeline stage
  without provisioning a real warehouse.
- Both polars and pandas interoperate with it via Arrow with zero-copy
  handoff, so it composes with either rather than competing.
- dbt has a DuckDB adapter, making it a legitimate lightweight target for
  dbt development and testing before pointing the same project at a
  production warehouse.

## Orchestration: Airflow vs. Dagster vs. Prefect

*Last reviewed 2026-08-19.*

| Tool | License | GitHub stars | Forks | Governance | What it's for |
|---|---|---|---|---|---|
| **Apache Airflow** | Apache-2.0 | 46,536 | 17,619 | Apache Software Foundation top-level project | Task-based DAG orchestration; the incumbent |
| **Dagster** | Apache-2.0 (core repo) | 16,025 | 2,247 | Dagster Labs (VC-backed); Dagster+ is a separate commercial hosted offering | Asset-based orchestration — software-defined data assets, not just tasks |
| **Prefect** | Apache-2.0 (confirmed via direct LICENSE fetch) | 23,642 | 2,470 | Prefect (VC-backed); Prefect Cloud is a separate commercial hosted offering | Lightweight, Python-native (decorator-based) workflow orchestration |

All three are permissively licensed for the open-source core as of this
review. Prefect is worth a specific note since, like dbt and Great
Expectations, this category has moved licenses before: Prefect's
server/UI briefly used a non-OSI "Prefect Community License" in the
Prefect 1.x era before the project consolidated on Apache-2.0 for
Prefect 2.0+. The LICENSE file at `main` today is unambiguously
Apache-2.0, but this is a category where re-checking at read time — not
just trusting this entry — is the right habit.

**Decision rule**: **Airflow** is the safe default when the deciding
factor is ecosystem breadth. It's the oldest and most widely deployed of
the three — star count and fork count both lead by a wide margin, meaning
the widest range of third-party tools ship an Airflow operator/provider
first — and is the most likely to have institutional buy-in already in a
larger organization.

**Dagster** is the better fit when a team is starting fresh and wants to
think in terms of *data assets* — a table, a file, a model — as the unit
of orchestration rather than *tasks*. This maps directly onto stack.md's
[notebook-to-production](../stacks/data-analytics-platforms.md#the-notebook-to-production-transition)
guidance (extract validated notebook logic into a typed function that
produces a named asset) and its layered bronze/silver/gold framing more
naturally than a pure task-DAG does. It also supports direct in-process
testing of individual assets — an asset is invocable as a plain Python
function with test inputs and mocked resources, and
`job.execute_in_process()` covers multi-asset integration-style tests —
which matters for the unit-test layer described below.

**Prefect** is the better fit for a smaller team or a simpler pipeline set
that wants to avoid Airflow's configuration/deployment overhead: plain
Python functions decorated as flows/tasks, and a notably lighter local dev
loop, at the cost of a smaller operator/integration ecosystem than
Airflow's.

## Transformation layer: dbt

*Last reviewed 2026-08-20 — re-verified at authoring time per the research
baseline's flag; see "What changed since the research baseline" below.*

`dbt-core` — the package a project actually installs via
`pip install dbt-core` — is Apache-2.0 and has been since 2016, confirmed
by direct GitHub API fetch (13,663 stars, 2,510 forks, not archived) and
by dbt Labs' own licensing FAQ page: "dbt Core... is completely open
source. Its code and binary are subject to the Apache 2.0 license." That
part is stable and safe to state as fact.

What's in flux is worth stating precisely rather than glossed over, since
this is genuinely a mid-transition licensing situation. dbt Labs shipped a
separate, faster Rust-based execution engine called **dbt Fusion** as a
public beta in May 2025 under the **Elastic License v2** — source-
available, not OSI-approved, restricting running it as a competing hosted
service. That was a real license-tightening move, worth naming as
precedent for this category's volatility. On June 1, 2026, dbt Labs
announced **dbt Core v2**, which merges the Fusion engine's Rust runtime
*source* back into the `dbt-core` repository under Apache-2.0 — so the
underlying engine code is open again — while the *distributed Fusion
binary itself* (the compiled artifact with premium, login-gated features)
is now governed by a separate "dbt Product Licensing Agreement" that
remains proprietary, just less restrictive than the ELv2 predecessor (no
explicit anti-competitive-hosting clause, but premium features stay gated
behind authentication). These are two different things under two
different terms: engine *source in dbt-core* is Apache-2.0; the *premium
Fusion binary distribution* is a proprietary commercial agreement.
Conflating them misstates the actual position.

**What changed since the research baseline** (baseline snapshot was
2026-08-19; re-checked 2026-08-20): dbt Core v2 has progressed from alpha
to beta — GitHub shows `v2.0.0-beta.2`, tagged August 18, 2026 — but it is
still a pre-release. `dbt-core` 1.12.2, confirmed via direct PyPI JSON
fetch, remains the latest *stable* released version, with the 1.x line
(down through backported patches on 1.1.x–1.9.x) still receiving
maintenance releases as recently as August 14, 2026. In other words: the
transition is moving, but the practical mandate hasn't changed.

**Practical, version-less mandate**: install and build on `dbt-core`
(Apache-2.0) as the default. As of this review, the latest installable
stable version is the 1.12.x line; dbt Core v2 is in beta, not stable —
re-check PyPI before pinning a version, since this is one of the
fastest-moving pieces of this whole reference. `dbt Cloud`/`dbt Platform`
(the hosted product) remains separately proprietary/commercial and is out
of scope for an open-source library recommendation.

This is the concrete tool underneath stack.md's
[ELT vs. ETL](../stacks/data-analytics-platforms.md#elt-vs-etl) default —
dbt is what "use the warehouse's own compute for transformation" means in
practice — and its built-in unit-testing feature is also the dbt-native
half of [Testing a data pipeline](../stacks/data-analytics-platforms.md#testing-a-data-pipeline),
picked up again below in [The unit-test layer](#the-unit-test-layer).

## Lakehouse table-format Python libraries

*Last reviewed 2026-08-19.*

stack.md's [Data warehouse vs. data lake vs. lakehouse](../stacks/data-analytics-platforms.md#data-warehouse-vs-data-lake-vs-lakehouse)
section already made the Iceberg-vs-Delta architectural call — Iceberg as
the safer neutral default, Delta as the better fit for a team already on
Databricks. This entry names the Python-facing libraries one layer down,
and flags a real maturity gap between them that matters for a Python-first
project.

| Library | For | License | Stars | Note |
|---|---|---|---|---|
| Apache Iceberg (format/spec) | Table format | Apache-2.0 | 9.2k | ASF top-level project |
| `pyiceberg` | Python read/write client for Iceberg | Apache-2.0 | 1,118 | Materially thinner than the Java/Spark-side Iceberg ecosystem — a real maturity gap, not just a smaller-number footnote; expect gaps versus Spark-based Iceberg tooling for advanced write patterns |
| Delta Lake (format/spec) | Table format | Apache-2.0 | 8.9k | Best integrated with Databricks/Spark |
| `deltalake` (delta-rs) | Native Rust engine with Python bindings for Delta Lake | Apache-2.0 | 3,284 | More mature/more capable from plain Python — no Spark/JVM dependency required — than `pyiceberg` is for Iceberg at this snapshot |

**Practical note for a Python-first, non-Spark project**: `deltalake`
(delta-rs) currently offers a more complete pure-Python read/write
experience than `pyiceberg` does for Iceberg. This is worth weighing
against stack.md's format-neutrality argument specifically when the team
has no Spark/JVM infrastructure and wants to read/write table-format
files directly from Python, polars, or pandas without standing up a Spark
cluster — the architecturally "safer" choice (Iceberg) and the
practically smoother choice for a lean Python stack (Delta via
`deltalake`) aren't automatically the same library.

## Data validation: Great Expectations (GX Core) and Pandera

*Last reviewed 2026-08-20 — re-verified at authoring time; GX's
stewardship transition is recent enough that it was checked directly
rather than assumed stable. See "What changed since the research
baseline" below.*

**Great Expectations / GX Core**: license confirmed by direct fetch of the
raw `LICENSE` file at `great-expectations/great_expectations` (`main`
branch) — Apache License, Version 2.0, unambiguous. Ownership changed
hands in 2026: GX's own blog post, dated May 6, 2026, states that Great
Expectations and FICO completed an agreement for FICO to acquire **GX
Cloud** (the commercial SaaS product) and fold it into the FICO platform —
GX Cloud stopped being publicly available June 1, 2026. Separately,
**Fivetran became the new steward of GX Core**, the open-source project
this recommendation actually concerns; the blog states GX Core "will
continue as an open source, community-driven project" under Fivetran's
stewardship.

**What changed since the research baseline** (baseline snapshot was
2026-08-19; re-checked 2026-08-20): the picture is unchanged and, if
anything, more settled. GitHub now shows 11,721 stars (up marginally from
11,719) and 1,798 forks, still Apache-2.0, still not archived, with a push
to `main` as recent as August 19, 2026 — active, ongoing development, not
a maintenance lapse. The open-issue count has continued to drop, from 28
at the baseline snapshot to 23 one day later, consistent with the
baseline's read of it as a triage/bulk-close artifact of the ownership
transition rather than a red flag — a stalled project's open-issue count
doesn't keep falling while commits keep landing. GitHub's own repository
description now reads "maintained by Fivetran," corroborating the blog
post's stewardship claim directly rather than through a secondary source.
No further ownership or licensing announcement has appeared on GX's blog
since the May 6, 2026 post as of this review.

**Practical mandate**: GX Core — the open-source validation library,
Apache-2.0 — remains a reasonable recommendation. Do not recommend GX
Cloud (discontinued). The stewardship transition to Fivetran is real but,
based on both the original and re-verification passes, has not
degraded the project; it's still worth a fresh commit-cadence glance
before leaning on GX Core for anything mission-critical, simply because a
stewardship handoff is exactly the kind of event that can go stale
quietly.

**Pandera**: MIT license, confirmed via PyPI JSON metadata (OSI-approved
MIT classifier), 4,436 stars, 434 forks, latest release 0.32.1. Maintained
under the `unionai-oss` GitHub org (Union.ai) rather than an independent
maintainer — a real, checkable maintenance-continuity signal, corporate
backing rather than a single-maintainer bus-factor risk. Pandera validates
pandas/polars/PySpark DataFrames via Python type hints or a schema-class
API, runs in-process with no external service, and is meaningfully
lighter-weight than GX for the specific case of validating a DataFrame
already in memory mid-pipeline.

**Decision rule, tied directly to stack.md's three-enforcement-point
architecture** (see [Data quality and validation as an architectural concern](../stacks/data-analytics-platforms.md#data-quality-and-validation-as-an-architectural-concern)):
use **Pandera** for validation that lives *inside* Python transformation
code — the unit-test-adjacent, in-memory checks at stack.md's
between-stage enforcement point, e.g. inside a Dagster asset or a Prefect
task. It's lightweight, fast, and expressed as ordinary Python. Use **GX
Core** for validation that needs to run against data already landed in a
warehouse/lake, wants a shareable human-readable expectation suite
independent of a specific pipeline script, or needs GX's built-in
profiling/data-docs output as an artifact reviewers can read. The two
aren't mutually exclusive — a pipeline commonly uses Pandera at the
in-code transformation boundary and GX (or plain warehouse-native
`dbt test` assertions) at the landed-data boundary.

## The unit-test layer

*Last reviewed 2026-08-19.*

This closes the forward reference stack.md's testing table leaves open
("library/tool names for both layers live in libraries.md" — see
[Testing a data pipeline](../stacks/data-analytics-platforms.md#testing-a-data-pipeline)).

For the Python-side unit-test layer — testing a transformation function
against fixture input, independent of any live warehouse — **pytest**
(MIT license, 14,429 stars; the de facto standard Python test runner,
used the same way here as in every other baseline in this repo) is the
tool. Nothing category-specific beyond ordinary pytest usage against plain
functions extracted per stack.md's
[notebook-to-production](../stacks/data-analytics-platforms.md#the-notebook-to-production-transition)
guidance.

For the SQL/dbt-model side, dbt's **built-in unit testing** (introduced in
dbt Core v1.8) is the dbt-native equivalent stack.md already named at the
architecture level — no separate library to install, since it ships
inside `dbt-core` itself. It's run via `dbt test --select "test_type:unit"`,
or scoped to one model with
`dbt test --select "model_name,test_type:unit"` — there's no separate
`dbt unit_test` command; unit tests are a selector on the ordinary
`dbt test` command, distinguished from data tests by the `test_type`
selector. dbt Labs' own docs recommend running them in dev/CI only, not
against production builds.

## BI/visualization

*Last reviewed 2026-08-19.*

One default is named plainly for this skill's likely audience, with the
others keyed to specific named conditions rather than presented as four
coequal options.

| Tool | License | Stars | Forks | Model |
|---|---|---|---|---|
| Apache Superset | Apache-2.0 | 74,311 | 18,127 | ASF top-level project |
| Metabase | Dual: AGPL-3.0 (core, outside `enterprise/`) + proprietary Metabase Commercial License (`enterprise/` dir) | 48,831 | 6,750 | Company-backed (Metabase, Inc.) |
| Lightdash | Dual: MIT (core) + proprietary (`packages/backend/src/ee/`) | 6,056 | 767 | Company-backed; dbt-native — reads dbt-defined metrics |
| Evidence | MIT | 6,862 | 394 | Company-backed; "BI as code" — SQL + Markdown reports, git-versioned, no drag-drop canvas |

Metabase's and Lightdash's dual-license splits are confirmed by direct
fetch of each repo's `LICENSE`/`LICENSE.txt` file, not from GitHub's own
`license` API field, which returns an unhelpful "Other/NOASSERTION" for
both repos.

**Default recommendation for this skill's audience** — a project just
incubating a data platform, per the shared framing across this repo's
baselines — is **Apache Superset**, when the team wants a full, mature,
self-hosted BI platform with the broadest connector/chart-type coverage
and no per-seat licensing question to resolve: Apache-2.0, no dual-license
carve-out. It's also, by a wide margin, the most-starred tool in this
table — the clearest incumbent among purely open options. Superset sits
at the serving layer stack.md's
[architecture patterns](../stacks/data-analytics-platforms.md#how-the-cross-cutting-architecture-patterns-specialize-here)
section describes downstream of the warehouse — the CQRS read model made
consumable to humans.

**The one licensing discriminator worth foregrounding**: Metabase's core
is **AGPL-3.0**, not a permissive license, and the practical trigger is
*how* it's deployed, not whether it's used at all. Running Metabase
internally — employees only, self-hosted, never modified and redistributed
as a service to external users — does not trigger AGPL's network-copyleft
obligations in the way that matters for most teams. It becomes a real
question the moment a team modifies Metabase and offers it (or a
derivative) as a hosted service to *external* users or customers — AGPL's
source-disclosure obligation extends over the network in that case, unlike
GPL. Concretely: **internal-only self-hosting → AGPL is a non-issue;
embedding or redistributing Metabase (or a fork of it) as part of a
product offered to outside users → AGPL's obligations bite, and either
compliance or Metabase's commercial license is required.** This is a
practical characterization for decision-making, not a substitute for
actual legal review before a real redistribution decision. Lightdash's
core is plain MIT — only its enterprise-feature directory is proprietary —
which is the more permissive choice of the two dashboard tools if the
AGPL question is itself a blocker.

**Named condition for reaching for Lightdash or Evidence instead of
Superset**: when the team's transformation layer is already dbt-based
(this document's default per [Transformation layer: dbt](#transformation-layer-dbt)
above) and they want metrics/charts defined *as code, versioned in the
same git repo as the dbt project*, rather than point-and-click in a
separate BI server. Lightdash reads metric definitions directly from
dbt's own YAML; Evidence builds reports from SQL+Markdown files reviewed
the same way a pull request is. Both are a smaller (6–7k star), more
recent, more opinionated pick than Superset/Metabase — appropriate
specifically for a team that has already bought into "everything as code,"
the same ethos stack.md's
[notebook-to-production](../stacks/data-analytics-platforms.md#the-notebook-to-production-transition)
section argues for — rather than a general-purpose default.

## Explicitly out of scope

- **Ingestion/EL connector tooling** (Airbyte, Meltano, `dlt`/`dlthub`) —
  stack.md names Airbyte in passing as an example connector-swap point for
  its hexagonal-boundary argument, but a full EL-tool comparison —
  Airbyte vs. Meltano vs. `dlt`, self-hosted vs. cloud, connector-catalog
  breadth — hasn't been researched. It's a natural next slot in this same
  file if this skill's scope grows to cover it.
- **Streaming-engine libraries** (Kafka client libraries, Flink, Spark
  Structured Streaming) — matches stack.md's own scoping to the sibling
  Integration & Event-Driven Systems reference.
- **ML/feature-store/experiment-tracking libraries** (Feast, MLflow,
  Weights & Biases) — matches stack.md's exclusion to the separate MLOps
  roadmap category.
- **Cloud data-warehouse platform comparison** (Snowflake vs. BigQuery vs.
  Redshift vs. Databricks SQL) — these are managed platforms, not
  installable open-source libraries, and pricing/vendor comparison is
  out of scope per this repo's no-pricing convention (also stated in
  stack.md).
- **Spark/PySpark itself**, as a distributed processing engine. This is
  genuinely adjacent to the dataframe-library question above — cluster-
  based distributed compute versus single-node dataframe libraries is a
  different axis than pandas-vs-polars — but it's a materially larger
  research topic than this pass covered, and is named here as a deliberate
  omission rather than a silent one. It's the natural next addition to
  this file once single-node polars/DuckDB guidance proves insufficient
  for a project's actual scale — not a new roadmap category, just an
  unwritten slot in this one.
- **Data catalog/governance/lineage tooling** (OpenMetadata, DataHub,
  Amundsen) — matches stack.md's own out-of-scope call on deep
  catalog/governance-platform comparison.

## Sources

- [api.github.com/repos/pola-rs/polars](https://github.com/pola-rs/polars) —
  direct fetch: MIT, 39,394 stars, 3,028 forks — retrieved 2026-08-19.
- [api.github.com/repos/pandas-dev/pandas](https://github.com/pandas-dev/pandas) —
  direct fetch: BSD-3, 49,519 stars, 20,280 forks — retrieved 2026-08-19.
- [api.github.com/repos/duckdb/duckdb](https://github.com/duckdb/duckdb) —
  direct fetch: MIT, 40,430 stars, 3,582 forks — retrieved 2026-08-19.
- pypistats.org package stats for `polars` and `pandas` — direct fetch:
  ~79M and ~796M monthly PyPI downloads respectively, used in place of a
  secondary aggregator's conflicting, materially lower figures — retrieved
  2026-08-19.
- [api.github.com/repos/apache/airflow](https://github.com/apache/airflow) —
  direct fetch: Apache-2.0, 46,536 stars, 17,619 forks — retrieved
  2026-08-19.
- [api.github.com/repos/dagster-io/dagster](https://github.com/dagster-io/dagster) —
  direct fetch: Apache-2.0, 16,025 stars, 2,247 forks — retrieved
  2026-08-19.
- [api.github.com/repos/PrefectHQ/prefect](https://github.com/PrefectHQ/prefect)
  and its `main`-branch `LICENSE` file — direct fetch: Apache-2.0
  confirmed via LICENSE file, not just the API summary field; 23,642
  stars, 2,470 forks — retrieved 2026-08-19.
- [api.github.com/repos/dbt-labs/dbt-core](https://github.com/dbt-labs/dbt-core) —
  direct fetch: Apache-2.0, 13,663 stars, 2,510 forks, not archived —
  retrieved 2026-08-19.
- [getdbt.com/licenses-faq](https://www.getdbt.com/licenses-faq) — direct
  fetch: dbt Core Apache-2.0 "indefinitely," dbt Fusion licensing history
  (ELv2 → dbt Product Licensing Agreement as of June 1, 2026) — retrieved
  2026-08-19.
- dbt's own "dbt Core v2 is here" announcement — direct fetch: v2 announced
  June 1, 2026 as alpha, Rust/Fusion engine merged into dbt-core under
  Apache-2.0, dbt Product Licensing Agreement governs the distributed
  premium Fusion binary — retrieved 2026-08-19.
- [pypi.org/pypi/dbt-core/json](https://pypi.org/pypi/dbt-core/json) —
  direct fetch: latest released stable version 1.12.2, no stable 2.0.x
  release on PyPI — re-verified 2026-08-20 (unchanged from the 2026-08-19
  baseline check).
- [github.com/dbt-labs/dbt-core/releases](https://github.com/dbt-labs/dbt-core/releases) —
  direct fetch: `v2.0.0-beta.2` tagged August 18, 2026, still a
  pre-release; 1.x line (through 1.9.11) receiving patch releases as
  recently as August 13–14, 2026 — retrieved 2026-08-20, authoring-time
  re-verification of the baseline's flagged dbt Core v2 status.
- [github.com/apache/iceberg-python](https://github.com/apache/iceberg-python)
  and [github.com/delta-io/delta-rs](https://github.com/delta-io/delta-rs) —
  direct fetch: `pyiceberg` Apache-2.0, 1,118 stars; `deltalake`/delta-rs
  Apache-2.0, 3,284 stars — retrieved 2026-08-19.
- Apache Iceberg and Delta Lake star counts (9.2k / 8.9k) reused from the
  same-day stack.md verification rather than re-fetched, to keep the two
  companion documents from drifting on the same numbers.
- [api.github.com/repos/great-expectations/great_expectations](https://github.com/great-expectations/great_expectations)
  and its `main`-branch `LICENSE` file — direct fetch: Apache-2.0
  confirmed via LICENSE file — retrieved 2026-08-19 (11,719 stars, 1,798
  forks, 28 open issues) and re-verified 2026-08-20 (11,721 stars, 1,798
  forks, 23 open issues, pushed August 19, 2026, description now reads
  "maintained by Fivetran").
- Great Expectations' own blog, dated May 6, 2026 — direct fetch: FICO
  acquisition of GX Cloud (public availability ended June 1, 2026),
  Fivetran becomes GX Core's open-source steward — retrieved 2026-08-19;
  checked again 2026-08-20 for any newer post — none found as of that
  date.
- [greatexpectations.io/blog](https://greatexpectations.io/blog) — direct
  fetch of the blog index, checked 2026-08-20 for posts after May 6,
  2026 specifically about GX Core/Fivetran/stewardship/roadmap — none
  found through mid-August 2026.
- Great Expectations' `develop` branch commit history — direct fetch:
  near-daily commit activity through August 19, 2026, used to
  contextualize the low and falling open-issue count as a triage artifact
  of the ownership transition rather than a maintenance stall — retrieved
  2026-08-19.
- [api.github.com/repos/unionai-oss/pandera](https://github.com/unionai-oss/pandera)
  and its PyPI JSON metadata — direct fetch: MIT license (confirmed via
  PyPI classifier), 4,436 stars, 434 forks, latest release 0.32.1,
  maintained under the unionai-oss (Union.ai) org — retrieved 2026-08-19.
- [api.github.com/repos/pytest-dev/pytest](https://github.com/pytest-dev/pytest) —
  direct fetch: MIT, 14,429 stars, 3,307 forks — retrieved 2026-08-19.
- [api.github.com/repos/apache/superset](https://github.com/apache/superset) —
  direct fetch: Apache-2.0, 74,311 stars, 18,127 forks — retrieved
  2026-08-19.
- [api.github.com/repos/metabase/metabase](https://github.com/metabase/metabase)
  and its `master`-branch `LICENSE.txt` — direct fetch: dual AGPL-3.0
  (core) / proprietary Metabase Commercial License (`enterprise/` dir),
  confirmed via LICENSE file text since GitHub's own `license` field
  incorrectly returns "Other/NOASSERTION" for this repo — 48,831 stars,
  6,750 forks — retrieved 2026-08-19.
- [github.com/lightdash/lightdash](https://github.com/lightdash/lightdash)
  and its `main`-branch `LICENSE` — direct fetch: dual MIT (core) /
  proprietary (`packages/backend/src/ee/`), confirmed via LICENSE file
  text (API field also returns "Other/NOASSERTION") — 6,056 stars, 767
  forks — retrieved 2026-08-19.
- [api.github.com/repos/evidence-dev/evidence](https://github.com/evidence-dev/evidence) —
  direct fetch: MIT, 6,862 stars, 394 forks — retrieved 2026-08-19.
