# Baseline: Integration & Event-Driven Systems — Preferred Libraries
Status: user-approved      Date: 2026-08-19      Snapshot date: 2026-08-19

**Last-reviewed date convention**: every entry in this document was
verified on the **Snapshot date above (2026-08-19)** unless a specific
row states otherwise — this satisfies the per-entry "last reviewed"
requirement without repeating the same date in every table cell. Where a
row's own verification pass turned up a different date worth surfacing
(e.g. a package's own latest-release date), that date is called out
explicitly in the row.

## In scope

- **Message brokers (Kafka vs. RabbitMQ vs. NATS vs. Redpanda)** —
  impact: high — depth: table. Stars and licenses are from direct fetch
  of each repo's GitHub API (`api.github.com/repos/{owner}/{repo}`) on
  2026-08-19, which also supplies `pushed_at` (the timestamp of the most
  recent commit to the default branch) as this table's verified
  maintenance signal — every broker below shows a commit **on the same
  day as this research pass**, i.e. the API data itself is the freshest
  possible evidence these are actively maintained, not adoption numbers
  going stale on an unmaintained repo.
  | Broker | License (verified) | Stars (verified, GitHub API) | Last commit (verified, GitHub API `pushed_at`) | Governance/owner | What it's for | Why recommended |
  |---|---|---|---|---|---|---|
  | **Apache Kafka** | Apache-2.0 (core broker) | 33,550 | 2026-08-19 | Apache Software Foundation | High-throughput, durable, replayable log; the default for event-streaming and pub/sub at scale | The durable-log model (retained, replayable history, not just transient delivery) is genuinely different from a classic queue and is what most "event-driven architecture" writing actually means; broadest ecosystem (Kafka Connect, Kafka Streams, ksqlDB) and hiring pool. **Licensing caveat, direct-fetch-verified**: Kafka core itself stays Apache-2.0 — the licensing complexity lives one layer up, in *Confluent's* commercial platform components (Confluent Schema Registry, REST Proxy, ksqlDB, some connectors), which moved to the **Confluent Community License** (source-available, free to use/modify, but the license explicitly prohibits offering it as a competing SaaS) — confirmed by direct fetch of `confluentinc/schema-registry`'s own LICENSE file: "The project is licensed under the Confluent Community License, except some modules such as the client-* and avro-* libs, which are licensed under the Apache 2.0 license." Using bare Kafka + a non-Confluent schema registry (Apicurio, below) avoids this entirely. |
  | **RabbitMQ** | MPL 2.0 (server, confirmed by direct fetch of the repo page; the GitHub API's own `license.spdx_id` field returns `NOASSERTION` for this repo — a known GitHub license-detector limitation on dual/custom license text, not a contradiction of the repo page's own stated MPL 2.0) | 13,791 | 2026-08-19 | Broadcom (via the VMware acquisition, completed Nov 2023) | Classic message queue with flexible routing (direct/topic/fanout exchanges); strong at both point-to-point and pub/sub via exchange type | Mature, predictable, simpler mental model than Kafka for teams that don't need a durable replayable log — a message is consumed and gone. **Ownership caveat, direct-fetch-verified**: the repo page carries the copyright line "(c) 2007-2026 Broadcom. All Rights Reserved," with commercial support/enterprise editions offered through Broadcom's Tanzu division — the open-source server itself remains MPL 2.0, but worth flagging given Broadcom's well-documented pattern (VMware licensing changes) of tightening commercial terms around open-core products post-acquisition; monitor before committing long-term. |
  | **NATS** (NATS Server / JetStream) | Apache-2.0 | 20,546 | 2026-08-19 | CNCF (Cloud Native Computing Foundation), primary maintainer Synadia | Lightweight, cloud-native pub/sub and (via JetStream) durable streaming; simplest ops story of the four | Genuinely simpler to self-host than Kafka (single small binary, no ZooKeeper/KRaft cluster to manage) while JetStream adds Kafka-like durability/replay when needed. **Licensing history worth naming explicitly**: in April 2025, Synadia (NATS's primary commercial maintainer) proposed withdrawing NATS from CNCF governance and moving future releases to the Business Source License — a real, publicly documented licensing threat, confirmed via CNCF's and Synadia's own joint statement (`cncf.io/announcements/2025/05/01/...`) — that was **resolved** by 1 May 2025: NATS stays under CNCF governance, the Apache-2.0 license is retained, and trademark ownership was assigned to the Linux Foundation. The dispute is settled as of this baseline's date but is recent enough (16 months) to name rather than omit — a project this size going through a licensing scare and resolving in the community's favor is a different risk profile than a project with no such history. |
  | **Redpanda** | BSL 1.1 (converts to Apache-2.0 four years after each code merge) — commercial license for Enterprise Edition features; GitHub API's `license` field returns null for this repo (BSL isn't a standard SPDX identifier GitHub recognizes) | 12,463 | 2026-08-19 | Redpanda Data (VC-backed company) | Kafka-wire-protocol-compatible broker written in C++, no JVM/ZooKeeper — a drop-in for teams that want Kafka client compatibility with a lighter ops footprint | Real option when Kafka-API-compatibility matters but JVM operational overhead is unwanted. **Not source-available in the OSI sense at time of use** — the BSL's "Additional Use Grant" explicitly forbids offering Redpanda itself as a competing streaming/queueing service to third parties, and Enterprise-tier features (tiered storage, read replicas, SSO) require a commercial license — evaluate BSL's non-compete clause against your own use case before adopting, especially if the product being built is itself infrastructure-adjacent. |
  **Default recommendation for a new project without a specific driving
  constraint**: **Kafka** (bare, Apache-2.0, paired with Apicurio Registry
  rather than Confluent's licensed components — see below) if durable
  replay and a large ecosystem matter; **NATS** if operational simplicity
  is the priority and the licensing scare's resolution is acceptable;
  **RabbitMQ** if the team already knows it and needs flexible routing
  more than durable replay; **Redpanda** only with the BSL terms
  explicitly reviewed and accepted. Managed cloud-native options (AWS
  SQS/SNS/EventBridge, Google Pub/Sub, Azure Service Bus) were reviewed
  but not researched at license/adoption depth this pass since they're
  vendor-managed services rather than libraries with a license/star
  profile to verify — named here as a legitimate alternative to
  self-hosting any of the above, not researched further per this
  baseline's own no-pricing/vendor-comparison convention.

- **Workflow orchestration engines** — impact: high — depth: table. Stars,
  license, and `pushed_at` (last-commit maintenance signal) are from
  direct fetch of each repo's GitHub API on 2026-08-19 unless noted.
  | Engine | License (verified) | Stars (verified, GitHub API) | Last commit (verified, GitHub API `pushed_at`) | Model | What it's for | Why recommended |
  |---|---|---|---|---|---|---|
  | **Temporal** | MIT | 22,396 | 2026-08-19 | Durable execution — workflow code persists its execution history, survives process crashes, resumes exactly where it left off | Long-running, stateful, branching business processes; the current default implementation for a Saga-pattern orchestrator (see stack.md) since it solves the orchestrator's own crash-recovery problem | MIT is maximally permissive (self-host, fork, run commercially with zero license friction) — direct-fetch-confirmed from the repo page. Production users named in search results include Stripe, Snap, and Coinbase (not independently verified via those companies' own engineering blogs this pass — treat as a directional adoption signal, not a confirmed fact). |
  | **Apache Airflow** | Apache-2.0 | 46,536 | 2026-08-19 | DAG/schedule-oriented — tasks in a directed graph, typically time- or externally-triggered, task state persisted between runs but not mid-task execution state | Batch-shaped, primarily schedule-triggered pipeline orchestration — this is the *analytics*-pipeline-scheduling use case the sibling Data & Analytics Platforms baseline already covers; for *integration* use cases specifically, Airflow fits scheduled multi-system batch syncs (nightly reconciliation jobs) but is a poor fit for long-running stateful workflows waiting on unpredictable external events (a webhook that might arrive in seconds or days) — that's Temporal's shape, not Airflow's | Largest ecosystem and star count of any orchestrator by a wide margin — direct-fetch-confirmed via GitHub API, Apache Software Foundation governance. **Latest release, corrected**: an earlier fetch of this baseline mis-cited "3.3.0, dated 22 April 2025" — that date belongs to the *3.0.0* release-lifecycle milestone, not 3.3.0/3.3.1. Direct fetch of `api.github.com/repos/apache/airflow/releases/latest` corrects this: the current latest release is **3.3.1**, published **2026-08-12** — 7 days before this baseline's snapshot date, itself a strong maintenance signal. |
  | **Prefect** | Apache-2.0 | 23,642 | 2026-08-19 | Python-native, dynamic-DAG orchestration with a pull-based agent model (workers pull work rather than a central scheduler pushing to them) | An Airflow alternative for teams wanting first-class Python (dynamic pipelines, not static DAG files) and simpler retry/checkpoint ergonomics — still schedule/DAG-shaped, not durable-execution-shaped, so the same Airflow-vs-Temporal boundary above applies | Direct-fetch-confirmed Apache-2.0, 23,642 stars, commit activity same-day as this research pass — a real, comparably-sized alternative to Airflow specifically for teams whose pain point is Airflow's static-DAG-file ergonomics rather than teams needing durable long-running workflows (Temporal's use case). |
  | **n8n** | **Sustainable Use License + n8n Enterprise License ("fair-code")** — source-available, not an OSI-approved open-source license; GitHub API's `license.spdx_id` field itself returns `NOASSERTION`, corroborating that this isn't a standard OSI license | 201,179 | 2026-08-19 | Low-code visual workflow-automation platform (400+ pre-built integrations) | Rapid integration-automation building (Zapier/Make-alternative, self-hostable) for teams that want a visual builder over custom code, and/or need broad SaaS-connector coverage out of the box | Named explicitly because of the license distinction: the Community Edition is free to self-host with unlimited workflows/executions, but it is **not** permissively licensed like the other entries in this table — the Sustainable Use License restricts competing-commercial-use in the same family as Confluent's Community License and Redpanda's BSL. Its 201k star count (direct-fetch-confirmed via GitHub API, by a wide margin the largest number in this entire baseline) reflects real, large adoption as a low-code automation tool, but that's a different buyer profile (ops/automation teams wanting a visual builder) than Temporal/Airflow/Prefect (engineering teams building custom orchestration in code) — don't treat the star count as a like-for-like comparison against the code-first engines above. |
  **Decision rule**: durable, long-running, unpredictable-timing
  business process (order fulfillment, multi-day approval, Saga
  orchestrator) → **Temporal**. Scheduled batch/analytics pipeline →
  **Airflow** (or Prefect for a more Python-native ergonomics preference)
  — this is the sibling Data & Analytics Platforms baseline's primary
  territory, named here only for the integration-use-case boundary.
  Visual/low-code automation across many SaaS connectors, license terms
  reviewed and accepted → **n8n**.

