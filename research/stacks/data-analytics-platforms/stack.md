# Baseline: Data & Analytics Platforms — Architecture & Stack
Status: user-approved      Date: 2026-08-19

## Local precedent — one modest worked example found, honestly scoped

Checked directly this pass, per the task's instruction not to assume none
exists: `C:\Users\devop\GitHub\MEDGraph\medical_institutions\` is a real,
running batch pipeline — `extractors/{usa,can,chn,ind}.py` each scrape
government/health-data sources (NIFA, AVMA, CMS, HRSA, plus country-specific
equivalents) via `requests`/`BeautifulSoup`/`pdfplumber`, `extractors/base.py`
normalizes and fuzzy-deduplicates (`fuzzywuzzy`) before an `INSERT ... ON
CONFLICT DO NOTHING` write to PostgreSQL, and `extraction_monitor.py` uses
`pandas` to build a reporting summary (counts by country/type, coverage of
website/coordinate fields) read from that same table. This is a genuine
extract → normalize/dedupe → load → report shape — cited below in the
ELT/ETL and notebook-to-production sections as a real (if small-scale) data
point. **Honest limits, stated rather than glossed over**: it has no
orchestrator (it's invoked directly, not scheduled/DAG-managed), no
transformation layer distinct from the load step (dedup logic lives in
Python, not SQL/dbt), no data-quality/validation library, and no warehouse —
it writes straight to an OLTP-shaped Postgres table. It's evidence a batch
extraction pipeline exists locally, not evidence for warehouse/orchestration/
validation architecture, which is sourced externally throughout.

Also checked: `C:\Users\devop\GitHub\MCPg\benchmarks\datasets\load_tpch.py`
uses DuckDB's `tpch` extension purely as a **dev-only benchmark-data
generator** (generates TPC-H tables, streams to CSV, `COPY`s into Postgres
for MCPg's own integration tests) — not a data platform itself, and MCPg is
already the Agentic & MCP Platforms baseline's subject; noted here only
because it's the one place DuckDB appears locally. `C:\Users\devop\GitHub\
presidio\presidio-structured\` uses pandas for tabular-PII analysis, but
this is Microsoft's own upstream OSS repo cloned locally, not a project the
user built — not counted as local precedent for the same reason a vendored
dependency wouldn't be. No local repo runs Airflow/Dagster/Prefect, dbt, or
Great Expectations/Pandera. `C:\Users\devop\LitBot` and `C:\Users\devop\
ucum_check` were also checked directly (grepped for the same import list)
and confirmed to have no pandas/polars/orchestration/dbt/validation-library
usage.

## In scope

- **How this category specializes the cross-cutting
  architecture-templates.md pattern catalog** — impact: high — depth:
  section. A data platform is the clearest home for **layered
  architecture**, applied to pipeline *stages* rather than application
  tiers: raw/bronze → cleaned/silver → aggregated/gold is a layering
  discipline in its own right (see lakehouse medallion pattern below),
  independent of whether the platform's application code itself is layered.
  **Hexagonal/ports-and-adapters fits the ingestion boundary specifically**:
  a source connector (API, file drop, CDC stream) is an inbound adapter, a
  warehouse/lake write is an outbound adapter, and the transformation logic
  in between should not know which system produced or will consume the
  data — this is the same reasoning the Agentic & MCP Platforms and Backend
  & API Services baselines used for their own inbound/outbound boundaries,
  and it's what lets a pipeline swap Airbyte for a hand-rolled connector, or
  Postgres for Snowflake, without rewriting transformation logic.
  **Modular monolith is the honest default for the orchestration/
  transformation codebase** — one repo/deployable containing many pipeline
  definitions organized by domain (matches the cross-cutting doc's
  monolith-first heuristic); splitting into per-domain deployables
  (microservices) is rarely justified below genuine independent-team
  ownership of separate pipelines with separate release cadences.
  **Microservices** proper are a poor fit for the *pipeline* layer itself
  (a DAG orchestrator is already a distributed-execution system; adding
  service boundaries on top adds coordination cost without a matching
  benefit) but a fine fit for a platform's *serving* layer (a metrics API,
  a reverse-ETL sync service) sitting downstream of the warehouse.
  **CQRS is not an exotic pattern here — a data warehouse or lakehouse
  *is*, architecturally, the read-model half of CQRS applied at
  organization scale**: OLTP systems are the write model, the
  warehouse/lake is a separately-optimized read model built by replaying
  those writes through a pipeline; this reframes "does CQRS apply?" from
  the cross-cutting doc's usual caution (rarely justified) to "already
  applies, by construction, the moment a warehouse exists" — worth stating
  explicitly since a data-platform builder might otherwise think CQRS is
  something extra to opt into. **Event-driven is the natural fit for the
  ingestion edge of a platform with real-time/CDC sources** (see batch vs.
  streaming below) — an overlay on the batch/DAG core, not a wholesale
  replacement, matching the same "overlay not replacement" framing the
  Backend & API Services baseline used. **Serverless** fits
  spiky/event-triggered ingestion functions (a Lambda invoked on file
  arrival, a Cloud Function reacting to a Pub/Sub message) and short
  stateless transformation steps; it's a poor fit for long-running
  stateful joins/aggregations over large datasets, which is squarely where
  orchestrator-managed, provisioned-compute execution (Spark/warehouse
  compute, a Dagster/Airflow worker) belongs instead.

- **Batch vs. streaming — the real decision signal is the *consuming
  decision's* latency tolerance, not the data source's technical
  capability** — impact: high — depth: table + decision rule. The
  recurring, credible 2026 framing across multiple independent sources:
  freshness requirements belong to the *decision being made downstream*,
  not to the pipeline or the data itself — a source being technically
  capable of streaming doesn't obligate a streaming pipeline if nothing
  downstream needs sub-hour data.
  | Latency tolerance | Typical use case | Default architecture |
  |---|---|---|
  | ~24 hours | Financial/regulatory reporting, historical trend analysis | Batch (daily) |
  | ~1 hour | Operational dashboards, inventory tracking | Batch (hourly/micro-batch) |
  | 1–15 minutes | User activity feeds, recommendation refresh | Near-real-time (micro-batch or lightweight streaming) |
  | Sub-second | Fraud detection, trading, IoT safety interlocks | True streaming |
  **Decision rule**: default to batch — it is simpler, cheaper to operate,
  and achieves *higher throughput* for heavy joins/aggregations than
  streaming would for the same data volume (a 15-minute batch window can
  process millions of rows with complex joins more efficiently than
  streaming the same volume event-by-event). Justify streaming only when a
  named downstream decision genuinely needs sub-15-minute freshness *and*
  the team accepts streaming's real complexity tax: late/out-of-order
  events need watermarks and straggler policies, stateful aggregations need
  state that survives failures, and at-least-once delivery semantics push
  duplicate-handling onto every consumer. This is a legitimate, cited
  complexity cost, not an incidental inconvenience — teams that stream
  because "the data could be real-time" rather than because a decision
  requires it are paying that tax for no benefit. Deep streaming-engine
  architecture (Kafka, Flink, Spark Structured Streaming internals) is
  explicitly out of scope here — see Explicitly out of scope.

- **Data warehouse vs. data lake vs. lakehouse — the lakehouse is the 2025–
  2026 consensus default, with named alternatives to it named honestly**
  — impact: high — depth: section. Multiple 2025-2026 sources converge on
  the same shape: a data lakehouse adds a transactional metadata layer
  (schema enforcement, ACID guarantees, warehouse-grade query performance)
  directly on top of cheap object storage, via an **open table format**
  (Apache Iceberg, Delta Lake, or Apache Hudi) that manages the underlying
  data files — giving the storage economics of a lake with the reliability
  of a warehouse, without maintaining both separately. Reported adoption:
  over half of surveyed data teams now implement lakehouse patterns as of
  early-2026 industry reporting (cited with the caveat that this specific
  "50%+" figure traces to a single industry report referenced across
  several secondary sources, not independently re-derived this pass).
  **Table-format choice is the concrete decision underneath "lakehouse"**:
  Apache Iceberg has become the closer thing to neutral infrastructure —
  an Apache Software Foundation top-level project (confirmed by direct
  fetch: Apache-2.0, 9.2k GitHub stars, 9,086 commits, active CI) with the
  widest engine support and REST Catalog interoperability, adopted across
  Snowflake/Databricks/AWS/Google rather than tied to one vendor's stack —
  the safer default when starting fresh without an existing platform
  commitment. Delta Lake (Apache-2.0, confirmed by direct fetch: 8.9k
  stars, 5,520 commits) is the better-integrated choice specifically when
  a team is already running Databricks/Spark workloads, where its
  Databricks-specific performance features (Z-ordering, liquid clustering)
  are ahead of generic alternatives — a real, named trade-off between
  "most portable" (Iceberg) and "most optimized for one platform"
  (Delta on Databricks), not a strict better/worse ranking. **A plain data
  warehouse (no open table format, vendor-managed storage) remains the
  simpler, legitimate choice** for teams that don't need multi-engine
  access to the same files and are fine with one platform owning storage
  end-to-end (Snowflake, BigQuery) — the lakehouse pattern earns its
  complexity specifically when multiple compute engines need to read the
  same underlying files, or when avoiding storage vendor lock-in matters.
  A **plain data lake with no table format at all** (raw files, no ACID/
  schema layer) is named here only as the thing lakehouse architecture was
  invented to fix — schema-on-read chaos and no transactional guarantees —
  not a recommended target for new projects.

- **ELT vs. ETL — ELT is the dominant pattern for analytical workloads, for
  a specific, checkable reason** — impact: high — depth: section. The
  ETL→ELT shift tracks directly to cloud-warehouse economics: compute
  became cheap and elastic (Snowflake/BigQuery/Redshift-style pay-per-query
  or auto-scaling compute) and object storage is cheap, so loading raw data
  first and transforming it *inside* the warehouse using its own compute
  beats pre-transforming in a separate processing tier before load. A
  second, independently real benefit: keeping raw data preserved enables
  **reprocessing** — when a business rule changes, the fix is re-running
  transformations against already-loaded raw history, not re-extracting
  from every source system again. **When ETL still applies, named
  concretely rather than left as an asterisk**: strict compliance regimes
  where raw (unmasked/unfiltered) data must never land in the target system
  (GDPR/HIPAA-driven pre-filtering before load); on-premise or
  compute-constrained destinations that can't absorb in-warehouse
  transformation load; and complex non-SQL transformation logic (fuzzy
  matching, ML-based enrichment, external-API lookups) that doesn't
  express well as warehouse SQL — MEDGraph's local fuzzy-dedup step, cited
  above, is a concrete instance of exactly this ETL-shaped case: the
  transform (`fuzz.token_sort_ratio` matching) happens in Python before the
  write, not as warehouse SQL after it, and that's a legitimate reason to
  choose ETL over ELT for that specific step rather than a gap to fix.
  Practical default for a new project without one of these constraints:
  ELT, using the target warehouse/lakehouse's own compute for
  transformation (dbt — see libraries.md — is the current default tool for
  this).

- **Orchestration architecture: DAG-scheduled vs. event-triggered, and why
  most real platforms need both** — impact: high — depth: table + decision
  rule. A DAG orchestrator (Airflow/Dagster/Prefect — see libraries.md) is
  **dependency-aware**, not merely time-based: downstream tasks run once
  upstream tasks actually complete, not simply because a clock struck an
  hour — this is the meaningful distinction from a bare cron/job scheduler,
  which fires on a schedule regardless of whether upstream data has
  actually arrived (a documented failure mode: a schedule-only pipeline
  that runs before data lands produces stale or empty output, and only a
  dependency-aware system catches this). **Event-triggered** execution
  (file-arrival sensors, message-queue consumption, webhook-fired runs)
  moves the trigger from "a fixed time" to "a real signal that new data
  exists" — one concretely reported benefit from organizations that made
  this shift: reducing worst-case delay from missed-schedule-to-next-run
  gaps (up to ~2 days in a fixed daily-schedule setup) down to
  minutes (cited as a single practitioner-reported case study, not a
  general benchmark). **Decision rule**: DAG-based scheduling remains the
  right default for most analytical pipelines — well-defined stages,
  explicit dependency/retry logic, minute-level scheduling resolution is
  more than adequate for batch/near-real-time freshness tiers. Move to
  event-triggered execution specifically when a pipeline's freshness
  requirement is tied to *data arrival* rather than *time* (a file lands
  irregularly and processing should start immediately, not wait for the
  next scheduled slot) — this is compatible with, not a replacement for, a
  DAG orchestrator, since Airflow/Dagster/Prefect all support
  sensor/event-based triggering of an otherwise dependency-managed DAG.
  True low-latency stream processing (sub-second, p99 <100ms) is a
  different tool category entirely (Flink/Kafka Streams) — out of scope
  here, deferred to the sibling Integration & Event-Driven Systems
  baseline.

- **The notebook-to-production transition — a real, named pain point with
  concrete architectural guidance, not just "productionize it eventually"**
  — impact: high — depth: section. The mechanism is specific and worth
  stating precisely rather than vaguely: a Jupyter notebook allows
  out-of-order cell execution, so its in-memory state becomes a black box
  that can't be reliably reconstructed from the file alone (the **hidden
  state problem**); a `.ipynb` file is JSON with embedded outputs, so it
  doesn't diff meaningfully in git and can't run headless in a CI runner
  without extra tooling — together these are described in current sources
  as a "fragmentation tax": the cost paid when exploratory analysis, build,
  and run environments are three different, incompatible things. Concrete
  guidance for the authored doc: (1) treat the notebook as genuinely
  disposable scratch work, not a draft of the pipeline — the moment
  exploratory logic is validated, extract it into a plain Python
  module/package with functions that take and return typed data, not
  notebook cells; (2) that extraction is also the natural point to add
  the first tests (see Testing below) and the first data-quality checks
  (see Data quality below) — a notebook's `df.head()` visual eyeball check
  is not a test, and the transition point is exactly where a real
  assertion should replace it; (3) wire the extracted module into the
  orchestrator (Airflow/Dagster/Prefect task, dbt model) rather than
  scheduling the notebook itself via a notebook-execution tool — the
  latter (papermill-style notebook scheduling) is a legitimate stopgap for
  a single analyst's recurring report, not a pattern to build a
  production platform's core pipelines on. MEDGraph's own extractors,
  cited above, already skip the notebook stage entirely (plain `.py`
  modules from the start) — a reasonable data point for "start there
  directly on a new pipeline" rather than routing every new pipeline
  through a notebook phase on principle.

- **Data quality/validation as an architectural concern — where the check
  runs, not just that it exists** — impact: high — depth: section. The
  architectural point worth making explicitly: a validation library
  (Pandera/Great Expectations — see libraries.md) is only as good as
  *where in the pipeline* it's wired in. Current practice distinguishes at
  least three enforcement points, each catching a different failure class:
  (1) **at ingestion/load** — schema and type checks on data as it enters
  the platform, catching upstream source changes before they propagate;
  (2) **between transformation stages** (e.g., bronze→silver, silver→gold
  in a medallion-layered lakehouse) — row-count, null-rate, and
  referential-integrity checks that catch a broken join or a filter that
  silently drops more rows than expected; (3) **at the serving boundary**
  — final-output checks (e.g., "this table must never be empty," "this
  metric must be within N% of yesterday's value") that gate what a BI tool
  or downstream consumer actually sees, and are the closest analogue to
  the API-service testing layer's contract test. The practical default: a
  failed check at (1) or (2) should fail the pipeline run (fail loud,
  before bad data propagates); a failed check at (3) is the natural place
  for a **circuit-breaker** pattern — block the serving layer from
  publishing a metric/table that fails its own sanity check rather than
  silently shipping wrong numbers to a dashboard. This mirrors the
  cross-cutting doc's general "architectural concern, not an afterthought"
  framing applied concretely to where a data pipeline's checks actually
  sit.

- **Data contracts between producing and consuming teams** — impact: high
  — depth: section. A data contract is a formal, versioned, ideally
  machine-readable specification of what a producing team's data will look
  like — schema, semantics, freshness/completeness SLAs, and ownership
  metadata naming who to contact when it breaks — agreed between the team
  that produces a dataset and the team(s) that consume it, replacing
  informal "please don't change that column" tribal knowledge with
  something enforceable in CI. The current concrete open standard: the
  **Open Data Contract Standard (ODCS)**, a YAML-based spec for schema,
  quality rules, SLAs, and ownership, governed by the **Bitol** project
  under the Linux Foundation AI & Data umbrella (confirmed by direct
  fetch: Apache-2.0, current version v3.1.0, 1.1k GitHub stars — a modest
  but real and vendor-neutral governance home, not a single company's
  proprietary format). For streaming-specific contracts, **Confluent
  Schema Registry's** own data-contracts feature (schema + quality rules +
  migration rules, tied specifically to Kafka topics) is the dominant
  practical implementation in that narrower streaming context, though it
  is a Confluent-ecosystem feature rather than the vendor-neutral ODCS
  standard — worth naming as a real but ecosystem-scoped alternative, not
  presenting the two as directly competing on equal footing. **Governance
  model, stated honestly**: producers own and propose contract changes
  (they control the schema/semantics/generation logic); consumers validate
  requirements and flag breaking needs; a platform/governance function
  operationalizes the contract (automating validation in CI, managing
  versioning) — this is the same producer-primary-responsibility framing
  multiple 2025-2026 sources converge on independently.

- **Schema evolution handling** — impact: high — depth: checklist,
  directly downstream of the data-contracts section above. The concrete,
  actionable pattern: schema changes are proposed as a **new version of
  the contract**, not a silent in-place mutation — additive-only changes
  (new nullable column, new optional field) are the low-friction, usually
  backward-compatible case; anything that removes, renames, or narrows the
  type of an existing field is a breaking change that needs a deliberate
  versioned-contract bump and a consumer-migration window, not a
  same-day merge. This is the same additive-only-by-default discipline the
  Backend & API Services baseline named for API evolution-without-
  versioning — the two categories converge on the same underlying
  principle (additive changes are cheap, breaking changes need a
  deliberate process) applied to data schemas instead of API payloads.
  Table-format-level mechanics worth naming (both Iceberg and Delta Lake
  support this natively, per their own project documentation referenced
  above): column addition/rename/reorder/type-widening without rewriting
  historical data files, and **schema enforcement** at write time to
  reject a write that would silently violate the current contract —
  the lakehouse table format itself is part of how schema evolution gets
  enforced mechanically, not just a policy written in a document.

- **Testing approaches specific to data pipelines — what "TDD for a data
  pipeline" concretely means in current practice** — impact: high — depth:
  table. Current practice (per dbt's own 2024 introduction of unit testing
  in dbt Core, now well-established) distinguishes two testing philosophies
  that are often conflated:
  | Test type | Runs against | Catches | When it runs |
  |---|---|---|---|
  | **Unit tests** (dbt: static seeds/inline values in YAML; Python: pytest against a transformation function with fixture input) | Static, predefined, hand-crafted inputs | Logic errors in the transformation itself (a join condition, an aggregation formula) — deterministic, fast, no warehouse compute needed | Every local change, and in CI on every PR — the fast inner-loop check |
  | **Data tests** (dbt: `dbt test` against a built model; Great Expectations/Pandera checks against a real table) | Live warehouse/lake data | Data-quality problems in the *actual current data* (nulls appearing where they shouldn't, referential integrity broken, a metric out of expected range) — not a logic bug, a data-reality bug | On pipeline run / on schedule, against real (or real-shaped) data |
  This is the shape "TDD for a data pipeline" takes in current practice:
  write the unit test *before* the transformation logic (verifying a join/
  aggregation produces the expected output for known input) exactly as
  conventional TDD does, then separately layer data tests as an ongoing
  production gate — the two are complementary, not substitutes for each
  other, and a pipeline with only data tests (no unit tests on the
  transform logic itself) is missing the fast, deterministic inner loop
  that makes TDD valuable in the first place. Library/tool names for both
  layers live in libraries.md.

- **Data mesh — named honestly as an organizational pattern past its hype
  peak, not a technical architecture to default into** — impact: med —
  depth: paragraph. Multiple 2025-2026 sources describe data mesh as having
  passed peak hype (~2022) through a trough of disillusionment (~2024) and
  settling, by 2026, into organizations keeping the *useful* parts —
  domain-oriented data ownership, treating a dataset as a product with a
  named owner, federated (not zero) governance — while abandoning the more
  dogmatic full-decentralization vision. A named structural criticism
  worth carrying into the authored doc rather than omitting: domain teams
  optimizing purely for their own immediate use case tend to under-invest
  in making their data genuinely reusable by other domains, since the
  benefit of that extra generality work accrues mostly to *other* teams,
  not the one doing the work — a real coordination-economics problem, not
  a tooling problem a platform choice fixes on its own. Practical framing
  for a new project: this is an organizational/ownership decision more
  than an architecture-template decision, and most projects in this
  skill's target size range (a project just now incubating a data
  platform) don't yet have the multi-domain team structure that makes
  data mesh's decentralization worth the coordination overhead — the
  *data contracts + data quality gates* guidance above is the part of data
  mesh's toolkit worth adopting early regardless of mesh-vs-centralized
  organization, since contracts and quality gates are useful at any scale.

## Explicitly out of scope

- Specific library/tool names, licenses, and adoption signals — belongs
  entirely to the companion `libraries.md` baseline; this doc names
  categories and decision criteria only.
- ML/AI model training, fine-tuning, feature stores, experiment tracking,
  model serving/drift monitoring — this is the separate ML/AI Model
  Development and MLOps/ML Platform Engineering roadmap categories per
  `research/taxonomy-roadmap.md`, explicitly not this category's job even
  where the tooling (e.g. a feature store) touches the same warehouse.
- Deep streaming-engine internals (Kafka partition/consumer-group
  mechanics, Flink state-backend/checkpointing internals, exactly-once
  semantics implementation detail) — named only at the decision-signal
  level (when streaming is warranted at all); full streaming-platform
  architecture belongs to the sibling Integration & Event-Driven Systems
  baseline, not yet researched as of this pass.
- Deep data-governance/catalog-tooling architecture (Collibra, Alation,
  Informatica-style enterprise catalogs; fine-grained column-level access
  control systems) — named only where it intersects data contracts/
  lineage above; full catalog/governance-platform comparison is a
  separate, deeper research topic this pass didn't attempt.
- Data mesh implementation mechanics (a full domain-topology design, a
  federated-governance operating model) — named above only as an
  organizational-pattern signal with an honest hype-cycle caveat, not
  researched at implementation depth.
- Cost modeling / cloud data-warehouse pricing comparisons (per-TB/per-
  credit pricing across Snowflake/BigQuery/Databricks) — same no-pricing
  convention as every prior baseline in this repo; qualitative
  positioning only (see the warehouse/lakehouse section's brief mention).
- Numeric benchmark/adoption claims not traceable to a primary source —
  several turned up in search results this pass (e.g. a specific
  "40-60% faster" pipeline-migration figure, several "X% of teams have
  adopted lakehouse" variants beyond the one figure kept with its
  single-source caveat) and were excluded per this baseline's standard;
  see the lakehouse-adoption figure above for the one number kept, with
  its caveat stated explicitly rather than silently upgraded to fact.

## Sources

- Local precedent (not a web source, read directly): `C:\Users\devop\
  GitHub\MEDGraph\medical_institutions\extractors\{base.py,usa.py}` and
  `extraction_monitor.py`; `C:\Users\devop\GitHub\MCPg\benchmarks\
  datasets\load_tpch.py`; directory/grep search across `C:\Users\devop\
  GitHub\*` and `C:\Users\devop\{LitBot,ucum_check,src}` for pandas/
  polars/airflow/dbt/dagster/prefect/great_expectations/pandera/duckdb/
  pyarrow usage — searched and read 2026-08-19
- https://github.com/apache/iceberg — direct fetch: Apache-2.0, 9.2k
  stars, 3.5k forks, 9,086 commits, "format specification stable, new
  features added each release" framing — retrieved 2026-08-19
- https://github.com/delta-io/delta — direct fetch: Apache-2.0, 8.9k
  stars, 2.2k forks, 5,520 commits — retrieved 2026-08-19
- https://github.com/bitol-io/open-data-contract-standard — direct fetch:
  Apache-2.0, current version v3.1.0, 1.1k stars, 607 commits, 91 forks —
  retrieved 2026-08-19
- https://bitol-io.github.io/open-data-contract-standard/v3.0.0/home/ and
  https://bitol.io/odcs-version-3-transforming-data-contracts-with-enhanced-flexibility-integration-and-global-collaboration/
  — ODCS scope and governance (Linux Foundation AI & Data / AIDA User
  Group), v3.0.0 released October 2024 — retrieved 2026-08-19 (search,
  not independently re-verified beyond the repo's own version-number
  confirmation above)
- https://docs.confluent.io/platform/current/schema-registry/fundamentals/data-contracts.html
  and https://www.confluent.io/blog/data-contracts-confluent-schema-registry/
  — Confluent Schema Registry's own data-contracts feature scope (schema +
  quality + migration rules, Kafka-topic-scoped) — retrieved 2026-08-19
- https://www.landskill.com/blog/streaming-vs-batch-processing/,
  https://dataarchitect.studio/essays/batch-vs-streaming/, and
  https://www.systemoverflow.com/learn/etl-elt-patterns/incremental-processing/streaming-vs-batch-incremental-when-to-choose-each
  — batch-vs-streaming latency-tolerance table and the "freshness belongs
  to the decision, not the pipeline" framing, corroborated across
  independent practitioner sources — retrieved 2026-08-19
- https://dagster.io/learn/data-pipeline-orchestration-tools,
  https://medium.com/brenntag-blog/moving-from-scheduled-to-event-driven-data-pipelines-596b02e540dc,
  and https://www.systemoverflow.com/learn/data-pipelines-orchestration/dag-orchestration/choosing-dag-orchestration-vs-alternatives
  — DAG-scheduler vs. event-triggered distinction, the dependency-aware
  framing, and the single-practitioner-reported "~2 days to minutes"
  case study (flagged explicitly as a single case, not a general figure)
  — retrieved 2026-08-19
- https://valohai.com/blog/notebook-to-production/ and
  https://gradientflow.substack.com/p/data-engineering-for-machine-users
  — notebook-to-production "fragmentation tax," hidden-state problem,
  git-diff/CI limitations of `.ipynb` files — retrieved 2026-08-19
- https://xebia.com/blog/test-driven-development-tdd-with-dbt/,
  https://docs.getdbt.com/blog/announcing-unit-testing, and
  https://datacoves.com/post/dbt-test-options — dbt unit tests
  (introduced dbt Core v1.8) vs. data tests distinction, TDD-for-pipelines
  framing — retrieved 2026-08-19
- https://www.thoughtworks.com/insights/blog/data-strategy/the-state-of-data-mesh-in-2026-from-hype-to-hard-won-maturity
  and https://atlan.com/gartner-data-mesh/ — data mesh hype-cycle
  positioning (peak ~2022, trough ~2024, pragmatic-adoption-of-useful-parts
  by 2026), federated-governance framing, "generality underinvestment"
  structural criticism — retrieved 2026-08-19
- https://en.wikipedia.org/wiki/Data_build_tool and
  https://dataskew.io/blog/etl-vs-elt/,
  https://dataworkers.io/resources/etl-vs-elt/ — ELT-as-dominant-pattern
  framing tied to cloud-warehouse compute economics, named ETL-still-
  applies cases (compliance, on-prem, complex non-SQL transforms) —
  retrieved 2026-08-19
- https://www.lucentinnovation.com/resources/it-insights/data-warehouse-vs-data-lake-vs-lakehouse
  and https://amdatalakehouse.substack.com/p/the-2025-and-2026-ultimate-guide
  — lakehouse-as-2025-2026-consensus framing, the "50%+ of teams" adoption
  figure (flagged single-source/not independently re-derived) —
  retrieved 2026-08-19

## Open questions for the user

- The lakehouse-adoption figure ("over half of data teams" per a February
  2026 industry report referenced across secondary sources) was not traced
  to that report's own primary page this pass — only to secondary sources
  citing it. Worth a direct-fetch confirmation at authoring time given how
  load-bearing the lakehouse-as-consensus framing is for this doc, or
  acceptable to keep with the current single-source caveat?
- The "CQRS *is*, by construction, a warehouse" reframing is this
  research's strongest original synthesis (connecting the cross-cutting
  doc's CQRS caution to this category concretely) — confirm that's the
  right level of assertiveness for the authored doc, or whether it should
  be presented more tentatively as "one way to think about it" rather
  than a flat claim.
- Data mesh was scoped to organizational-pattern depth only (impact: med,
  paragraph), given its post-hype-cycle status and this skill's likely
  project-size range. Confirm that's the right depth, or whether a small
  number of projects incubated via this skill will be large/multi-domain
  enough that a fuller data-mesh section is worth the space.
- The notebook-to-production section leans on Jupyter/`.ipynb` specifically
  as the running example. Confirm that's representative enough of "the
  exploratory tool" for the authored doc, or whether it should generalize
  more (e.g. also naming Databricks/Marimo notebooks, which have different
  hidden-state/diffability properties than plain Jupyter).
- Deep streaming-engine architecture and full data-governance/catalog
  tooling were both scoped out this pass as belonging to other (not-yet-
  researched or out-of-scope) categories. Confirm that division is correct
  rather than something this category should absorb given how often
  "streaming" and "governance" came up adjacent to core search results.

## Resolutions (Checkpoint D review, 2026-08-19)

- **Lakehouse-adoption figure**: keep with its current single-source
  caveat; direct-fetch verification of the underlying report deferred to
  Phase 2 authoring, per the standing verify-before-publish policy.
- **"CQRS is, by construction, a warehouse" reframing**: keep as an
  assertive claim, not softened to "one way to think about it" — matches
  this repo's established opinionated-default-with-reasoning convention.
- **Data mesh depth**: confirmed as-is (paragraph-level, organizational-
  pattern framing).
- **Notebook-to-production generalization**: keep Jupyter as the primary
  worked example; add a brief note at authoring time that Databricks/Marimo
  notebooks have different hidden-state/diffability properties, rather
  than fully generalizing away from the concrete Jupyter case.
- **Streaming/governance scope boundary**: confirmed correct. Streaming is
  now formally resolved to the Integration & Event-Driven Systems baseline
  (see `research/skill-flow-decisions.md`'s cross-checkpoint conflict
  resolution) rather than left ambiguous between the two docs. Deep
  data-governance/catalog tooling stays out of scope as originally scoped.

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/data-analytics-platforms.md
  — est. 460–540 lines (11 subsections per the In-scope list above,
  several as tables; the warehouse/lakehouse, ELT/ETL, notebook-to-
  production, and testing sections likely the longest given worked-example
  and table density, roughly matching the other two authored-category
  baselines' actual length).
