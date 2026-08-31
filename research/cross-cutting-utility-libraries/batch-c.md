# Baseline: Cross-Cutting Utility Libraries (Batch C) — Structured/tabular data manipulation & analysis

Status: draft      Date: 2026-08-31      Snapshot date: 2026-08-31

This is a third, later-added batch for
`references/cross-cutting-utility-libraries.md`, researched separately from
`batch-a.md` and `batch-b.md` in response to a direct methodology
correction: **evaluate by functional/architectural merit first, adoption
signals second**, and do **not** treat staleness or a CVE as an automatic
disqualifier — assess whether staleness means "feature-complete/saturated"
or genuinely abandoned, and whether a CVE is actually exploitable for the
library's typical use. This domain — pandas vs. Polars vs. Vaex vs.
DuckDB — was named explicitly as the worked example for that correction,
so it is held to that lens more deliberately than Batch A/B's tables were.
Every "Why it earns a slot here" cell below leads with the concrete
architectural/functional reason, not a star or download count; adoption
figures are still direct-fetched and reported, but placed in the
"Maintenance/adoption signal" column as a secondary trust check, not the
deciding factor.

**A real scope finding, checked before researching further, not assumed**:
this repo already has a **Data & Analytics Platforms** stack category with
its own `references/preferred-libraries/data-analytics-platforms.md`,
which already carries a "Dataframe/processing libraries: pandas vs. polars
vs. DuckDB" section (last reviewed 2026-08-19) with its own decision rule.
Read in full this pass to avoid duplicating it. That existing table:

- Already states an architecturally-grounded decision rule (lazy execution
  for larger-than-memory data, multi-core parallelism for CPU-bound
  pipelines, ecosystem-compatibility default for pandas) — closer to the
  corrected merit-first lens than Batch A/B's own tables were, though it
  still opens its comparison table with stars/downloads as the first two
  columns before the prose decision rule.
- Does **not** mention **Vaex** at all — a real, direct gap this batch
  fills.
- Does **not** cover the **npm/TypeScript side** at all — another real gap
  this batch fills.
- Is scoped to the Data & Analytics Platforms *category* — read only when
  a project's primary or secondary category is that one. This cross-cutting
  doc's whole reason to exist is naming utility-shaped choices that recur
  **regardless of category** — a Backend & API Services project generating
  a nightly CSV export report, or an ML pipeline's feature-engineering
  step, hits the exact same pandas-vs-Polars decision without ever reading
  the Data & Analytics Platforms doc.

**Resolution for the authored doc, stated here rather than left implicit**:
this batch's table should be **short and cross-reference the existing
table** for the full pandas/polars/DuckDB decision rule, rather than
duplicating it — and add specifically what's missing: Vaex (full
treatment), the npm-side verdict, and a size/workload-threshold framing
tightened to the merit-first lens the user asked for. See "Explicitly out
of scope" below for the precise line drawn.

## Local precedent

Checked directly this pass, not assumed:

- **`/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/backend/app/requirements.txt`**
  (grepped and confirmed): pins **`pandas==2.0.3`**, **`numpy==1.24.4`**,
  and — notably — **`pyarrow==22.0.0`** directly. **No `polars`, no
  `vaex`, no `duckdb`** anywhere in the file. pandas is used across at
  least five files in this real codebase (`agents/table_reader/loader.py`,
  `reader_tools.py`, `math_tools.py`, `agents/strands_agents/
  visualization_agent.py`, `backend/app/core/data_model/preview.py`) —
  i.e. a real, non-trivial "read/analyze uploaded tabular data" subsystem,
  not an incidental import. **The `pyarrow` pin is itself a concrete,
  worth-stating data point for this batch's own argument**: this codebase
  already carries an Arrow-format dependency (likely pulled in for pandas'
  own Arrow-backed dtype support or a Parquet read path), meaning a future
  move to Polars or DuckDB — both Arrow-native, zero-copy-compatible with
  data already in Arrow form — would not be introducing a wholly new
  columnar-format dependency, just a new *engine* over a format this repo
  already depends on.
- **`/Users/devopammittra/GitHub/ubi-csr-tmf/aws/container/frontend/package.json`**:
  no `danfojs`, `arquero`, or `@duckdb/duckdb-wasm` — the frontend is a
  React 19 + Vite consumer of backend-computed data, not a place doing its
  own tabular analysis, so this is an expected, not a concerning, absence.