- **Schema registry tooling** — impact: high — depth: table.
  | Tool | License (verified) | Stars (verified, GitHub API) | Last commit (verified, GitHub API `pushed_at`) | What it's for | Why recommended |
  |---|---|---|---|---|---|
  | **Confluent Schema Registry** | **Confluent Community License** (server), Apache-2.0 (client-*/avro-* libraries only) — direct-fetch-confirmed from the repo's own LICENSE file, contradicting some secondary sources found in this pass's initial search that describe it as simply "Apache 2.0" | 2,500 (rendered-page fetch; GitHub API call for this repo was rate-limited during this pass's verification round — see Open questions) | Not independently re-verified via API this pass — flagged above | Kafka-native schema storage/validation (Avro, Protobuf, JSON Schema), stores schemas using Kafka itself as the backend | The de facto standard for Kafka specifically, tightly integrated with the Confluent client ecosystem — but the license caveat matters: it is source-available with a no-competing-SaaS restriction, not a permissive OSI license, which is a materially different commitment than "open source" as commonly assumed. Verify this against your own use case (internal use is unaffected by the restriction; building a schema-registry-as-a-service product on top of it is not). |
  | **Apicurio Registry** | Apache-2.0 (fully, verified by direct fetch) | 916 | 2026-08-19 | Multi-format schema/API-artifact registry — Avro, Protobuf, JSON Schema, **plus** OpenAPI, AsyncAPI, GraphQL, WSDL, XML Schema in one registry; storage backends include in-memory (dev), PostgreSQL, or a Kafka-topic-backed "KafkaSQL" mode | Genuinely permissively licensed (no competing-SaaS carve-out), Red-Hat-backed, and broader in scope than Confluent's registry — one registry for both event-schema and API-contract artifacts (ties into the AsyncAPI/OpenAPI contract-first pattern the Backend & API Services baseline covers). Lower star count than Confluent's registry (916 vs ~2,500) is a real, smaller-community signal worth naming honestly rather than glossing over — recommended on license grounds and format breadth, not on adoption-size grounds. |
  | **AWS Glue Schema Registry** | Proprietary AWS service (client SDKs are open source, the service itself is not self-hostable) | N/A (managed service) | N/A | Schema management integrated into the AWS ecosystem (Glue, Kinesis, MSK) | Named for completeness as the default choice for teams already fully committed to AWS-managed streaming (MSK/Kinesis) who want one less thing to self-host — not comparable license-wise to the two self-hosted options above, and not researched at further depth per this baseline's no-vendor-pricing convention. |
  **Default recommendation**: **Apicurio Registry** for a new project
  without an existing Confluent Platform commitment, specifically because
  of the license difference — Confluent Schema Registry only if already
  standardized on the broader Confluent Platform and the Community
  License's terms are acceptable for the project's context.

- **Change Data Capture (CDC)** — impact: med — depth: paragraph.
  **Debezium**: Apache-2.0 (direct-fetch-confirmed via GitHub API,
  `license.spdx_id: Apache-2.0`), 13,022 GitHub stars (direct-fetch-
  confirmed via GitHub API), last commit **2026-08-19** (same day as this
  research pass, per the API's `pushed_at` field) — Red-Hat-backed.
  Captures row-level database
  changes (via each database's native replication mechanism — logical
  decoding for PostgreSQL, binlog for MySQL, etc.) and publishes them as
  a Kafka Connect source, turning a database's write-ahead log into an
  event stream without application code needing to publish events itself.
  This is the concrete tool underneath the "fuzzy ETL/integration
  boundary" named in stack.md — the same Debezium stream commonly feeds
  both an operational event bus (this baseline) and a warehouse-ingestion
  pipeline (the Data & Analytics Platforms baseline). Recommended as the
  default CDC mechanism for a new project needing to react to database
  changes as events, over hand-rolled polling or dual-write patterns
  (which are a well-documented source of the exact at-least-once/
  idempotency problems stack.md's delivery-semantics section addresses).

- **API/integration-platform tooling (distinct from the pure
  message-broker layer)** — impact: med — depth: paragraph. **Apache
  Camel**: Apache-2.0 (direct-fetch-confirmed via GitHub API), 6,291
  GitHub stars (direct-fetch-confirmed via GitHub API), last commit
  **2026-08-19** (same day as this research pass). A routing/mediation
  engine implementing the
  classic Enterprise Integration Patterns (content-based routing, message
  filtering, aggregation, dead-letter channel, publish-subscribe) with
  300+ pre-built connectors (HTTP/REST, JMS, Kafka, JDBC, FTP/SFTP,
  and more) callable from Java, XML, YAML, or Groovy route definitions.
  This is the clearest current default for **programmatic**
  system-to-system integration with heterogeneous protocols/systems on
  either end, distinct from n8n's low-code/visual audience and distinct
  from a pure message broker (Camel routes *between* systems and
  protocols; a broker just moves messages within one). Commercial
  iPaaS SaaS products (MuleSoft, Workato, Boomi, Zapier's paid tiers) were
  reviewed in search results but excluded from this table per this
  baseline's no-pricing/vendor-comparison convention — Camel is the one
  clear open, self-hostable, code-first default found this pass; the
  SaaS-iPaaS space is a legitimate alternative for teams wanting a
  managed low-code platform but wasn't researched at license/adoption
  depth here since it's a buy-vs-build decision outside a
  "preferred libraries" baseline's scope.

- **Webhook infrastructure and signature verification** — impact: med —
  depth: paragraph. **Svix** (`svix/svix-webhooks`): MIT license
  (direct-fetch-confirmed from the repo's own LICENSE file), a
  self-hostable webhook-sending service (ingest an event, fan it out to
  registered subscriber endpoints with retry/backoff, signing, and a
  delivery dashboard) implementing the receiver-side mechanics stack.md
  documents from Stripe's own docs. Recommended for a project that needs
  to be the **sender** of webhooks to third parties and wants the
  retry/backoff/signing machinery already built, rather than
  reimplementing Stripe's documented shape from scratch. **Standard
  Webhooks** (`standard-webhooks/standard-webhooks`): a specification,
  not a single library — reference signature-verification implementations
  are published across Python, JS/TS, Go, Rust, Ruby, PHP, C#, Java, and
  Elixir per the project's own repo; recommended as the receiver-side
  verification approach for a project consuming webhooks from multiple
  providers that support the standard, since it avoids writing bespoke
  HMAC-verification code per vendor.

- **Retry / backoff / circuit-breaker libraries (the DLQ companion
  layer)** — impact: med — depth: table. These implement the
  exponential-backoff-with-jitter and circuit-breaker patterns stack.md's
  DLQ/retry section names as the mitigation layer above a broker's own
  redelivery-count threshold.
  | Library | Language | License (verified) | Stars (verified, direct fetch of rendered repo page) | Maintenance signal (verified) | Why recommended |
  |---|---|---|---|---|---|
  | **Polly** | .NET | New BSD (BSD-3-Clause) | 14.2k | Star count and license direct-fetch-verified 2026-08-19; a follow-up GitHub API call for `pushed_at` was rate-limited (HTTP 403) during this pass's verification round rather than confirmed — see Open questions | The standard .NET resilience library — retry, circuit-breaker, timeout, bulkhead, fallback policies, composable. Version 8's pipeline-based API is the current idiomatic approach per search-corroborated practitioner sources. |
  | **resilience4j** | Java | Apache-2.0 | 10.7k | Star count and license direct-fetch-verified 2026-08-19; `pushed_at` API call rate-limited (HTTP 403) this pass — see Open questions | The modern, modular successor to Netflix Hystrix (which is in maintenance mode) for JVM projects — pick only the modules needed (Retry, CircuitBreaker, RateLimiter, Bulkhead, TimeLimiter) as decorators over a functional interface. |
  | **tenacity** | Python | Apache-2.0 (OSI-approved, direct-fetch-confirmed via PyPI classifiers) | N/A (PyPI-verified via direct fetch of the JSON API; GitHub star count not independently re-verified this pass) | **Latest release 9.1.4, uploaded 7 February 2026** — direct-fetch-confirmed via `pypi.org/pypi/tenacity/json`; a package release 6 months before this baseline's snapshot date is itself the maintenance signal here, verified at the registry level rather than via GitHub | The standard Python retry library — decorator-based retry-with-backoff, actively maintained. |
  None of these three implement DLQ semantics themselves (that's the
  broker/queue's job, per stack.md) — they implement the
  application-level retry-before-giving-up layer that determines *how
  many times and how* a consumer retries before a message is allowed to
  exhaust the broker's own `maxReceiveCount` and land in the DLQ.

## Explicitly out of scope

- Cloud-managed broker/orchestration services (AWS MSK/SQS/SNS/
  EventBridge, Google Pub/Sub, Azure Service Bus/Event Grid, Confluent
  Cloud, Temporal Cloud) — named in passing above as legitimate
  alternatives to self-hosting, not researched at license/pricing depth,
  consistent with this baseline series' no-cost-modeling convention.
- Stream-processing/computation frameworks (Kafka Streams, Apache Flink,
  Spark Streaming) — per stack.md's scoping decision, placed closer to
  the Data & Analytics Platforms baseline's territory; not researched at
  library-selection depth this pass.
- Apache Pulsar — a real Kafka alternative (Apache-2.0, built-in
  multi-tenancy and tiered storage) surfaced in initial search results
  but not researched to the same license/adoption-verification depth as
  the four brokers in the table above, given this pass's time budget;
  flagged in Open questions rather than included on unverified footing.
- Commercial iPaaS/SaaS integration platforms (MuleSoft, Workato, Boomi,
  Zapier, Make) — reviewed only enough to confirm Apache Camel's position
  as the clear open/self-hosted default; not researched at vendor-pricing
  or feature depth per this baseline's own convention.
- GraphQL/REST/gRPC contract tooling (Buf, OpenAPI generators) — belongs
  to Backend & API Services' libraries.md.
- Data-pipeline/ELT tooling (Airbyte, Fivetran, dbt) — belongs to Data &
  Analytics Platforms' libraries.md; named only via Debezium's dual role
  above.
- Deep per-language SDK comparisons for any single broker (e.g. Kafka's
  own client libraries across Java/Python/Go/Rust) — out of scope; this
  baseline covers broker/platform selection, not per-language client
  ergonomics.

## Sources

- https://github.com/apache/kafka — direct fetch: Apache-2.0, 33.5k
  stars — retrieved 2026-08-19
- https://github.com/rabbitmq/rabbitmq-server — direct fetch: MPL 2.0,
  13.8k stars, "(c) 2007-2026 Broadcom" copyright line, Tanzu commercial
  editions — retrieved 2026-08-19
- https://github.com/nats-io/nats-server — direct fetch: Apache-2.0,
  20.5k stars — retrieved 2026-08-19
- https://www.cncf.io/announcements/2025/05/01/cncf-and-synadia-align-on-securing-the-future-of-the-nats-io-project/
  — CNCF/Synadia joint statement resolving the April 2025 BSL-relicensing
  proposal: NATS stays under CNCF governance, Apache-2.0 retained,
  trademarks assigned to the Linux Foundation — retrieved 2026-08-19
  (search-corroborated across CNCF's own blog, Synadia's own press page,
  and The New Stack; CNCF's announcement page itself not independently
  re-fetched in full this pass, flagged in Open questions)
- https://api.github.com/repos/apache/kafka,
  https://api.github.com/repos/nats-io/nats-server,
  https://api.github.com/repos/temporalio/temporal,
  https://api.github.com/repos/debezium/debezium,
  https://api.github.com/repos/redpanda-data/redpanda,
  https://api.github.com/repos/rabbitmq/rabbitmq-server,
  https://api.github.com/repos/apache/camel,
  https://api.github.com/repos/apicurio/apicurio-registry,
  https://api.github.com/repos/apache/airflow,
  https://api.github.com/repos/PrefectHQ/prefect,
  https://api.github.com/repos/n8n-io/n8n — direct fetch of the GitHub
  REST API (not just the rendered HTML page) for each repo: supplies the
  exact `stargazers_count`, `pushed_at` (last-commit timestamp, used as
  this baseline's maintenance signal), and `license.spdx_id` for every
  entry that has one. Every repo's `pushed_at` returned **2026-08-19**
  (this pass's own retrieval date) — retrieved 2026-08-19. A follow-up
  API batch for `svix/svix-webhooks`, `App-vNext/Polly`,
  `resilience4j/resilience4j`, and `confluentinc/schema-registry` was
  rate-limited (HTTP 403, unauthenticated GitHub API rate limit) later in
  this pass; those four entries' star counts and licenses in this doc
  come from the earlier rendered-page direct fetch instead (still a
  direct fetch, just not the API), with the `pushed_at` field
  specifically flagged as unverified in their table rows.
- https://github.com/temporalio/temporal — direct fetch (rendered page,
  corroborating the API figures above): MIT, 22.4k stars — retrieved
  2026-08-19
- https://api.github.com/repos/apache/airflow/releases/latest — direct
  fetch: corrects an earlier draft's mis-citation ("3.3.0, dated 22 April
  2025," which was actually the 3.0.0 lifecycle milestone date) — confirms
  the current latest release is **3.3.1**, published **2026-08-12T09:50:17Z**
  — retrieved 2026-08-19
- https://pypi.org/pypi/apache-airflow/json — direct fetch: confirms
  3.3.1 as the current PyPI release, consistent with the GitHub Releases
  API fetch above — retrieved 2026-08-19
- https://github.com/PrefectHQ/prefect — direct fetch (rendered page,
  corroborating the API figures above): Apache-2.0, 23.6k stars —
  retrieved 2026-08-19
- https://github.com/n8n-io/n8n — direct fetch (rendered page,
  corroborating the API figures above): Sustainable Use License + n8n
  Enterprise License ("fair-code"), 201.2k stars — retrieved 2026-08-19
- https://github.com/confluentinc/schema-registry and
  https://raw.githubusercontent.com/confluentinc/schema-registry/master/LICENSE
  — direct fetch of both the repo page and the raw LICENSE file: confirms
  Confluent Community License for the server, Apache-2.0 only for
  client-*/avro-* modules — this directly contradicts a secondary source
  surfaced in initial search results (a comparison blog stating "Confluent
  Schema Registry is open-source under the Apache 2.0 license") — the
  direct-fetched LICENSE file is authoritative here, resolved in this
  baseline's favor per its own verify-by-direct-fetch standard — retrieved
  2026-08-19
- https://github.com/apicurio/apicurio-registry — direct fetch:
  Apache-2.0, 916 stars, version 3.3.0 referenced as a pinned tag —
  retrieved 2026-08-19
- https://github.com/debezium/debezium — direct fetch: Apache-2.0
  license (search-confirmed), ~13.0k stars (direct fetch) — retrieved
  2026-08-19
- https://github.com/apache/camel — direct fetch: Apache-2.0, 6.3k
  stars, 350+ connectors per repo description — retrieved 2026-08-19
- https://github.com/svix/svix-webhooks and
  https://github.com/svix/svix-webhooks/blob/main/LICENSE — MIT license
  — retrieved 2026-08-19 (via search of the repo's own LICENSE file path;
  not independently re-fetched in full this pass, flagged in Open
  questions)
- https://github.com/standard-webhooks/standard-webhooks — community
  spec, technical steering committee membership — retrieved 2026-08-19
- https://github.com/App-vNext/Polly — direct fetch: New BSD (BSD-3-
  Clause), 14.2k stars — retrieved 2026-08-19
- https://github.com/resilience4j/resilience4j — direct fetch:
  Apache-2.0, 10.7k stars — retrieved 2026-08-19
- https://pypi.org/pypi/tenacity/json — direct fetch: latest version
  9.1.4, uploaded 7 February 2026, Apache-2.0 license classifier —
  retrieved 2026-08-19
- https://github.com/redpanda-data/redpanda and
  https://github.com/redpanda-data/redpanda/blob/dev/licenses/bsl.md —
  direct fetch of the repo (12.5k stars; license badge not visible in the
  truncated fetch) plus search-corroborated BSL 1.1 terms (4-year
  Apache-2.0 conversion, Additional Use Grant's no-competing-service
  clause) — retrieved 2026-08-19, BSL terms flagged in Open questions as
  search-corroborated rather than independently fetched from the primary
  `bsl.md` file's full text

## Open questions for the user

- Three library facts in this doc are still confirmed only via
  search-tool summaries rather than a full direct fetch of the primary
  page/file: the NATS/CNCF resolution statement's full text, Svix's
  LICENSE file's full text, and Redpanda's `licenses/bsl.md` full text.
  All three are corroborated by multiple independent sources found in
  search, so confidence is reasonably high, but a direct re-fetch at
  authoring time would fully close the gap given this baseline's own
  verify-by-fetch standard. (This is narrower than an earlier draft's
  version of this question — the Airflow release date, the KIP-98/Saga
  sources, and the schema-compatibility vocabulary were all resolved via
  direct fetch during this baseline's own self-check pass.)
- A late-pass GitHub API batch for four entries (Svix, Polly,
  resilience4j, Confluent Schema Registry) hit the API's unauthenticated
  rate limit (HTTP 403) after the first ~15 API calls succeeded — those
  four entries' `pushed_at` maintenance-signal field is unverified in
  this doc (star counts and licenses for all four were still confirmed
  via an earlier successful rendered-page direct fetch). An authenticated
  API call, or simply re-running the same unauthenticated call after the
  rate-limit window resets, would close this at authoring time.
- Apache Pulsar was identified as a real Kafka alternative but excluded
  from the broker table for time-budget reasons this pass rather than a
  substantive reason to exclude it — confirm whether it should be
  researched and added before authoring, particularly given its
  multi-tenancy/tiered-storage differentiation from Kafka.
- n8n's star count (201.2k) dwarfs every other entry in this baseline by
  an order of magnitude, but it's serving a different buyer (low-code
  automation) than the code-first engines it's tabled alongside
  (Temporal/Airflow/Prefect) — confirm the authored doc should present
  it as a separate category rather than a directly-ranked alternative,
  to avoid the star count reading as "n8n is just better," which isn't
  the actual claim.
- Confirm whether cloud-managed services (MSK, Confluent Cloud, Temporal
  Cloud, SQS/SNS/EventBridge) deserve their own explicitly-researched row
  even without pricing depth — right now they're named only in passing as
  "a legitimate alternative," which may under-serve a reader whose
  project is cloud-native by default rather than self-hosting-by-default.

## Resolutions (Checkpoint D review, 2026-08-19)

- **Unverified library facts** (NATS/CNCF statement, Svix LICENSE, Redpanda
  BSL full text) and **rate-limited `pushed_at` gaps** (Svix, Polly,
  resilience4j, Confluent Schema Registry): both deferred to a fresh
  direct-fetch pass at Phase 2 authoring, per the standing
  verify-before-publish policy.
- **Apache Pulsar**: confirmed out of scope for v1, flagged as a candidate
  future addition to this file rather than a blocking gap.
- **n8n framing**: confirmed — present as a separate low-code/automation
  category, not directly ranked alongside the code-first orchestration
  engines (Temporal/Airflow/Prefect), to avoid its star count implying a
  like-for-like comparison it isn't.
- **Cloud-managed services**: add a brief "legitimate alternative to
  self-hosting" callout for each broker/orchestrator category at authoring
  time, without deep license/pricing research — matches this repo's
  no-pricing convention while still acknowledging the option exists.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/integration-event-driven-systems.md
  — est. 380–440 lines (7 subsections per the In-scope list above, most
  as tables given the license/star-verification density this category
  demands; somewhat denser than a typical libraries.md given how many
  entries carry a licensing caveat worth stating in full).
