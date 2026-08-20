# Integration & Event-Driven Systems — Preferred Libraries

**Last-reviewed date convention**: every entry in this document was
verified on **2026-08-19**, the baseline's original snapshot date, unless
a specific row states otherwise. A fresh direct-fetch pass on **2026-08-20**
re-verified the four rows the baseline had flagged as rate-limited (Svix,
Polly, resilience4j, Confluent Schema Registry) and added the new
stream-processing-engine rows — those rows carry the 2026-08-20 date
explicitly. Where a row's own verification pass turned up a different
date worth surfacing (e.g. a package's own latest-release date), that
date is called out explicitly in the row.

## Table of contents

1. [Message brokers](#message-brokers-kafka-vs-rabbitmq-vs-nats-vs-redpanda)
2. [Stream processing engines](#stream-processing-engines)
3. [Workflow orchestration engines](#workflow-orchestration-engines)
4. [Schema registry tooling](#schema-registry-tooling)
5. [Change Data Capture](#change-data-capture-cdc)
6. [API/integration-platform tooling](#apiintegration-platform-tooling-distinct-from-the-pure-message-broker-layer)
7. [Webhook infrastructure and signature verification](#webhook-infrastructure-and-signature-verification)
8. [Retry / backoff / circuit-breaker libraries](#retry--backoff--circuit-breaker-libraries-the-dlq-companion-layer)
9. [Explicitly out of scope](#explicitly-out-of-scope)
10. [Sources](#sources)

## Message brokers (Kafka vs. RabbitMQ vs. NATS vs. Redpanda)

Stars and licenses are from direct fetch of each repo's GitHub API
(`api.github.com/repos/{owner}/{repo}`), which also supplies `pushed_at`
(the timestamp of the most recent commit to the default branch) as this
table's verified maintenance signal.

| Broker | License (verified) | Stars (verified) | Last commit (verified) | Governance/owner | What it's for | Why recommended |
|---|---|---|---|---|---|---|
| **Apache Kafka** | Apache-2.0 (core broker) | 33,560 | 2026-08-19 | Apache Software Foundation | High-throughput, durable, replayable log; the default for event-streaming and pub/sub at scale | The durable-log model (retained, replayable history, not just transient delivery) is genuinely different from a classic queue and is what most "event-driven architecture" writing actually means; broadest ecosystem (Kafka Connect, Kafka Streams, ksqlDB) and hiring pool. **Licensing caveat**: Kafka core itself stays Apache-2.0 — the licensing complexity lives one layer up, in *Confluent's* commercial platform components (Confluent Schema Registry, REST Proxy, ksqlDB, some connectors), which moved to the **Confluent Community License** (source-available, free to use/modify, but the license explicitly prohibits offering it as a competing SaaS) — confirmed by direct fetch of `confluentinc/schema-registry`'s own LICENSE file: "The project is licensed under the Confluent Community License, except some modules such as the client-* and avro-* libs, which are licensed under the Apache 2.0 license." Using bare Kafka with a non-Confluent schema registry (Apicurio, below) avoids this entirely. |
| **RabbitMQ** | MPL 2.0 (server, confirmed by direct fetch of the repo page; the GitHub API's own `license.spdx_id` field returns `NOASSERTION` for this repo — a known GitHub license-detector limitation on dual/custom license text, not a contradiction of the repo page's own stated MPL 2.0) | 13,791 | 2026-08-19 | Broadcom (via the VMware acquisition, completed Nov 2023) | Classic message queue with flexible routing (direct/topic/fanout exchanges); strong at both point-to-point and pub/sub via exchange type | Mature, predictable, simpler mental model than Kafka for teams that don't need a durable replayable log — a message is consumed and gone. **Ownership caveat**: the repo page carries the copyright line "(c) 2007-2026 Broadcom. All Rights Reserved," with commercial support/enterprise editions offered through Broadcom's Tanzu division — the open-source server itself remains MPL 2.0, but worth flagging given Broadcom's well-documented pattern (VMware licensing changes) of tightening commercial terms around open-core products post-acquisition; monitor before committing long-term. |
| **NATS** (NATS Server / JetStream) | Apache-2.0 | 20,546 | 2026-08-19 | CNCF (Cloud Native Computing Foundation), primary maintainer Synadia | Lightweight, cloud-native pub/sub and (via JetStream) durable streaming; simplest ops story of the four | Genuinely simpler to self-host than Kafka (single small binary, no ZooKeeper/KRaft cluster to manage) while JetStream adds Kafka-like durability/replay when needed. **Licensing history, direct-fetch-confirmed this pass**: in April 2025, Synadia (NATS's primary commercial maintainer) proposed withdrawing NATS from CNCF governance and moving future releases to the Business Source License — a real, publicly documented licensing threat — that was **resolved** by 1 May 2025. Direct fetch of CNCF's own joint statement confirms the resolution's exact terms: "NATS project's infrastructure and assets — including the NATS.io domain name and GitHub repositories — will continue to be held by CNCF," development continues "under the Apache-2.0 license," and "Synadia has agreed to assign its two NATS trademark registrations to the Linux Foundation," all under a stated commitment to "open collaboration, neutral governance, and shared ownership." The dispute is settled as of this baseline's date but is recent enough (16 months) to name rather than omit — a project this size going through a licensing scare and resolving in the community's favor is a different risk profile than a project with no such history. |
| **Redpanda** | BSL 1.1 (converts to Apache-2.0 automatically at whichever comes first of four years from each release's date, or the fifth anniversary of initial public distribution) — commercial license for Enterprise Edition features; GitHub API's `license` field returns null for this repo (BSL isn't a standard SPDX identifier GitHub recognizes) | 12,463 | 2026-08-19 | Redpanda Data (VC-backed company) | Kafka-wire-protocol-compatible broker written in C++, no JVM/ZooKeeper — a drop-in for teams that want Kafka client compatibility with a lighter ops footprint | Real option when Kafka-API-compatibility matters but JVM operational overhead is unwanted. **Not source-available in the OSI sense at time of use**: direct fetch of the license file's own terms confirms the Additional Use Grant permits "copy, modify, create derivative works, redistribute, and make non-production use of the Licensed Work," but explicitly forbids operating Redpanda as a "Streaming or Queuing Service" — a commercial offering letting third parties access its functionality by creating topics, a restriction that specifically names "providers of infrastructure services, such as cloud services, hosting services, data center services." Production use outside that grant requires a commercial license, and violation "automatically terminates all rights under the license for all versions." Enterprise-tier features (tiered storage, read replicas, SSO) require a commercial license regardless. Evaluate the non-compete clause against your own use case before adopting, especially if the product being built is itself infrastructure-adjacent. |

**Default recommendation for a new project without a specific driving
constraint**: **Kafka** (bare, Apache-2.0, paired with Apicurio Registry
rather than Confluent's licensed components — see below) if durable
replay and a large ecosystem matter; **NATS** if operational simplicity
is the priority and the licensing scare's resolution is acceptable;
**RabbitMQ** if the team already knows it and needs flexible routing more
than durable replay; **Redpanda** only with the BSL terms explicitly
reviewed and accepted.

**Legitimate alternative to self-hosting**: managed cloud-native options
— AWS MSK, SQS/SNS/EventBridge, Google Pub/Sub, Azure Service Bus,
Confluent Cloud — hand off broker operations entirely for a real cost.
They're a genuine choice for teams that would rather not run broker
infrastructure at all, not researched at license/pricing depth here since
they're vendor-managed services rather than libraries with a license/star
profile to verify — see this doc's own no-pricing convention.

## Stream processing engines

Kafka Streams, Flink, and Spark Structured Streaming ship as part of
their parent projects rather than as separate repos — their license,
star count, and maintenance signal are the same repo's figures already
established above and in the Data & Analytics Platforms baseline. This
table exists to give each engine its own recommendation and honest
trade-offs rather than repeating a bare license line; the conceptual
comparison (state backend, checkpointing, processing model) lives in
`stacks/integration-event-driven-systems.md`.

| Engine | License (verified) | Stars (verified) | Last commit (verified) | Ships as | Why recommended |
|---|---|---|---|---|---|
| **Kafka Streams** | Apache-2.0 (same repo as Kafka core) | 33,560 (`apache/kafka`) | 2026-08-19 | Part of the Apache Kafka distribution — no separate install | The lowest-friction path into stream processing for a team already on Kafka and the JVM: a library, not new infrastructure, with exactly-once processing inherited from the same KIP-98 transactional machinery covered in stack.md. Confirmed Java-native (Scala wrapper shipped; other JVM languages work via interop with "no native support") — not a fit for Python-first teams. |
| **Apache Flink** | Apache-2.0 | 26,271 | 2026-08-20 | Standalone project, own repo (`apache/flink`), deployed as its own cluster (standalone, YARN, or Kubernetes) | The most capable and most operationally demanding of the three — the right default when true low-latency (sub-second) continuous processing, non-Kafka sources, or complex multi-stream joins/CEP are actual requirements, not aspirational ones. Broadest language surface (Java, Scala, Python via PyFlink, SQL). |
| **Spark Structured Streaming** | Apache-2.0 (same repo as Spark core) | 43,842 (`apache/spark`) | 2026-08-20 | Part of the Apache Spark distribution — no separate install | The right default specifically for a team already running Spark for batch/ELT that also needs a streaming ingestion path — same cluster, same Dataset/DataFrame API for Scala/Java/Python/R, one operational surface instead of two. A poor default for a team with no existing Spark footprint, since standing it up from scratch costs about the same operational lift as Flink for a narrower (micro-batch-first) latency profile. |

The star counts above aren't directly comparable row-to-row the way they
are in the broker or orchestrator tables: Kafka Streams' and Spark
Structured Streaming's figures are their *parent project's* total stars
(`apache/kafka`, `apache/spark`), since neither ships as a separate repo,
while Flink's figure is the project itself. A higher number for Kafka
Streams or Spark doesn't mean more people specifically chose that
engine's streaming feature — the same caution this doc applies to n8n's
star count below applies here.

**Decision rule**: JVM-only, Kafka-only pipeline → **Kafka Streams**
(cheapest to adopt, no new infrastructure). Non-Kafka sources, Python-first
teams, or genuine sub-second/complex-CEP requirements → **Flink** (most
capable, most to operate). Already running Spark for batch/ELT and adding
a streaming path → **Spark Structured Streaming** (reuses the existing
cluster and APIs).

**Legitimate alternative to self-hosting**: Confluent Cloud offers managed
Flink and ksqlDB directly on top of Kafka topics; AWS offers Managed
Service for Apache Flink; Databricks offers a fully managed Spark
(including Structured Streaming) runtime. All three are real options for
getting the engine's capability without operating the cluster — not
researched at pricing depth here, consistent with this baseline's
no-cost-modeling convention.

## Workflow orchestration engines

Stars, license, and `pushed_at` are from direct fetch of each repo's
GitHub API.

| Engine | License (verified) | Stars (verified) | Last commit (verified) | Model | What it's for | Why recommended |
|---|---|---|---|---|---|---|
| **Temporal** | MIT | 22,396 | 2026-08-19 | Durable execution — workflow code persists its execution history, survives process crashes, resumes exactly where it left off | Long-running, stateful, branching business processes; the current default implementation for a Saga-pattern orchestrator (see stack.md) since it solves the orchestrator's own crash-recovery problem | MIT is maximally permissive (self-host, fork, run commercially with zero license friction). Production users named in search results include Stripe, Snap, and Coinbase — not independently verified via those companies' own engineering blogs, so treat as a directional adoption signal rather than a confirmed fact. |
| **Apache Airflow** | Apache-2.0 | 46,536 | 2026-08-19 | DAG/schedule-oriented — tasks in a directed graph, typically time- or externally-triggered, task state persisted between runs but not mid-task execution state | Batch-shaped, primarily schedule-triggered pipeline orchestration — this is the *analytics*-pipeline-scheduling use case the sibling Data & Analytics Platforms baseline already covers; for *integration* use cases specifically, Airflow fits scheduled multi-system batch syncs (nightly reconciliation jobs) but is a poor fit for long-running stateful workflows waiting on unpredictable external events (a webhook that might arrive in seconds or days) — that's Temporal's shape, not Airflow's | Largest ecosystem and star count of any orchestrator by a wide margin, Apache Software Foundation governance. Latest release confirmed via direct fetch of `api.github.com/repos/apache/airflow/releases/latest`: **3.3.1**, published **2026-08-12** — 7 days before this baseline's 2026-08-19 snapshot date, itself a strong maintenance signal. |
| **Prefect** | Apache-2.0 | 23,642 | 2026-08-19 | Python-native, dynamic-DAG orchestration with a pull-based agent model (workers pull work rather than a central scheduler pushing to them) | An Airflow alternative for teams wanting first-class Python (dynamic pipelines, not static DAG files) and simpler retry/checkpoint ergonomics — still schedule/DAG-shaped, not durable-execution-shaped, so the same Airflow-vs-Temporal boundary above applies | A real, comparably-sized alternative to Airflow specifically for teams whose pain point is Airflow's static-DAG-file ergonomics rather than teams needing durable long-running workflows (Temporal's use case). |

**Decision rule**: durable, long-running, unpredictable-timing business
process (order fulfillment, multi-day approval, Saga orchestrator) →
**Temporal**. Scheduled batch/analytics pipeline → **Airflow** (or
Prefect for more Python-native ergonomics) — this is the sibling Data &
Analytics Platforms baseline's primary territory, named here only for the
integration-use-case boundary.

**Legitimate alternative to self-hosting**: Temporal Cloud is a managed
option for teams that want durable-execution semantics without running
the Temporal server themselves — not researched at pricing depth here.

### n8n: a separate category, not a ranked alternative

| Tool | License (verified) | Stars (verified) | Last commit (verified) | Model | What it's for |
|---|---|---|---|---|---|
| **n8n** | **Sustainable Use License + n8n Enterprise License ("fair-code")** — source-available, not an OSI-approved open-source license; GitHub API's `license.spdx_id` field itself returns `NOASSERTION`, corroborating that this isn't a standard OSI license | 201,179 | 2026-08-19 | Low-code visual workflow-automation platform (400+ pre-built integrations) | Rapid integration-automation building (a self-hostable Zapier/Make alternative) for teams that want a visual builder over custom code, and/or need broad SaaS-connector coverage out of the box |

n8n is named separately, deliberately not ranked alongside Temporal,
Airflow, and Prefect in the table above, because it serves a genuinely
different buyer: ops/automation teams wanting a visual builder, not
engineering teams building custom orchestration in code. Its 201k star
count — by a wide margin the largest number in this entire baseline —
reflects real, large adoption as a low-code automation tool, but treating
that as "n8n is just better than Temporal" would misread what the number
measures; it's not a like-for-like comparison. The license distinction
also matters on its own terms: the Community Edition is free to
self-host with unlimited workflows/executions, but it is **not**
permissively licensed like Temporal/Airflow/Prefect above — the
Sustainable Use License restricts competing-commercial-use in the same
family as Confluent's Community License and Redpanda's BSL. Recommended
for visual/low-code automation across many SaaS connectors once its
license terms are reviewed and accepted; not a substitute for a code-first
orchestration engine when the actual need is durable execution or
dependency-aware DAG scheduling.

## Schema registry tooling

| Tool | License (verified) | Stars (verified) | Last commit (verified) | What it's for | Why recommended |
|---|---|---|---|---|---|
| **Confluent Schema Registry** | **Confluent Community License** (server), Apache-2.0 (client-*/avro-* libraries only) — direct-fetch-confirmed from the repo's own LICENSE file, contradicting some secondary sources that describe it as simply "Apache 2.0"; the GitHub API's own `license.spdx_id` field returns `NOASSERTION` for the repo, consistent with the license not being a standard OSI/SPDX entry | 2,461 (GitHub API, re-verified this pass — an earlier pass's rate-limited attempt had used a rendered-page estimate of ~2,500) | 2026-08-20 (re-verified this pass — previously rate-limited) | Kafka-native schema storage/validation (Avro, Protobuf, JSON Schema), stores schemas using Kafka itself as the backend | The de facto standard for Kafka specifically, tightly integrated with the Confluent client ecosystem — but the license caveat matters: it is source-available with a no-competing-SaaS restriction, not a permissive OSI license, which is a materially different commitment than "open source" as commonly assumed. Verify this against your own use case (internal use is unaffected by the restriction; building a schema-registry-as-a-service product on top of it is not). |
| **Apicurio Registry** | Apache-2.0 (fully) | 916 | 2026-08-19 | Multi-format schema/API-artifact registry — Avro, Protobuf, JSON Schema, **plus** OpenAPI, AsyncAPI, GraphQL, WSDL, XML Schema in one registry; storage backends include in-memory (dev), PostgreSQL, or a Kafka-topic-backed "KafkaSQL" mode | Genuinely permissively licensed (no competing-SaaS carve-out), Red-Hat-backed, and broader in scope than Confluent's registry — one registry for both event-schema and API-contract artifacts (ties into the AsyncAPI/OpenAPI contract-first pattern the Backend & API Services baseline covers). Lower star count than Confluent's registry (916 vs. 2,461) is a real, smaller-community signal worth naming honestly rather than glossing over — recommended on license grounds and format breadth, not adoption-size grounds. |
| **AWS Glue Schema Registry** | Proprietary AWS service (client SDKs are open source, the service itself is not self-hostable) | N/A (managed service) | N/A | Schema management integrated into the AWS ecosystem (Glue, Kinesis, MSK) | Named for completeness as the default choice for teams already fully committed to AWS-managed streaming (MSK/Kinesis) who want one less thing to self-host — not comparable license-wise to the two self-hosted options above, and not researched at further depth per this baseline's no-vendor-pricing convention. |

**Default recommendation**: **Apicurio Registry** for a new project
without an existing Confluent Platform commitment, specifically because
of the license difference — Confluent Schema Registry only if already
standardized on the broader Confluent Platform and the Community
License's terms are acceptable for the project's context.

**Legitimate alternative to self-hosting**: beyond AWS Glue Schema
Registry above, Confluent Cloud offers a managed Schema Registry as part
of its hosted Kafka offering — a real option for a team already on
Confluent Cloud that wants one less self-hosted component; not researched
at pricing depth here.

## Change Data Capture (CDC)

**Debezium**: Apache-2.0, 13,022 GitHub stars, last commit 2026-08-19 —
Red-Hat-backed. Captures row-level database changes (via each database's
native replication mechanism — logical decoding for PostgreSQL, binlog
for MySQL, etc.) and publishes them as a Kafka Connect source, turning a
database's write-ahead log into an event stream without application code
needing to publish events itself. This is the concrete tool underneath
the fuzzy ETL/integration boundary named in stack.md — the same Debezium
stream commonly feeds both an operational event bus (this baseline) and a
warehouse-ingestion pipeline (the Data & Analytics Platforms baseline).
Recommended as the default CDC mechanism for a new project needing to
react to database changes as events, over hand-rolled polling or
dual-write patterns (a well-documented source of the exact
at-least-once/idempotency problems stack.md's delivery-semantics section
addresses).

## API/integration-platform tooling (distinct from the pure message-broker layer)

**Apache Camel**: Apache-2.0, 6,291 GitHub stars, last commit 2026-08-19.
A routing/mediation engine implementing the classic Enterprise
Integration Patterns (content-based routing, message filtering,
aggregation, dead-letter channel, publish-subscribe) with 300+ pre-built
connectors (HTTP/REST, JMS, Kafka, JDBC, FTP/SFTP, and more) callable from
Java, XML, YAML, or Groovy route definitions. This is the clearest current
default for **programmatic** system-to-system integration with
heterogeneous protocols/systems on either end — distinct from n8n's
low-code/visual audience, and distinct from a pure message broker (Camel
routes *between* systems and protocols; a broker just moves messages
within one). Commercial iPaaS SaaS products (MuleSoft, Workato, Boomi,
Zapier's paid tiers) were reviewed but excluded from this table per this
baseline's no-pricing/vendor-comparison convention — Camel is the one
clear open, self-hostable, code-first default found here; the SaaS-iPaaS
space is a legitimate alternative for teams wanting a managed low-code
platform but wasn't researched at license/adoption depth, since it's a
buy-vs-build decision outside a "preferred libraries" baseline's scope.

## Webhook infrastructure and signature verification

**Svix** (`svix/svix-webhooks`): MIT license — direct-fetch-confirmed
from the repo's own LICENSE file this pass (MIT, copyright Svix 2021,
standard permissive terms), previously confirmed only via search; 3,360
GitHub stars, last commit 2026-08-19 — both figures newly direct-fetch-
verified this pass, closing an earlier gap where the entry carried no
star count. A self-hostable webhook-sending service (ingest an event, fan
it out to registered subscriber endpoints with retry/backoff, signing,
and a delivery dashboard) implementing the receiver-side mechanics
stack.md documents from Stripe's own docs. Recommended for a project that
needs to be the **sender** of webhooks to third parties and wants the
retry/backoff/signing machinery already built, rather than reimplementing
Stripe's documented shape from scratch. **Legitimate alternative to
self-hosting**: Svix's own hosted cloud service offers the same
sending/retry/signing/dashboard functionality as a managed product — a
real option for a team that wants the capability without operating the
open-source service itself; not researched at pricing depth here, per
this baseline's convention.

**Standard Webhooks** (`standard-webhooks/standard-webhooks`): a
specification, not a single library — reference signature-verification
implementations are published across Python, JS/TS, Go, Rust, Ruby, PHP,
C#, Java, and Elixir per the project's own repo. Recommended as the
receiver-side verification approach for a project consuming webhooks from
multiple providers that support the standard, since it avoids writing
bespoke HMAC-verification code per vendor.

## Retry / backoff / circuit-breaker libraries (the DLQ companion layer)

These implement the exponential-backoff-with-jitter and circuit-breaker
patterns stack.md's DLQ/retry section names as the mitigation layer above
a broker's own redelivery-count threshold. Polly and resilience4j were
re-verified via a fresh GitHub API direct fetch this pass, closing the
previous baseline's rate-limit gap on their `pushed_at` field; tenacity's
maintenance signal remains registry-level (PyPI), as in the baseline,
since it isn't tracked via the GitHub API here.

| Library | Language | License (verified) | Stars (verified) | Last commit (verified) | Why recommended |
|---|---|---|---|---|---|
| **Polly** | .NET | BSD-3-Clause (New BSD) | 14,231 | 2026-08-16 | The standard .NET resilience library — retry, circuit-breaker, timeout, bulkhead, fallback policies, composable. Version 8's pipeline-based API is the current idiomatic approach per search-corroborated practitioner sources. |
| **resilience4j** | Java | Apache-2.0 | 10,748 | 2026-07-08 (six weeks before this baseline's verification date — a real, if slightly less frequent, maintenance cadence than the other entries in this table; still an actively maintained project by any normal standard, named honestly rather than flagged as stale) | The modern, modular successor to Netflix Hystrix (which is in maintenance mode) for JVM projects — pick only the modules needed (Retry, CircuitBreaker, RateLimiter, Bulkhead, TimeLimiter) as decorators over a functional interface. |
| **tenacity** | Python | Apache-2.0 (OSI-approved, PyPI-classifier-confirmed) | N/A (verified via PyPI's JSON API rather than GitHub) | **Latest release 9.1.4, uploaded 7 February 2026** — direct-fetch-confirmed via `pypi.org/pypi/tenacity/json`; a package release roughly 6 months before this baseline's date is itself the maintenance signal here, verified at the registry level rather than via GitHub | The standard Python retry library — decorator-based retry-with-backoff, actively maintained. |

None of these three implement DLQ semantics themselves (that's the
broker/queue's job, per stack.md) — they implement the application-level
retry-before-giving-up layer that determines *how many times and how* a
consumer retries before a message is allowed to exhaust the broker's own
`maxReceiveCount` and land in the DLQ.

## Explicitly out of scope

- Apache Pulsar — a real Kafka alternative (Apache-2.0, built-in
  multi-tenancy and tiered storage) surfaced in search results but not
  researched to the same license/adoption-verification depth as the four
  brokers in the table above; a candidate for a future addition to this
  file, not a blocking gap for this pass.
- Commercial iPaaS/SaaS integration platforms (MuleSoft, Workato, Boomi,
  Zapier, Make) — reviewed only enough to confirm Apache Camel's position
  as the clear open/self-hosted default; not researched at vendor-pricing
  or feature depth.
- GraphQL/REST/gRPC contract tooling (Buf, OpenAPI generators) — belongs
  to Backend & API Services' libraries.md.
- Data-pipeline/ELT tooling (Airbyte, Fivetran, dbt) — belongs to Data &
  Analytics Platforms' libraries.md; named only via Debezium's dual role
  above.
- Deep per-language SDK comparisons for any single broker (e.g. Kafka's
  own client libraries across Java/Python/Go/Rust) — out of scope; this
  baseline covers broker/platform selection, not per-language client
  ergonomics.
- Deep license/pricing research on every cloud-managed alternative named
  in passing above (MSK, Confluent Cloud, Temporal Cloud, AWS Managed
  Flink, Databricks, Svix Cloud, Confluent Cloud Schema Registry) — named
  as legitimate alternatives to self-hosting, not researched at
  vendor-pricing depth, per this baseline series' no-cost-modeling
  convention.

## Sources

- `api.github.com/repos/apache/kafka`, `.../rabbitmq/rabbitmq-server`,
  `.../nats-io/nats-server`, `.../redpanda-data/redpanda`,
  `.../temporalio/temporal`, `.../apache/airflow`, `.../PrefectHQ/prefect`,
  `.../n8n-io/n8n`, `.../apicurio/apicurio-registry`,
  `.../debezium/debezium`, `.../apache/camel`, `.../apache/flink`,
  `.../apache/spark` — direct fetch of the GitHub REST API for
  `stargazers_count`, `pushed_at`, and `license.spdx_id` — retrieved
  2026-08-19 through 2026-08-20
- `api.github.com/repos/svix/svix-webhooks`,
  `.../App-vNext/Polly`, `.../resilience4j/resilience4j`,
  `.../confluentinc/schema-registry` — **re-fetched this pass**,
  resolving the prior baseline's rate-limit gap; all four now carry a
  direct-fetch-confirmed `pushed_at` — retrieved 2026-08-20
- `raw.githubusercontent.com/svix/svix-webhooks/main/LICENSE` — direct
  fetch of the full license text: MIT, copyright Svix 2021 — retrieved
  2026-08-20, resolving the prior baseline's search-only citation
- `raw.githubusercontent.com/redpanda-data/redpanda/dev/licenses/bsl.md`
  — direct fetch of the full BSL 1.1 text: Additional Use Grant's
  "Streaming or Queuing Service" restriction (quoted above), four-year/
  fifth-anniversary Apache-2.0 conversion, production-use and termination
  terms — retrieved 2026-08-20, resolving the prior baseline's
  search-only citation
- `cncf.io/announcements/2025/05/01/cncf-and-synadia-align-on-securing-the-future-of-the-nats-io-project/`
  — direct fetch of the full joint statement text (quoted above) —
  retrieved 2026-08-20, resolving the prior baseline's search-only
  citation
- `github.com/confluentinc/schema-registry` and
  `raw.githubusercontent.com/confluentinc/schema-registry/master/LICENSE`
  — direct fetch of both the repo page and the raw LICENSE file:
  confirms Confluent Community License for the server, Apache-2.0 only
  for client-*/avro-* modules — this directly contradicts a secondary
  source found in earlier search results describing the project as
  simply "open-source under the Apache 2.0 license" — retrieved
  2026-08-19
- `api.github.com/repos/apache/airflow/releases/latest` and
  `pypi.org/pypi/apache-airflow/json` — direct fetch: current latest
  release is **3.3.1**, published 2026-08-12T09:50:17Z — retrieved
  2026-08-19
- `pypi.org/pypi/tenacity/json` — direct fetch: latest version 9.1.4,
  uploaded 7 February 2026, Apache-2.0 license classifier — retrieved
  2026-08-19
- `docs.confluent.io/platform/current/streams/architecture.html` and
  `.../streams/faq.html` — Kafka Streams' embedded-library model, and
  confirmation the API is Java-native (Scala wrapper shipped, no native
  support for other JVM languages) — retrieved 2026-08-20
- `flink.apache.org/what-is-flink/flink-architecture/`,
  `nightlies.apache.org/flink/flink-docs-release-1.20/docs/ops/state/state_backends/`
  — Flink's architecture and state-backend documentation, underlying this
  section's engine comparison — retrieved 2026-08-20
- `spark.apache.org/streaming/`,
  `spark.apache.org/docs/latest/streaming/index.html` — Spark Structured
  Streaming's shared-cluster/shared-API design and micro-batch vs.
  Continuous Processing tradeoffs — retrieved 2026-08-20