- **This repo (`agent-skills`) itself**: `references/preferred-libraries/
  data-analytics-platforms.md` already names pandas/polars/DuckDB (see
  the scope-finding note above) — the one place in this repo any of this
  batch's libraries were already present before this pass.

## Domain: Structured/tabular data manipulation & analysis — impact: high — depth: table + narrative

**The actual mechanism each library uses, not just "it's faster" — direct-fetched
from each library's own docs, since a vague speed claim is exactly what
the merit-first correction asked this pass to avoid.**

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here (architecture first) | Maintenance/adoption signal (direct-fetch verified, secondary) |
|---|---|---|---|---|---|
| **pandas** — the incumbent default, named for what its architecture actually is, not dismissed | Python | The familiar, ecosystem-universal API for loading, cleaning, and analyzing tabular data in memory — every plotting library, most ML libraries, and nearly every notebook tutorial assume it, so code written against it needs zero translation layer to reach the rest of the Python data ecosystem | BSD-3-Clause | **Real local precedent**: `ubi-csr-tmf` uses it directly across five files for exactly its intended purpose. Architecturally: pandas' `DataFrame` is backed by NumPy arrays organized through an internal `BlockManager`, and the large majority of its operations — including most transformations and `groupby` — execute on a **single core by default**; pandas is eager (every operation materializes its result immediately, no query planning). Per pandas' **own** docs (direct-fetched, `pandas.pydata.org/docs/user_guide/scale.html`), quoted precisely rather than a folklore multiplier: *"pandas provides data structures for in-memory analytics, which makes using pandas to analyze datasets that are larger than memory somewhat tricky. Even datasets that are a sizable fraction of memory become unwieldy, as some pandas operations need to make intermediate copies."* **The commonly cited "needs 5–10x the dataset's on-disk size in RAM" figure is search-corroborated folklore, not pandas' own stated number** — flagged honestly rather than repeated as if it were primary-sourced. This is the correct, deliberate default for datasets that fit comfortably in memory and don't need CPU-parallel transformation — not a legacy pick, an appropriately-scoped one | Direct GitHub fetch: 49,607 stars, 20,308 forks, 2,738 open issues, pushed 2026-08-31 (same day, very active); PyPI: v3.0.5 |
| **Polars** — the user's own named example; correctly earns its slot on architecture | Python | Eliminates pandas' two structural bottlenecks at once for CPU-bound or memory-constrained workloads: single-threaded execution and eager (no-query-planning) evaluation | MIT | **Verified via direct fetch of Polars' own README and lazy-engine docs, not assumed from reputation.** README, quoted: *"written from the ground up in Rust with multi-threaded, vectorized (SIMD) execution"* and *"uses the Apache Arrow Columnar Format for zero-copy data sharing."* The lazy API (direct-fetched from `docs.pola.rs/user-guide/lazy/optimizations/`) applies real, named query optimizations before execution — **predicate pushdown** ("applies filters as early as possible... at scan level"), **projection pushdown** ("select only the columns that are needed at the scan level"), **slice pushdown**, **common subplan elimination**, and **join-order estimation to reduce memory pressure** — this is the precise mechanism by which "the methods provided usually suffice the functional requirement" the way the user's own framing described: Polars only reads/computes what the final query actually needs, not the full intermediate result at every step the way eager pandas does. Its **streaming engine** (README, quoted) "processes datasets that don't fit in memory" via query streaming to "drastically reduce memory requirements" — a genuinely different mechanism from pandas' all-in-memory model, not just a faster implementation of the same one. This is the concrete, mechanism-level "why" behind the user's own example, not a benchmark-chart appeal | Direct GitHub fetch: 39,569 stars, 3,072 forks, 2,860 open issues, pushed 2026-08-31 (same day, very active); PyPI: v1.44.1 |
| **Vaex** — the user's other named example; a real, honest, current-status finding follows, not a clean recommendation | Python | A different architectural answer to the same "dataset bigger than RAM" problem Polars' streaming engine addresses: **memory-mapping** the on-disk file so it's never fully loaded, combined with **lazy expression evaluation** and a stated **zero-memory-copy policy**. Direct-fetched from Vaex's own README: *"Instant opening of Huge data files (memory mapping)"*; *"Don't waste memory or time with feature engineering, we (lazily) transform your data when needed"*; and explicitly, *"memory mapping, zero memory copy policy and lazy computations for best performance (no memory wasted)."* Data stays "untouched on disk, and will be streamed only when needed" — this is a genuinely distinct mechanism from both pandas (fully in-RAM) and Polars' streaming engine (still reads/processes in query-driven batches): Vaex is designed around never materializing the full dataset in memory at all, which is the specific answer for exploratory analysis/visualization over a file too large to load even once | MIT | **A real, current, direct-fetch-verified maintenance finding — per the corrected merit-first lens, this is reported as a factual "does it still work for you today" check, not a blanket popularity-based dismissal.** GitHub's own `vaexio/vaex/discussions/2363` ("Is Vaex active?", direct-fetched): core maintainer JovanVeljanoski, June 2024 — *"I am however no longer involved in this project, and I am unaware of its status, so unfortunately I can not provide any info."* Co-maintainer maartenbreddels, same thread — *"I'll do my best to at least get vaex releases out."* That promise has been kept only partially: `vaex-core` PyPI release history (direct-fetched) shows real releases in Oct 2024 (4.18.0, 4.18.1) and Sep 2025 (4.19.0, the current version) — genuine, if infrequent, maintenance, not total abandonment. **The concrete, currently-load-bearing limitation, not a vague staleness flag**: `vaex-core` 4.19.0's own PyPI metadata states `requires_python: <3.13,>=3.9` — **it does not install on Python 3.13 or 3.14 at all**, a functional, present-tense blocker for a new project on a current Python version, not a maintenance-signal abstraction. **Verdict for the authored doc**: name Vaex for its genuinely distinct memory-mapped architecture (a real answer Polars' streaming engine doesn't give the same way), but with this precise Python-version ceiling stated as the reason it's not the default for a *new* 2026 project — this is a "saturated feature set, but a hard current-runtime compatibility wall," not "outdated because it's unpopular" | Direct GitHub fetch: 8,510 stars, 602 forks, 552 open issues, pushed 2026-04-01 (real commit activity as recently as Feb 2026, per `gh api .../commits`); PyPI (`vaex-core`): v4.19.0, released 2025-09-03; **`requires_python: <3.13,>=3.9`** (direct-fetched, load-bearing) |
| **DuckDB** — a genuinely different mechanism, not a competitor on the same axis | Python (+ npm, see below) | Not a DataFrame-API library at all — an **embedded, in-process OLAP SQL engine**. The pain it eliminates is different in kind from pandas/Polars/Vaex: ad hoc analytical *queries* (joins, aggregations, filters expressed as SQL) across one or more Parquet/CSV/Arrow files, or directly against an existing pandas/Polars DataFrame already in memory, without first loading everything into a single unified structure | MIT | Direct-fetched from DuckDB's own `duckdb.org/why_duckdb.html`: *"completely embedded within a host process"* (no server to stand up), a *"columnar-vectorized query execution engine, where... a large batch of values (a 'vector') are processed in one operation"* (batch-at-a-time execution, not row-at-a-time), and — the concrete zero-copy claim — *"can run queries directly on Pandas data without ever importing or copying any data."* Interoperates with Polars/Arrow the same zero-copy way via the shared Arrow columnar format. The functional case for reaching for it specifically: **ad hoc SQL joins/aggregations across multiple large files that individually or together exceed comfortable RAM**, without hand-writing a Polars lazy-query chain or a pandas chunking loop — SQL expressiveness over exactly this doc's other three libraries' data, not a replacement for any of them | Direct GitHub fetch: 40,862 stars, 3,692 forks, 847 open issues, pushed 2026-08-31 (same day, very active); PyPI: v1.5.5 |

