# Integration & Event-Driven Systems — Architecture & Stack

## Table of contents

1. [How this category specializes the cross-cutting architecture patterns](#how-this-category-specializes-the-cross-cutting-architecture-patterns)
2. [Message broker architecture: pub/sub vs. point-to-point queue](#message-broker-architecture-pubsub-vs-point-to-point-queue)
3. [Event schema design and evolution](#event-schema-design-and-evolution)
4. [Delivery semantics: exactly-once vs. at-least-once vs. at-most-once](#delivery-semantics-exactly-once-vs-at-least-once-vs-at-most-once)
5. [The Saga pattern: choreography vs. orchestration](#the-saga-pattern-choreography-vs-orchestration)
6. [Dead-letter-queue and retry/backoff design](#dead-letter-queue-and-retrybackoff-design)
7. [Stream processing engines: stateful transformation beyond simple consumers](#stream-processing-engines-stateful-transformation-beyond-simple-consumers)
8. [Webhook design: delivery guarantees, retries, signature verification](#webhook-design-delivery-guarantees-retries-signature-verification)
9. [ETL/ELT integration-platform architecture — the boundary with Data & Analytics Platforms](#etlelt-integration-platform-architecture--the-boundary-with-data--analytics-platforms)
10. [Workflow orchestration: durable execution vs. DAG-scheduling](#workflow-orchestration-durable-execution-vs-dag-scheduling)
11. [Sources](#sources)

This baseline covers the async/event-driven surface of an integration
system: message brokers, event schemas, delivery semantics, sagas,
dead-letter handling, stream processing, webhooks, and workflow
orchestration. Specific library/broker/vendor names and licenses live in
the companion `preferred-libraries/integration-event-driven-systems.md`;
full REST/GraphQL/gRPC API design belongs to Backend & API Services;
warehouse-bound ELT/data-quality tooling belongs to Data & Analytics
Platforms. Where those boundaries are genuinely fuzzy rather than clean,
that's named explicitly rather than glossed over.

## How this category specializes the cross-cutting architecture patterns

**Event-driven** is this category's home pattern, but "fits" splits into
two genuinely different things a single cross-cutting label can blur
together. As a **communication style** — services react to events instead
of calling each other synchronously — it's nearly unconditional for this
category; almost every integration system has this somewhere. As a
**storage/state model** — event sourcing, where the event log *is* the
system of record and current state is a fold over history — it stays
behind the same rarely-justified bar CQRS/event sourcing generally sit
behind, but this is the one category where that bar gets crossed more
often than elsewhere: an integration system's events are frequently
already the durable, replayable artifact the business cares about (a
payment-events topic, an order-lifecycle topic), not an implementation
detail bolted onto a CRUD domain model. It's worth naming as a live
option when a system already treats its event stream as the durable
record of what happened, rather than reaching for it reflexively.

**Microservices** and **modular monolith** apply to the *services that
produce and consume* events, not to the broker itself — the broker is
shared infrastructure, not a service. The monolith-first heuristic still
holds for the surrounding application code, with the broker as the one
piece that's justified as a separate, shared component from day one once
more than one service needs to communicate asynchronously.

**Hexagonal** applies cleanly at the consumer boundary: the inbound port
is "handle this event," and the domain logic doesn't know or care whether
the event arrived via Kafka, RabbitMQ, or a synchronous test harness —
the same reasoning the Backend & API Services baseline applies to HTTP
handlers, applied here to message handlers.

**Serverless** fits individual event handlers well (a function triggered
per message) but is a poor fit for the broker or queue infrastructure
itself, which needs to be always-on, stateful infrastructure regardless of
how spiky the workload driving it is.

## Message broker architecture: pub/sub vs. point-to-point queue

These are genuinely different delivery topologies, not two names for the
same thing:

| Pattern | Delivery shape | Fits when | Representative tech |
|---|---|---|---|
| Point-to-point queue | Each message consumed by exactly one worker among a competing pool | Work distribution — a task should be done once, by whichever worker picks it up first (job queues, task processing) | SQS, RabbitMQ (classic queue with a single consumer group), a single-consumer-group Kafka topic |
| Pub/sub (topic/fan-out) | Each message delivered to every independent subscriber | Multiple independent parties each need to know an event happened, for different reasons (order-placed triggers billing, shipping, and analytics independently) | Kafka (multiple consumer groups on one topic), NATS subjects, SNS, RabbitMQ topic exchange, Google Pub/Sub |

Kafka and RabbitMQ can each be made to do either shape — Kafka's consumer
groups give point-to-point *within* a group and pub/sub *across* groups;
RabbitMQ's exchange types (direct/topic/fanout) cover both — so the
distinction that actually matters for architecture decisions is **which
shape a given integration point needs**, not which product was chosen,
since most current brokers support both. The practical decision rule: ask
"does exactly one consumer need this, or does every interested party need
their own copy?" per integration point, not per system. A single platform
commonly has both shapes present simultaneously — a point-to-point job
queue for background work alongside a pub/sub topic for domain events —
and forcing one topology everywhere is a common design mistake.

A related, easy-to-miss trap: an in-process or single-connection pub/sub
primitive (PostgreSQL's `LISTEN`/`NOTIFY` is a common example) is not a
substitute for a broker once delivery has to survive a process restart or
fan out across replicas. Without durable storage behind it, a bare pub/sub
primitive loses every subscription on restart and can't fan messages out
across more than one listening process — exactly the gap a real broker
sitting between the source and its consumers is built to close.

## Event schema design and evolution

A schema registry exists to solve one concrete problem: producers and
consumers deploy independently, so the event schema **will** change while
both old and new code are running simultaneously. Compatibility modes,
using the Confluent/Avro vocabulary that's become the de facto standard
industry-wide even outside Confluent's own tooling:

| Mode | Rule | Deployment order this allows |
|---|---|---|
| Backward compatible | Consumers using the new schema can read data produced with the last schema | **Upgrade all consumers before producing new events** — the new schema is a superset the new consumer code already understands, so consumers can safely see new-shaped data before any exists; producers switch last |
| Forward compatible | Data produced with a new schema can be read by consumers using the last schema, even if they can't use the new schema's full capabilities | **Upgrade all producers first**, ensure data produced under the old schema is no longer available to consumers, **then** upgrade consumers — old consumer code stays functional (if capability-limited) against new-shaped data |
| Full compatible | Both hold simultaneously | Producers and consumers can be upgraded in **either order, independently** |

Each mode also has a `_TRANSITIVE` variant (e.g. `BACKWARD_TRANSITIVE`)
checked against every prior schema version in the subject's history, not
just the immediately preceding one — the non-transitive variants only
guard against a single-version skip, which understates the real
compatibility risk in a system where a consumer might lag behind by more
than one schema version.

The practical default for an evolving system with independently-deployed
producers and consumers is **backward compatible** — this is not just a
common convention, it is Confluent Schema Registry's own default
compatibility mode for a newly registered subject, which makes it the
path of least resistance for a team using off-the-shelf registry tooling
rather than a mode they'd need to consciously opt into. Concretely: upgrade
consumer code to understand the next schema version *before* any producer
starts emitting it, achieved mechanically by only ever adding optional
fields with sensible defaults, never removing or repurposing a field, and
never changing a field's type. A schema registry enforces the chosen mode
at publish time — rejecting a schema version that violates it before the
change can reach production — rather than relying on code review
discipline alone.

**CloudEvents** (a CNCF graduated project as of 25 January 2024, spec
v1.0.2) is the relevant complementary standard here — not a
schema-evolution mechanism itself, but a standard *envelope* (id, source,
type, specversion, plus payload) so tooling across different
brokers/languages can agree on event metadata shape. It composes with,
rather than replaces, a schema registry's payload-body versioning.

## Delivery semantics: exactly-once vs. at-least-once vs. at-most-once

This is the single most load-bearing sub-topic in this baseline.

**At-most-once**: a message is delivered zero or one times — the sender
fires and doesn't wait for confirmation, or the consumer acks *before*
processing. Nothing is ever double-processed, but messages are silently
lost on any failure between send and process. Rarely the right choice for
anything that matters, but legitimate for high-volume telemetry/metrics
where losing an occasional sample is cheaper than the infrastructure to
prevent it.

**At-least-once**: the sender retries until it gets confirmation, or the
consumer acks *after* successful processing — nothing is silently lost,
but the same message can and will be delivered more than once (a retry
after a timeout the original request actually succeeded past, a consumer
crash after processing but before acking, a broker failover). This is the
**default most production message-broker configurations actually
deliver** — not a corner case to guard against occasionally, but the
normal operating behavior a consumer must be built for.

**Exactly-once ("EOS")**: nothing lost, nothing duplicated. Kafka's own
EOS (KIP-98, introduced in Kafka 0.11) is real and works via an idempotent
producer — a producer ID plus a per-partition monotonic sequence number
the broker uses to reject or dedupe a resent message — combined with
transactions: atomic multi-partition writes, with the
read-process-write cycle wrapped in a transaction so consuming,
transforming, and re-producing to another topic happens as one atomic
unit. But this guarantee holds **within the Kafka cluster's own
read-process-write cycle only**, and the KIP-98 design doc is explicit
about the boundary even *inside* that cycle: "we cannot guarantee that all
the messages of a committed transaction will be consumed all together" —
because compacted topics may overwrite some of a transaction's messages
with newer versions, transactions can straddle log segments that get
independently deleted by retention, and a consumer is free to seek
arbitrarily within a transaction or skip partitions entirely. That caveat
is *before* even reaching the harder boundary: the moment a side effect
crosses out of Kafka entirely — an HTTP call to a third-party API, a write
to a database that isn't itself transactionally coordinated with Kafka's
offset commit, a call to another message broker — Kafka's EOS machinery
has no way to make that external effect exactly-once, because it can't
roll back an HTTP call that already fired. Both boundaries are facts
"exactly-once" marketing claims across the industry consistently gloss
over, and together they're the reason the field converges on a different,
more honest practical answer:

**Idempotent-consumer design is the practical answer to at-least-once
being the common default.** The pattern's definition (per Chris
Richardson's own pattern catalog, the same primary source the Saga section
below draws from): "the outcome of processing the same message repeatedly
must be the same as processing the message once." The concrete mechanism
is tracking processed-message identifiers — either a dedicated
`PROCESSED_MESSAGES` table keyed by (subscriber ID, message ID) that a
processing transaction inserts into atomically with its business-logic
writes (a duplicate insert fails the unique constraint, the transaction
rolls back, the duplicate is safely dropped), or, where the operation is
*naturally* idempotent (an upsert keyed by a stable business ID, "set
balance to X" instead of "add X to balance"), no tracking table is needed
at all because reprocessing produces the same end state by construction.
Combining at-least-once delivery with an idempotent consumer is what the
industry calls "effectively-once" processing — simpler than chasing true
exactly-once across a system boundary Kafka's own EOS can't reach, and it
generalizes across every broker (RabbitMQ, SQS, NATS), not just Kafka's
transactional subset.

**Decision rule**: default to at-least-once delivery (it's what most
brokers give you without special configuration) plus an idempotent
consumer for any handler with a real side effect. Reach for exactly-once
machinery only for the narrow case of a pure Kafka-to-Kafka
read-process-write pipeline, where the transactional guarantee's actual
boundary (Kafka-internal only) is sufficient for the use case. Treat
at-most-once as an explicit, deliberate choice for loss-tolerant
telemetry, not a default anyone should fall into by omission.

## The Saga pattern: choreography vs. orchestration

A saga is a sequence of local transactions: "Each local transaction
updates the database and publishes a message or event to trigger the next
local transaction in the saga" (Chris Richardson's own definition, the
primary reference AWS Prescriptive Guidance and Temporal's own blog
themselves cite). In **choreography**, "each local transaction publishes
domain events that trigger local transactions in other services." In
**orchestration**, "an orchestrator tells the participants what local
transactions to execute." When a step fails, prior steps are undone via
**compensating actions** rather than a cross-service ACID rollback (which
doesn't exist in a distributed system without an expensive two-phase-commit
coordinator most architectures deliberately avoid) — this trades ACID
guarantees for availability, and concurrent sagas can introduce data
anomalies needing their own countermeasures.

| | Choreography | Orchestration |
|---|---|---|
| Control flow | Decentralized — each service publishes events and reacts to others' events independently | Centralized — one coordinator service tells each participant what to do and interprets the result |
| Coupling | Lower — services only know event contracts, not each other | Higher — participants are coupled to the orchestrator's command contract |
| Visibility / debuggability | Harder — the saga's overall state is implicit, reconstructed from scattered event logs across services | Easier — the orchestrator holds explicit state; "what step is this saga on" is one query away |
| Fits well | Few participants, simple linear flows, teams already fully event-driven | More than a few participants, complex branching/compensation logic, need for centralized monitoring/retry of the saga itself |
| Failure mode as it grows | Cyclic/implicit dependencies between services become hard to trace as participant count grows | Orchestrator becomes a single point of design complexity (though not necessarily a single point of runtime failure if built stateless/replayable) |

**Decision rule**: start with choreography for a 2–3-participant saga in an
already event-driven system — it's the lower-ceremony default and avoids
introducing a new centralized component. Move to orchestration once the
saga's compensation logic itself becomes hard to reason about scattered
across services, or once the business needs a queryable "what state is
this order in" view — at which point a durable workflow-orchestration
engine (Temporal — see libraries.md) is the current default implementation
for the orchestrator role, since it handles the orchestrator's own
crash-recovery/replay problem instead of leaving that as another
distributed-systems problem to solve by hand.

## Dead-letter-queue and retry/backoff design

A DLQ exists to isolate messages a consumer repeatedly fails to process,
so they stop blocking or retrying forever and can be inspected. AWS SQS's
own mechanics generalize well beyond SQS specifically: a **redrive
policy** sets `maxReceiveCount` — the number of delivery attempts before a
message moves to the DLQ — and AWS's own guidance is explicit this number
should be "high enough to allow for sufficient retries," not set
reflexively low. For standard (non-FIFO) queues, once a message has been
received 3+ times without being deleted, SQS moves it to the back of the
queue rather than immediately redelivering it — a mild backoff mechanism
baked into the queue's own redelivery behavior. A specific, non-obvious
warning worth carrying forward: don't attach a DLQ to a FIFO queue if
strict message ordering matters, because pulling one message out to the
DLQ breaks the ordering guarantee for everything behind it.

**Retention**: DLQ retention should be set **longer** than the source
queue's retention, since a message's age is tracked from its *original*
enqueue time on standard queues, not from when it landed in the DLQ — a
DLQ with too-short retention can silently expire a message before anyone
gets to investigate it.

**Backoff strategy layered on top of the DLQ threshold**: fixed-interval
retry is the simplest and worst choice for anything hitting a struggling
downstream (all retries arrive in lockstep, prolonging the outage);
**exponential backoff** (each retry waits longer than the last) is the
standard mitigation; **exponential backoff with jitter** (randomizing the
wait slightly) is the refinement that prevents a large population of
retrying clients from re-synchronizing into new lockstep waves after the
first backoff interval. This jitter detail is a well-established
distributed-systems practice (originating from AWS's own "Exponential
Backoff and Jitter" architecture blog post) rather than a Kafka- or
SQS-specific mechanism, and it applies equally to broker-level redelivery
and to application-level HTTP retry logic (webhook delivery, below,
included). Library-level implementations of retry+backoff are covered in
libraries.md.

## Stream processing engines: stateful transformation beyond simple consumers

Everything above this point assumes a consumer that reacts to one event
at a time — receive a message, do a side effect, ack. That model, plus an
idempotent handler, covers most integration work. It stops covering the
problem once a handler's logic needs **memory across events**: a rolling
count over a time window, a join between two independently-arriving
streams (enriching order events with a customer-profile stream), a
deduplication check over a lookback period, or detecting a pattern across
a sequence of events. A stream processing engine is a distinct layer that
exists to solve exactly this — **continuous, stateful transformation over
a broker's event log** — and it's worth being precise about the
distinction: a broker (Kafka, RabbitMQ, NATS) moves messages from
producers to consumers; a stream processing engine sits on top of that
movement and maintains computed state as events arrive, persisting that
state so it survives a crash and can be rebuilt by replaying the log.

**When it's warranted vs. the simpler patterns above**: default to a
plain consumer with idempotent handling for single-event-in,
single-effect-out logic — that's the large majority of integration
handlers, and it's simpler to write, test, and operate than a stream
processing job. Reach for a stream processing engine when the
transformation genuinely can't be expressed as "one event triggers one
side effect" — the moment a handler needs to remember something about
previous events to correctly process the current one. Hand-rolling that
state management in a plain consumer means reinventing checkpointing,
crash recovery, and rebalancing by hand; these engines exist specifically
because that's a hard, well-trodden problem not worth re-solving per
project.

### Kafka Streams, Flink, and Spark Structured Streaming compared

| | Kafka Streams | Apache Flink | Spark Structured Streaming |
|---|---|---|---|
| Language/ecosystem fit | Java/Scala native — the API is implemented in Java with a Scala wrapper; other JVM languages (Kotlin, Clojure) work via interop but have no native support | Java, Scala, Python (PyFlink), and SQL via the Table API — the broadest language surface of the three | Scala, Java, Python, and R via the same Dataset/DataFrame API Spark uses for batch |
| Processing model | A **library embedded in your application**, not a separate cluster — "a library that runs anywhere its stream processing application runs"; your app instances *are* the processing cluster | A **dedicated cluster** (JobManager orchestrating Resource Manager/Dispatcher/JobMaster roles, plus TaskManager worker processes) doing true continuous per-event processing | Runs on the **same Spark cluster/engine as batch jobs**; micro-batch by default (a series of small batch jobs, latencies as low as ~100ms), with an optional Continuous Processing mode (~1ms latency, but only at-least-once, not exactly-once) since Spark 2.3 |
| State backend / checkpointing (conceptual) | Local state stores (RocksDB-backed) per task, each backed by a replicated, log-compacted Kafka changelog topic; standby replicas pre-warm state on other instances to cut failover time; exactly-once via Kafka transactions plus a local checkpoint file tracking changelog offset | Two backend choices — `HashMapStateBackend` (heap objects, fast, memory-bound) or `EmbeddedRocksDBStateBackend` (disk-backed, scales past memory, roughly an order of magnitude slower per access, supports incremental checkpoints); checkpointing is asynchronous and incremental, "guaranteeing exactly-once state consistency" with minimal latency impact | Checkpoint location plus write-ahead logs; exactly-once fault tolerance holds in micro-batch mode, traded away for at-least-once under Continuous Processing |
| Operational complexity | Lowest of the three — nothing new to deploy; scale by adding application instances, bounded by the input topic's partition count; tied to Kafka as the source | Highest of the three — a dedicated cluster to deploy, monitor, and scale (standalone, YARN, or Kubernetes) separate from any broker, but the most general engine: many source types beyond Kafka, and the richest state/windowing/CEP feature set, with documented deployments processing multiple trillions of events per day and maintaining multiple terabytes of state | Adds nothing new to operate **if the team already runs Spark** for batch/ELT — one operational surface instead of two; otherwise it's a comparable operational lift to standing up Flink |
| When it's the right choice | The pipeline is Kafka-to-Kafka (or Kafka-to-external-sink), the team is already JVM-based, and a library beats new infrastructure — the default when data already lives in Kafka and the team is Java/Scala | Sub-second/true-streaming latency requirements, complex multi-stream joins or CEP-style pattern detection, non-Kafka or multi-source pipelines, or state too large for a per-app-instance embedded model | A team already on Spark for batch/analytics that also needs a stream-ingestion path with the same APIs and cluster, tolerant of ~100ms-class (not sub-millisecond) latency |

**Decision rule**: pick on language/ecosystem fit first — a JVM-only,
Kafka-only pipeline defaults to Kafka Streams because it costs nothing
operationally beyond the application itself; a pipeline needing Python,
non-Kafka sources, or genuinely low-latency complex state defaults to
Flink; a team already running Spark for batch/ELT defaults to Structured
Streaming to avoid a second operational surface. Then weigh operational
complexity budget explicitly — Flink's cluster is the heaviest of the
three to run and is only worth it when its capability (true low-latency
continuous processing, the broadest source ecosystem, the richest
state/CEP feature set) is actually needed, not by default. Managed
options exist for all three (Confluent Cloud's managed Flink and ksqlDB,
AWS Managed Service for Apache Flink, Databricks for Spark) and are a
legitimate way to get the engine's capability without operating the
cluster yourself — a real alternative worth pricing out before committing
to self-hosting any of the three, though this baseline doesn't research
pricing depth (see libraries.md's convention).

This is distinct from, and sits above, the batch-vs-streaming latency
question the Data & Analytics Platforms baseline covers for warehouse
ingestion pipelines — that baseline's guidance on *when* streaming is
warranted at all (a named downstream decision needs sub-15-minute
freshness) still applies before reaching this table; this table is for
*how* to build the stream processor once streaming has already been
decided.

## Webhook design: delivery guarantees, retries, signature verification

This fills the gap the Backend & API Services baseline explicitly
deferred here. Stripe's own webhook documentation is treated as the
primary worked reference — the most complete, concretely-specified
real-world implementation of outbound webhook delivery found in this
category's research, specific enough to carry forward close to verbatim:

- **Retry schedule**: retries continue "for up to three days with an
  exponential backoff in live mode" (sandbox mode retries 3 times over a
  few hours instead) — Stripe's own stated policy. The specific
  minute-by-minute retry intervals some third-party blogs publish aren't
  confirmed by Stripe's own docs and are deliberately excluded here.
- **Non-2xx and redirects are both failures**: a `3xx` redirect response
  to a webhook request is treated as a delivery failure, not followed — a
  detail easy to miss when standing up a naive webhook receiver behind a
  load balancer that redirects.
- **Fast-ack requirement**: the endpoint must return a `2xx` status
  quickly, before doing slow or complex processing. Stripe recommends
  queuing the actual business-logic work asynchronously rather than
  processing inline, both to avoid timeout-triggered retries and to
  survive traffic spikes (Stripe's own example: many subscriptions renew
  at the start of a billing period, producing a burst).
- **Signature verification mechanics**: a `Stripe-Signature` header
  carries a timestamp (`t=`) and one or more HMAC-SHA256 signatures
  (`v1=`, keyed to the endpoint's per-endpoint secret); the signed payload
  is `{timestamp}.{raw request body}`. Verification must use a
  constant-time comparison (to prevent timing attacks) and must reject a
  timestamp too far from current time (Stripe's own libraries default to
  a 5-minute tolerance) specifically to prevent replay attacks — a
  captured valid payload+signature pair becomes unusable after the
  tolerance window even if replayed verbatim.
- **Duplicate delivery is explicitly expected, not a bug**: Stripe's own
  best-practices section instructs receivers to log processed event IDs
  and skip already-seen ones — the idempotent-consumer pattern above,
  applied at the webhook-receiver boundary specifically, framed as a
  required practice, not an edge case.
- **IP allowlisting as a second, independent verification layer**
  alongside signature verification — Stripe publishes a fixed set of
  sending IPs and recommends both mechanisms together, not signature
  verification alone.

**Standard Webhooks** is the emerging community attempt (a technical
steering committee including Zapier, Twilio, Mux, ngrok, Supabase, Svix,
and Kong per the project's own repo) to standardize this exact
HMAC-plus-timestamp-plus-replay-protection shape across providers, so a
receiver doesn't need bespoke verification code per vendor. Its mechanics
closely mirror Stripe's own approach — corroborating evidence this shape
is a converged industry pattern, not one company's idiosyncratic design.

**Recommendation for a new project building outbound webhooks**:
implement Stripe's shape directly (HMAC-SHA256, timestamp+signature
header, replay-window rejection, documented retry-with-backoff schedule,
redirect-is-failure), or adopt the Standard Webhooks spec and its
reference libraries (see libraries.md) rather than reinventing it — either
lands in the same place.

## ETL/ELT integration-platform architecture — the boundary with Data & Analytics Platforms

The sibling Data & Analytics Platforms baseline covers ELT/ETL from the
*analytics-consumer* framing: data lands in a warehouse or lakehouse for
BI/analytical query, and ELT is the dominant pattern there because
cloud-warehouse compute economics favor load-then-transform. **This
category's framing is different in intent, even when the mechanics look
similar**: system-to-system integration moves data *because another
operational system needs it to function* — a CRM needs the latest order
status, a billing system needs a subscription change, a partner's system
needs a webhook — not because an analyst needs to query it later.

The boundary is genuinely fuzzy rather than clean, and pretending
otherwise would be dishonest. **Change Data Capture (CDC)** tooling
(Debezium — see libraries.md) is the clearest example of something that
serves both framings simultaneously: the same CDC stream off a production
database can feed an operational event bus (this category) and a
warehouse ingestion pipeline (the analytics baseline), with no difference
in the underlying mechanism — only in what consumes the resulting topic.

**Decision rule for which baseline a given data-movement concern belongs
to**: if the destination is a warehouse/lakehouse and the consumer is a
query engine or BI tool, it's the Data & Analytics Platforms baseline's
territory (ELT, dbt-style transforms, data-quality testing frameworks).
If the destination is another live operational system and the consumer is
application code reacting to the data, it's this baseline's territory
(message brokers, webhooks, CDC-to-event-bus, workflow orchestration
coordinating multi-system operations). A single platform commonly needs
both, sourced from the same CDC stream — that overlap is normal, not a
modeling failure.

**ETL still applies within this category specifically** (transform-before-
load, not load-then-transform) when the destination system enforces a
schema on write and can't be handed raw or malformed data — a legacy
system-of-record a webhook must post clean, pre-validated payloads to is a
concrete instance of exactly this case, the same reasoning the sibling
baseline uses for its own ETL exception, just triggered by "the
operational destination requires it" instead of "the analytical
destination requires it."

## Workflow orchestration: durable execution vs. DAG-scheduling

Two genuinely different engine models exist and get conflated under
"orchestration" generically. Full tooling detail lives in libraries.md;
this section covers the model distinction.

**DAG/schedule-oriented orchestration** (Airflow's original model — a DAG
of tasks, typically triggered on a schedule or an external trigger, each
task usually short-lived and stateless between runs) fits batch-shaped,
primarily time-triggered work — this is the shape the Data & Analytics
Platforms baseline already covers for pipeline scheduling.

**Durable-execution orchestration** (Temporal's model — a workflow is
regular code that can run for days, survive process crashes, and resume
exactly where it left off, with the engine persisting execution history
rather than just task-completion state) fits long-running, stateful
business processes with real branching logic and human-in-the-loop or
external-event waits: a multi-step order-fulfillment saga, a multi-day
approval workflow, a Saga-pattern orchestrator (above) that needs to
survive its own process restarting mid-saga.

This is the discriminator that actually matters for this category: an
integration system coordinating multiple external systems over an
unpredictable timeframe — waiting on a partner's webhook that might arrive
in five seconds or five days — is durable-execution-shaped, not
DAG-schedule-shaped, even though both tools get marketed under
"orchestration."

## Sources

- `cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging`
  — KIP-98: idempotent producer and transactional mechanics, introduced
  Kafka 0.11, and the explicit consumer-side scope limit quoted above —
  retrieved 2026-08-19
- `microservices.io/patterns/communication-style/idempotent-consumer.html`
  — Chris Richardson's idempotent-consumer pattern definition and the
  `PROCESSED_MESSAGES` table mechanism — retrieved 2026-08-19
- `microservices.io/patterns/data/saga.html` — Chris Richardson's saga,
  choreography, and orchestration definitions, quoted directly above —
  retrieved 2026-08-19
- `docs.confluent.io/platform/current/schema-registry/fundamentals/schema-evolution.html`
  — backward/forward/full compatibility-mode definitions, deployment
  orders, `_TRANSITIVE` variants, and confirmation that `BACKWARD` is the
  registry's default — retrieved 2026-08-19
- `docs.aws.amazon.com/.../sqs-dead-letter-queues.html` — redrive policy /
  `maxReceiveCount` mechanics, the 3+-receives back-of-queue behavior,
  DLQ-plus-FIFO ordering warning, DLQ-retention-longer-than-source
  guidance — retrieved 2026-08-19
- `docs.stripe.com/webhooks` — full webhook delivery mechanics: retry
  schedule, redirect-as-failure, fast-2xx-ack, `Stripe-Signature` header
  mechanics, duplicate-event dedup, IP allowlisting — retrieved 2026-08-19
- `github.com/standard-webhooks/standard-webhooks` — Standard Webhooks
  community spec and technical steering committee membership — retrieved
  2026-08-19; the spec body itself (`spec/standard-webhooks.md`) was not
  independently direct-fetched this pass — the TSC membership and the
  claim that its mechanics mirror Stripe's approach are carried forward
  from the baseline on that same flagged, search-corroborated basis
- `github.com/cloudevents/spec` — CNCF graduated 25 January 2024, spec
  v1.0.2 — retrieved 2026-08-19
- AWS "Exponential Backoff and Jitter" architecture blog post
  (`aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/`)
  — the originating primary source for jitter-on-backoff as a
  distributed-systems practice, corroborated by its continued citation
  across current retry-library documentation; not independently
  re-fetched this pass — carried forward from the baseline on that same
  flagged basis
- **Streaming-engine research, new this pass**:
  `docs.confluent.io/platform/current/streams/architecture.html` and
  `docs.confluent.io/platform/current/streams/faq.html` — Kafka Streams'
  embedded-library model, processor topology, local state stores backed by
  changelog topics, standby replicas, exactly-once via Kafka transactions,
  and confirmation the API is Java-native with a Scala wrapper only ("no
  native support" for other JVM languages) — retrieved 2026-08-20
- `flink.apache.org/what-is-flink/flink-architecture/` — Flink's own
  description as "a framework and distributed processing engine for
  stateful computations over unbounded and bounded data streams,"
  asynchronous incremental checkpointing, and documented production scale
  (multiple trillions of events/day, multiple terabytes of state,
  thousands of cores) — retrieved 2026-08-20
- `nightlies.apache.org/flink/flink-docs-release-1.20/docs/ops/state/state_backends/`
  — `HashMapStateBackend` vs. `EmbeddedRocksDBStateBackend` tradeoffs,
  incremental checkpointing — retrieved 2026-08-20
- `nightlies.apache.org/flink/flink-docs-release-1.20/docs/concepts/glossary/`
  — JobManager/TaskManager definitions — retrieved 2026-08-20
- `spark.apache.org/streaming/` and
  `spark.apache.org/docs/latest/streaming/index.html` — Spark Structured
  Streaming's shared-API-with-batch design, micro-batch default (~100ms
  latency) vs. Continuous Processing mode (~1ms, at-least-once only since
  Spark 2.3), checkpointing plus write-ahead logs for exactly-once
  fault tolerance, and Scala/Java/Python/R language support — retrieved
  2026-08-20
- `api.github.com/repos/apache/kafka`, `api.github.com/repos/apache/flink`,
  `api.github.com/repos/apache/spark` — direct fetch of the GitHub REST
  API for star counts, license, and last-commit signal (all three engines'
  Kafka Streams/Flink/Spark-Structured-Streaming code ships inside these
  same repos rather than a separate one) — retrieved 2026-08-20; see
  libraries.md for the full table
- Data & Analytics Platforms sibling baseline
  (`references/stacks/data-analytics-platforms.md`) — read for the
  ELT/ETL framing this doc's fuzzy-boundary section responds to, and for
  the batch-vs-streaming latency-tolerance table this doc's streaming
  section sits above
- Backend & API Services sibling baseline
  (`references/stacks/backend-api-services.md`) — read to confirm what was
  explicitly deferred here (event-driven/message-broker architecture,
  webhook delivery/retry/signature mechanics)