**Decision guidance — the practical "when do you actually move off
pandas" answer this domain needs to give, tied to the specific mechanism
each alternative offers rather than a blanket "pandas is slow" claim**:

- **Stay on pandas** when the dataset comfortably fits in memory (no
  intermediate-copy pressure per pandas' own scale-doc caveat above) and
  the project's other dependencies (plotting, ML, notebook tooling)
  already assume a pandas `DataFrame` — the ecosystem-compatibility case,
  not a performance concession.
- **Move to Polars** when either holds: (1) the pipeline is CPU-bound on
  transformation and Polars' default multi-threaded, SIMD-vectorized
  execution changes wall-clock time in practice — this is a profiling
  question, not an assumption; or (2) the dataset is large enough that
  pandas' eager, fully-materializing model creates real memory pressure,
  and Polars' lazy query optimizer (predicate/projection pushdown) plus
  streaming engine can avoid materializing data pandas would. Greenfield
  work with no existing pandas-specific dependency chain is the cheapest
  point to default to Polars directly, per the existing
  `data-analytics-platforms.md` guidance — not re-litigated here.
- **Reach for Vaex specifically** when the workload is exploratory/
  visualization-driven analysis over a single file too large to load into
  RAM even once, and the project can accept Vaex's current `<3.13`
  Python-version ceiling (e.g. a pinned-Python-3.12 environment) — a
  narrower, more conditional recommendation than Polars', stated precisely
  because of that real compatibility limitation, not because the
  memory-mapped architecture itself is inferior.
- **Reach for DuckDB** when the actual task is ad hoc SQL-shaped
  analytical queries (joins/aggregations/filters) across one or more
  Parquet/CSV files or an existing in-memory DataFrame, especially when
  the combined data exceeds comfortable RAM — this is an orthogonal axis
  to the DataFrame-API choice above, not a fourth competing default: a
  project commonly uses DuckDB *for the query* and pandas/Polars *for the
  result*.

**Dask — a deliberate scope exclusion, stated rather than silent.** Its
own README (direct-fetched) describes it as *"a flexible parallel
computing library for analytics"* — a **distributed/multi-machine cluster
computing framework** with a pandas-like DataFrame API layered on top, a
different axis (single-node performance vs. multi-node horizontal scale)
from every library in the table above. Named here only to state the
boundary explicitly: the moment a workload's real constraint is "this
needs to run across a cluster of machines," not "this needs to run faster
or with less memory on one machine," it has left this domain's scope
entirely and become an infrastructure/cluster-orchestration decision — a
natural candidate for a dedicated entry in `data-analytics-platforms.md`'s
own "Explicitly out of scope" list (which already names Spark/PySpark as
exactly this kind of deliberate omission), not for this cross-cutting doc.

**npm/TypeScript side — a genuinely mixed picture, not a clean "no
equivalent" the way Batch A's cloud-storage-I/O domain found.** Three real
candidates, each solving a different piece of the problem, none
matching pandas/Polars' combined maturity and adoption:

| Library | Ecosystem | The specific pain it eliminates | License | Why it earns a slot here | Maintenance/adoption signal (direct-fetch verified, secondary) |
|---|---|---|---|---|---|
| **danfojs** (`javascriptdata/danfojs`) | npm/TS | A deliberately pandas-shaped API in JavaScript — per its own README (direct-fetched, quoted): *"heavily inspired by Pandas library, and provides a similar API. This means that users familiar with Pandas, can easily pick up danfo.js."* Also integrates directly with TensorFlow.js tensors for a JS-native ML pipeline | MIT | The closest **API-level** analog to pandas, but a materially thinner, less architecturally distinct implementation — its README makes no Arrow/columnar-format claim, only a TensorFlow.js-tensor integration point. Real, current commit activity exists (a February 2026 merged PR improving `groupby`'s `agg` performance from 16s to 20ms for 20k rows — a genuine, recent, functionally-meaningful fix, not a stale project), but the project's raw scale is small next to arquero/duckdb-wasm below | Direct GitHub fetch: 5,059 stars, 222 forks, 101 open issues, pushed 2026-04-15; npm-downloads: 4.85K/week (`danfojs`) + 4.39K/week (`danfojs-node`) |
| **arquero** (`uwdata/arquero`) | npm/TS | The genuinely **architecturally closer** analog to Polars, not just an API lookalike: per its own README (direct-fetched, quoted), a library for *"query processing and transformation of array-backed data tables,"* explicitly *"flexible: query over arrays, typed arrays, array-like objects, or **Apache Arrow columns**"* — real columnar/Arrow interop, not a row-oriented object-array wrapper. Inspired by dplyr/relational algebra rather than pandas' specific API shape | BSD-3-Clause | From University of Washington's Interactive Data Lab (the group behind D3/Vega/Observable Plot) — an academic-visualization-tooling pedigree, not a startup abandoned mid-build; real, if modest, current npm pull | Direct GitHub fetch: 1,535 stars, 74 forks, 41 open issues, pushed 2025-05-29 — **~1 year, 3 months stale relative to this snapshot**, a real currency flag stated plainly, though consistent with a feature-complete, narrowly-scoped library rather than an abandoned one (worth a closer look at open-issue responsiveness before the authored doc states this without any caveat); npm-downloads: 72.4K/week |
| **`@duckdb/duckdb-wasm`** — the genuinely strongest npm-side answer, architecturally, not just by download count | npm/TS | DuckDB itself, compiled to WebAssembly — the actual embedded columnar-vectorized SQL engine described in the Python table above, running in-browser or in Node, not a separate reimplementation with its own bugs/API gaps. The pain it eliminates: SQL-shaped analytical queries over Parquet/CSV/Arrow data directly in a browser tab or a Node process, with the same zero-copy Arrow interop DuckDB offers on the Python side | MIT | The most architecturally capable of the three by a clear margin — it's DuckDB, not a from-scratch JS reimplementation of dataframe semantics — and also the highest-adoption of the three researched, a rare case in this batch where the architectural and adoption signals point the same direction rather than diverging | Direct GitHub fetch: 2,113 stars, 228 forks, 189 open issues, pushed 2026-07-28 (active); npm-downloads: **510.1K/week** — by a wide margin the highest of the three npm candidates |

**Honest verdict for the authored doc**: unlike Batch A's cloud-storage-I/O
domain (a clean "no comparable npm equivalent exists"), this domain has a
**real, if fragmented, npm-side answer** — but split across three
different mechanisms rather than one dominant library the way
pandas/Polars are on the Python side: danfojs for pandas-API familiarity,
arquero for a genuinely columnar/Arrow-aware DataFrame-shaped API, and
`@duckdb/duckdb-wasm` for the SQL-over-Arrow-columnar-data approach —
which, per its own architecture (it *is* DuckDB) and its adoption figures,
is the strongest single recommendation of the three for a TypeScript
project doing anything beyond light in-memory row/column manipulation.

## Explicitly out of scope

- **The full pandas-vs-polars-vs-DuckDB decision rule for Data &
  Analytics Platforms-category projects** — already owned by
  `references/preferred-libraries/data-analytics-platforms.md`'s
  "Dataframe/processing libraries" section (read in full this pass to
  confirm no unintentional duplication; that doc's own decision rule is
  reused, not restated, above). This batch's table exists specifically for
  the **cross-category** case — any project, regardless of primary
  category, that hits a "load and manipulate a tabular file" need — and
  adds what that doc doesn't cover: Vaex and the npm side.
- **Distributed/cluster computing frameworks** (Dask, Spark/PySpark, Ray) —
  see the dedicated Dask scope note above; a materially different axis
  (multi-machine horizontal scale) from this domain's single-node
  DataFrame/query-engine comparison, and already named as a deliberate
  omission in `data-analytics-platforms.md`'s own "Explicitly out of
  scope" list for Spark specifically.
- **Orchestration, transformation-layer (dbt), lakehouse table formats,
  data-validation-for-pipelines, and BI/visualization tooling** — all
  already owned by `data-analytics-platforms.md`'s other sections; this
  batch's domain is narrowly the DataFrame/query-engine layer itself.
- **NumPy** — the array library pandas/most of this table is itself built
  on — not independently researched here; it's a foundational dependency
  of this whole domain, not a competing choice at this domain's level.

## Sources

- Local file reads: `/Users/devopammittra/GitHub/ubi-csr-tmf/aws/
  container/backend/app/requirements.txt` (grepped for pandas/polars/
  vaex/duckdb/pyarrow/numpy/dask), file-existence/import check across
  `agents/table_reader/{loader.py,reader_tools.py,math_tools.py}`,
  `agents/strands_agents/visualization_agent.py`,
  `backend/app/core/data_model/preview.py`; `/Users/devopammittra/GitHub/
  ubi-csr-tmf/aws/container/frontend/package.json` (grepped);
  `/Users/devopammittra/GitHub/agent-skills/skills/project-incubation/
  references/preferred-libraries/data-analytics-platforms.md` (read in
  full, for the scope-boundary finding and to avoid duplicating its
  existing pandas/polars/DuckDB decision rule) — all 2026-08-31.
- `gh api repos/<owner>/<repo>` direct GitHub API fetches (license, stars,
  forks, open issues, `pushed_at`, `archived`) for: pandas-dev/pandas,
  pola-rs/polars, vaexio/vaex, duckdb/duckdb, dask/dask,
  javascriptdata/danfojs, uwdata/arquero, duckdb/duckdb-wasm — retrieved
  2026-08-31.
- `gh api repos/vaexio/vaex/releases`, `.../issues`, and `.../commits` —
  direct fetches used to independently verify Vaex's real current
  activity level (most recent commit 2026-02-05; issues still receiving
  dependency-bump/CI-maintenance activity into mid-2026) rather than
  relying on `pushed_at` alone — retrieved 2026-08-31.
- Direct PyPI JSON-API fetches (`pypi.org/pypi/<name>/json`) for current
  version and full release-history timestamps: pandas, polars, duckdb,
  vaex, vaex-core (the latter specifically to see the real
  4.17.0→4.18.0→4.19.0 release-cadence gap and confirm the current
  `requires_python` ceiling) — retrieved 2026-08-31.
- `github.com/vaexio/vaex/discussions/2363` ("Is Vaex active?") — direct
  fetch, maintainer quotes reproduced verbatim above — retrieved
  2026-08-31.
- Direct fetches of each library's own docs/README for the specific
  architectural claims quoted throughout: `raw.githubusercontent.com/
  pola-rs/polars/main/README.md`, `docs.pola.rs/user-guide/lazy/
  optimizations/`, `raw.githubusercontent.com/vaexio/vaex/master/
  README.md`, `duckdb.org/why_duckdb.html`,
  `pandas.pydata.org/docs/user_guide/scale.html`,
  `raw.githubusercontent.com/dask/dask/main/README.rst`,
  `raw.githubusercontent.com/javascriptdata/danfojs/dev/README.md`,
  `raw.githubusercontent.com/uwdata/arquero/master/README.md` — all
  retrieved 2026-08-31.
- Direct `registry.npmjs.org/<name>/latest` and `api.npmjs.org/downloads/
  point/last-week/<name>` fetches for: danfojs, danfojs-node, arquero,
  @duckdb/duckdb-wasm — retrieved 2026-08-31.
- WebSearch corroboration (not independently direct-fetched primary
  source beyond the GitHub discussion itself, flagged inline): general
  community commentary on Vaex's maintenance status (Snyk Advisor, package
  health pages) used only to locate the primary-source GitHub discussion
  above, not cited as a standalone claim — retrieved 2026-08-31.

## Open questions for the user

- **Vaex's Python `<3.13` ceiling is the load-bearing fact this batch
  leans on to give a precise, current, non-popularity-based reason it
  isn't the default** — should the authored doc name this as a hard
  blocker (don't recommend Vaex for any project not deliberately pinned
  below Python 3.13), or a softer "confirm your Python version before
  choosing this" caveat? This baseline leans toward stating it plainly as
  a real current constraint, consistent with the corrected merit-first
  lens (a concrete compatibility fact, not a vague staleness vibe).
- **Should this batch's table be merged into `data-analytics-platforms.md`
  instead of staying in the cross-cutting doc**, given how much overlap
  exists? This baseline's own read is no — the whole value of the
  cross-cutting doc is being read by projects that never open the Data &
  Analytics Platforms category doc at all — but this is a real
  information-architecture call worth confirming rather than assuming.
- **arquero's ~15-month-stale `pushed_at`** wasn't investigated as deeply
  as Vaex's (no equivalent "is this project active?" discussion was
  searched for) — worth a closer look before the authored doc states its
  entry without any staleness caveat, or is "academic-lab pedigree,
  feature-complete, real Arrow-format architecture" sufficient standalone
  reasoning per this pass's own read?
- **danfojs vs. arquero vs. `@duckdb/duckdb-wasm` — should the authored
  doc name one as *the* npm default**, the way Python's table can point to
  pandas/Polars/DuckDB by workload shape, or is presenting all three by
  their distinct mechanism (API-familiarity vs. Arrow-native columnar API
  vs. embedded SQL engine) the more honest framing given none dominates
  the others in both architecture and adoption simultaneously (except
  duckdb-wasm, which this baseline already leans toward as the strongest
  single npm-side recommendation)?

## Target file(s) + estimated length

- `skills/project-incubation/references/cross-cutting-utility-libraries.md`
  — this batch covers 1 domain (a later addition to the file Batch A/B's 12
  domains already scope) at approximately 180–220 lines on its own,
  including the cross-reference framing to `data-analytics-platforms.md`
  and the two-table (Python + npm) structure. Combined with Batch A (6
  domains) and Batch B (6 domains), the fully authored file will run
  longer than either batch's own individual estimate suggested — the
  authoring pass should budget for a real Table of Contents given the
  file will exceed this repo's own 100-line TOC-convention threshold by a
  wide margin once merged.
