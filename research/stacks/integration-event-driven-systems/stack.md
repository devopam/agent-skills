# Baseline: Integration & Event-Driven Systems — Architecture & Stack
Status: user-approved      Date: 2026-08-19

## Local precedent — narrow, not a worked example

Checked directly this pass: `C:\Users\devop\GitHub\MCPg\src\mcpg\listen.py`
is a real, shipped LISTEN/NOTIFY-to-tool-poll bridge — a single dedicated
PostgreSQL connection holds every active `LISTEN`, a background
`asyncio.Task` drains notifies and fans them out to per-subscription
in-memory queues that MCP tool calls poll. Its own module docstring is
directly useful evidence for this baseline's durability section: "Per
ADR-0005, subscriptions live in process memory. On server restart they're
lost — agents must re-subscribe. Cross-replica fanout is out of scope for
v1; an operator wanting durability stands up a broker between PG and their
consumers." That is MCPg's own authors independently arriving at this
baseline's core claim — a bare pub/sub primitive without persistence is
not a substitute for a broker once delivery has to survive a restart or
fan out across replicas — worth one citation, not a worked example of
this category's architecture. MCPg is an MCP server with one narrow
messaging feature bolted on, not an integration platform, ETL system, or
workflow orchestrator. No other repo under `C:\Users\devop\GitHub\*`
(`MEDGraph`, `docker-mcp-registry`, `Obfuscatory`, `VSIP`, `presidio`)
touches message brokers, webhooks, or workflow engines. This category is
effectively greenfield, matching the Backend & API Services baseline's
finding — every recommendation below is backed by external primary
sources with direct fetches.

## In scope

- **How this category specializes the cross-cutting
  architecture-templates.md pattern catalog** — impact: high — depth:
  section. **Event-driven** is this category's home pattern, but "fits"
  needs to be split into two genuinely different things the cross-cutting
  doc treats as one axis: event-driven as a **communication style**
  (services react to events instead of calling each other synchronously —
  this is nearly always present somewhere in an integration system) versus
  event-driven as a **storage/state model**, i.e. event sourcing (the event
  log *is* the system of record, current state is a fold over history).
  The former is close to unconditional for this category; the latter stays
  behind the same rarely-justified bar the cross-cutting doc sets for
  CQRS/event sourcing generally — but this is the one category where that
  bar gets crossed more often than elsewhere, because an integration
  system's events are frequently already the durable, replayable artifact
  the business cares about (a payment-events topic, an order-lifecycle
  topic), not an implementation detail bolted onto a CRUD domain model.
  **Microservices** and **modular monolith** apply to the *services that
  produce/consume* events, not to the broker itself — the broker is
  shared infrastructure, not a service; the monolith-first heuristic still
  holds for the surrounding application code, with the broker as the one
  piece that's justified as a separate, shared component from day one once
  more than one service needs to communicate asynchronously. **Hexagonal**
  applies cleanly at the consumer boundary: the inbound port is "handle
  this event," the domain logic doesn't know or care whether the event
  arrived via Kafka, RabbitMQ, or a synchronous test harness — this is the
  same reasoning the Backend & API Services baseline used for HTTP
  handlers, applied to message handlers instead. **Serverless** fits
  individual event handlers well (a Lambda/Cloud Function triggered per
  message) but is a poor fit for the broker/queue infrastructure itself,
  which needs to be always-on, stateful infrastructure regardless of how
  spiky the workload is.

- **Message broker architecture: pub/sub vs. point-to-point queue, and
  when each fits** — impact: high — depth: table. These are genuinely
  different delivery topologies, not two names for the same thing:
  | Pattern | Delivery shape | Fits when | Representative tech |
  |---|---|---|---|
  | Point-to-point queue | Each message consumed by exactly one worker among a competing pool | Work distribution — a task should be done once, by whichever worker picks it up first (job queues, task processing) | SQS, RabbitMQ (classic queue with a single consumer group), a single-consumer-group Kafka topic |
  | Pub/sub (topic/fan-out) | Each message delivered to every independent subscriber | Multiple independent parties each need to know an event happened, for different reasons (order-placed triggers billing, shipping, and analytics independently) | Kafka (multiple consumer groups on one topic), NATS subjects, SNS, RabbitMQ topic exchange, Google Pub/Sub |
  Kafka and RabbitMQ can each be made to do either shape (Kafka's consumer
  groups give point-to-point *within* a group and pub/sub *across*
  groups; RabbitMQ's exchange types — direct/topic/fanout — cover both) —
  the distinction that actually matters for architecture decisions is
  **which shape a given integration point needs**, not which product was
  chosen, since most current brokers support both. The practical
  decision rule: ask "does exactly one consumer need this, or does every
  interested party need their own copy?" per integration point, not per
  system — a single platform commonly has both shapes present
  simultaneously (a point-to-point job queue for background work, a
  pub/sub topic for domain events), and forcing one topology
  everywhere is a common design mistake.

- **Event schema design and evolution** — impact: high — depth: section.
  A schema registry (see libraries.md for tooling) exists to solve one
  concrete problem: producers and consumers deploy independently, so the
  event schema **will** change while both old and new code are running
  simultaneously. Compatibility modes, using the Confluent/Avro
  terminology that's become the de facto vocabulary industry-wide even
  outside Confluent's own tooling:
  | Mode | Rule (Confluent's own wording, direct-fetch-confirmed) | Deployment order this allows |
  |---|---|---|
  | Backward compatible | "Consumers using the new schema can read data produced with the last schema" | **Upgrade all consumers before you start producing new events** — the new schema is a superset the new consumer code already understands, so it's safe to let consumers see new-shaped data before any exists; producers switch last |
  | Forward compatible | "Data produced with a new schema can be read by consumers using the last schema, even though they may not be able to use the full capabilities of the new schema" | **Upgrade all producers first**, and ensure data produced under the old schema is no longer available to consumers, **then** upgrade consumers — old consumer code stays functional (if capability-limited) against new-schema data |
  | Full compatible | Both hold simultaneously | Producers and consumers can be upgraded in **either order, independently** |
  Each mode also has a `_TRANSITIVE` variant (e.g. `BACKWARD_TRANSITIVE`)
  checked against every prior schema version in the subject's history, not
  just the immediately preceding one — the non-transitive variants only
  guard against a single-version skip, which understates the real
  compatibility risk in a system where a consumer might lag behind by
  more than one schema version. Confirmed by direct fetch of
  `docs.confluent.io/platform/current/schema-registry/fundamentals/
  schema-evolution.html`.
  The practical default for an evolving system with independently-deployed
  producers and consumers: **backward compatible** — this is not just a
  common convention, it is Confluent Schema Registry's own default
  compatibility mode for a newly registered subject ("The default
  compatibility mode is BACKWARD," confirmed by direct fetch of the same
  Confluent schema-evolution doc), which makes it the path of least
  resistance for a team using off-the-shelf registry tooling rather than
  a mode they'd need to consciously opt into. Concretely this means:
  upgrade consumer code to understand the next schema version *before*
  any producer starts emitting it, achieved mechanically by only ever
  adding optional fields with sensible defaults, never removing or
  repurposing a field, and never changing a field's type. A schema
  registry enforces the chosen mode at publish time (rejects a schema
  version that violates it before the change can reach production)
  rather than relying on code review discipline alone.
  **CloudEvents** (CNCF graduated project, graduated 25 January 2024,
  spec v1.0.2, confirmed by direct fetch of `github.com/cloudevents/spec`)
  is the relevant complementary standard here — not a schema-evolution
  mechanism itself, but a standard *envelope* (id, source, type,
  specversion, plus payload) so tooling across different brokers/languages
  can agree on event metadata shape; it composes with, rather than
  replaces, a schema registry's payload-body versioning.

- **Delivery semantics — exactly-once vs. at-least-once vs. at-most-once,
  the real trade-offs** — impact: high — depth: section, this is the
  single most load-bearing sub-topic in this baseline. **At-most-once**:
  a message is delivered zero or one times — the sender fires and doesn't
  wait for confirmation, or the consumer acks *before* processing. Nothing
  is ever double-processed, but messages are silently lost on any failure
  between send and process. Rarely the right choice for anything that
  matters, but legitimate for high-volume telemetry/metrics where losing
  an occasional sample is cheaper than the infrastructure to prevent it.
  **At-least-once**: the sender retries until it gets confirmation, or the
  consumer acks *after* successful processing — nothing is silently lost,
  but the same message can and will be delivered more than once (retry
  after a timeout that the original request actually succeeded past, a
  consumer crash after processing but before acking, a broker failover).
  This is the **default most production message-broker configurations
  actually deliver** — not a corner case to guard against occasionally,
  but the normal operating behavior a consumer must be built for. **Exactly-once
  ("EOS")**: nothing lost, nothing duplicated. Kafka's own EOS (KIP-98,
  confirmed by direct fetch of the Apache Kafka wiki KIP page — introduced
  in Kafka 0.11) is real and works via an idempotent producer (a
  producer ID plus a per-partition monotonic sequence number the broker
  uses to reject/dedupe a resent message) combined with transactions
  (atomic multi-partition writes, with the "read-process-write" cycle
  wrapped in a transaction so consuming, transforming, and re-producing to
  another topic happens as one atomic unit) — but this guarantee holds
  **within the Kafka cluster's own read-process-write cycle only**, and
  the KIP-98 design doc is explicit about the boundary even
  *inside* that cycle: "we cannot guarantee that all the messages of a
  committed transaction will be consumed all together" — confirmed by
  direct fetch of the KIP-98 wiki page itself — because compacted topics
  may overwrite some of a transaction's messages with newer versions,
  transactions can straddle log segments that get independently deleted
  by retention, and a consumer is free to seek arbitrarily within a
  transaction or skip partitions entirely. That caveat is *before* even
  reaching the harder boundary: the moment a side effect crosses out of
  Kafka entirely — an HTTP call to a third-party API, a write to a
  database that isn't itself transactionally coordinated with Kafka's
  offset commit, a call to another message broker — Kafka's EOS machinery
  has no way to make that external effect exactly-once, because it can't
  roll back an HTTP call that already fired. Both boundaries are facts
  "exactly-once" marketing claims across the industry consistently gloss
  over, and together they're the reason the field converges on a
  different, more honest practical answer:

  **Idempotent-consumer design is the practical answer to at-least-once
  being the common default.** Confirmed by direct fetch of
  `microservices.io/patterns/communication-style/idempotent-consumer.html`
  (Chris Richardson's own pattern catalog, the same primary source the
  Saga section below draws from): the pattern's definition is that
  "the outcome of processing the same message repeatedly must be the same
  as processing the message once," and the concrete mechanism is tracking
  processed-message identifiers — either a dedicated
  `PROCESSED_MESSAGES` table keyed by (subscriber ID, message ID) that a
  processing transaction inserts into atomically with its business-logic
  writes (a duplicate insert fails the unique constraint, the transaction
  rolls back, the duplicate is safely dropped), or, where the operation is
  *naturally* idempotent (an upsert keyed by a stable business ID, a
  "set balance to X" instead of "add X to balance"), no tracking table is
  needed at all because reprocessing produces the same end state by
  construction. Combining at-least-once delivery with an idempotent
  consumer is what the industry calls "effectively-once" processing — it
  is simpler than chasing true exactly-once across a system boundary
  Kafka's own EOS can't reach, and it's the pattern that generalizes
  across every broker (RabbitMQ, SQS, NATS), not just Kafka's
  transactional subset. **Decision rule**: default to at-least-once
  delivery (it's what most brokers give you without special
  configuration) plus an idempotent consumer for any handler with a
  real side effect; reach for exactly-once machinery only for the narrow
  case of a pure Kafka-to-Kafka read-process-write pipeline where the
  transactional guarantee's actual boundary (Kafka-internal only) is
  sufficient for the use case; treat at-most-once as an explicit,
  deliberate choice for loss-tolerant telemetry, not a default anyone
  should fall into by omission.

- **The Saga pattern — choreography vs. orchestration** — impact: high —
  depth: table, anchored on `microservices.io/patterns/data/saga.html`
  (Chris Richardson, direct-fetch-confirmed this pass — the primary
  reference most other sources — AWS Prescriptive Guidance, Temporal's own
  blog — themselves cite). The page's own definitions, quoted directly:
  "A saga is a sequence of local transactions. Each local transaction
  updates the database and publishes a message or event to trigger the
  next local transaction in the saga." For choreography: "Each local
  transaction publishes domain events that trigger local transactions in
  other services." For orchestration: "An orchestrator (object) tells the
  participants what local transactions to execute." When a step fails,
  the prior steps are undone via **compensating actions** rather than a
  cross-service ACID rollback (which doesn't exist in a distributed
  system without an expensive two-phase-commit coordinator most
  architectures deliberately avoid) — the page is explicit that this
  trades ACID guarantees for availability, and that concurrent sagas can
  introduce data anomalies needing their own countermeasures.
  | | Choreography | Orchestration |
  |---|---|---|
  | Control flow | Decentralized — each service publishes events and reacts to others' events independently | Centralized — one coordinator service tells each participant what to do and interprets the result |
  | Coupling | Lower — services only know event contracts, not each other | Higher — participants are coupled to the orchestrator's command contract |
  | Visibility / debuggability | Harder — the saga's overall state is implicit, reconstructed from scattered event logs across services | Easier — the orchestrator holds explicit state; "what step is this saga on" is one query away |
  | Fits well | Few participants, simple linear flows, teams already fully event-driven | More than a few participants, complex branching/compensation logic, need for centralized monitoring/retry of the saga itself |
  | Failure mode as it grows | Cyclic/implicit dependencies between services become hard to trace as participant count grows | Orchestrator becomes a single point of design complexity (though not necessarily a single point of runtime failure if built stateless/replayable) |
  **Decision rule**: start with choreography for a 2-3-participant saga
  in an already event-driven system — it's the lower-ceremony default and
  avoids introducing a new centralized component. Move to orchestration
  once the saga's compensation logic itself becomes hard to reason about
  scattered across services, or once the business needs a queryable
  "what state is this order in" view — at which point a durable
  workflow-orchestration engine (Temporal — see libraries.md) is the
  current default implementation for the orchestrator role, since it
  handles the orchestrator's own crash-recovery/replay problem instead of
  leaving that as another distributed-systems problem to solve by hand.

- **Dead-letter-queue and retry/backoff design** — impact: high — depth:
  section, anchored on `docs.aws.amazon.com/.../sqs-dead-letter-queues.html`
  (direct fetch) as the most concrete, mechanism-level primary source
  found this pass. A DLQ exists to isolate messages a consumer
  repeatedly fails to process, so they stop blocking/retrying forever
  and can be inspected. AWS SQS's own mechanics, confirmed by direct
  fetch, generalize well beyond SQS specifically: a **redrive policy**
  sets `maxReceiveCount` — the number of delivery attempts before a
  message moves to the DLQ — and AWS's own guidance is explicit that this
  number should be "high enough to allow for sufficient retries," not set
  reflexively low; for standard (non-FIFO) queues, once a message has been
  received 3+ times without being deleted, SQS moves it to the back of the
  queue rather than immediately redelivering it, which is itself a mild
  backoff mechanism baked into the queue's own redelivery behavior. AWS's
  docs also carry a specific, non-obvious warning worth preserving: don't
  attach a DLQ to a FIFO queue if strict message ordering matters, because
  pulling one message out to the DLQ breaks the ordering guarantee for
  everything behind it. **Retention**: DLQ retention should be set
  **longer** than the source queue's retention (AWS's own documented best
  practice), since a message's age is tracked from its *original* enqueue
  time on standard queues, not from when it landed in the DLQ — a DLQ with
  too-short retention can silently expire a message before anyone gets to
  investigate it. **Backoff strategy layered on top of the DLQ
  threshold**: fixed-interval retry is the simplest and worst choice for
  anything hitting a struggling downstream (all retries arrive in
  lockstep, prolonging the outage); **exponential backoff** (each retry
  waits longer than the last) is the standard mitigation; **exponential
  backoff with jitter** (randomizing the wait slightly) is the refinement
  that prevents a large population of retrying clients from
  re-synchronizing into new lockstep waves after the first backoff
  interval — this jitter detail is a well-established distributed-systems
  practice (originating from AWS's own "Exponential Backoff and Jitter"
  architecture blog post) rather than a Kafka- or SQS-specific mechanism,
  and it applies equally to broker-level redelivery and to
  application-level HTTP retry logic (webhook delivery, below, included).
  Library-level implementations of retry+backoff belong to libraries.md.

- **Webhook design — delivery guarantees, retries, signature
  verification** — impact: high — depth: section, filling the gap the
  Backend & API Services baseline explicitly deferred here. This baseline
  treats **Stripe's own webhook documentation**
  (`docs.stripe.com/webhooks`, direct fetch) as the primary worked
  reference — it is the most complete, concretely-specified real-world
  implementation of outbound webhook delivery found this pass, and its
  mechanics are specific enough to carry into the authored doc close to
  verbatim:
  - **Retry schedule**: Stripe's own docs state retries continue "for up
    to three days with an exponential backoff in live mode" (sandbox mode
    retries 3 times over a few hours instead) — this is Stripe's own
    stated policy, not a third-party estimate; the specific minute-by-
    minute retry intervals some third-party blogs publish are not
    confirmed by Stripe's own docs and are excluded here as unverified.
  - **Non-2xx and redirects are both failures**: Stripe's docs
    explicitly state that a `3xx` redirect response to a webhook request
    is treated as a delivery failure, not followed — a detail easy to
    miss when standing up a naive webhook receiver behind a load
    balancer that redirects.
  - **Fast-ack requirement**: the endpoint must return a `2xx` status
    quickly, before doing slow/complex processing — Stripe's docs
    recommend queuing the actual business-logic work asynchronously
    rather than processing inline, both to avoid timeout-triggered
    retries and to survive traffic spikes (their own example: many
    subscriptions renew at the start of a billing period, producing a
    burst).
  - **Signature verification mechanics**: a `Stripe-Signature` header
    carries a timestamp (`t=`) and one or more HMAC-SHA256 signatures
    (`v1=`, keyed to the endpoint's per-endpoint secret); the signed
    payload is `{timestamp}.{raw request body}`; verification must use a
    constant-time comparison (to prevent timing attacks) and must reject
    a timestamp too far from current time (Stripe's own libraries default
    to a 5-minute tolerance) specifically to prevent replay attacks —
    a captured valid payload+signature pair becomes unusable after the
    tolerance window even if replayed verbatim.
  - **Duplicate delivery is explicitly expected, not a bug**: Stripe's
    own best-practices section instructs receivers to log processed
    event IDs and skip already-seen ones — this is the idempotent-
    consumer pattern above, applied at the webhook-receiver boundary
    specifically, and Stripe's docs frame it as a required practice, not
    an edge case.
  - **IP allowlisting as a second, independent verification layer**
    alongside signature verification — Stripe publishes a fixed set of
    sending IPs; the docs recommend both mechanisms together, not
    signature verification alone.
  **Standard Webhooks** (`github.com/standard-webhooks/standard-webhooks`,
  a community specification backed by a technical steering committee
  including Zapier, Twilio, Mux, ngrok, Supabase, Svix, and Kong per its
  own repo) is the emerging attempt to standardize this exact
  HMAC-plus-timestamp-plus-replay-protection shape across providers so a
  receiver doesn't need bespoke verification code per vendor — its
  mechanics (documented in `spec/standard-webhooks.md`) closely mirror
  Stripe's own approach, which is corroborating evidence the shape above
  is a converged industry pattern, not one company's idiosyncratic
  design. Recommendation for a new project building outbound webhooks:
  implement Stripe's shape (HMAC-SHA256, timestamp+signature header,
  replay-window rejection, documented retry-with-backoff schedule,
  redirect-is-failure) directly, or adopt the Standard Webhooks spec and
  its reference libraries (see libraries.md) rather than reinventing it —
  either lands in the same place.

- **ETL/ELT integration-platform architecture — the fuzzy boundary with
  Data & Analytics Platforms, named explicitly** — impact: high — depth:
  section. The sibling Data & Analytics Platforms baseline covers
  ELT/ETL from the *analytics-consumer* framing: data lands in a
  warehouse/lakehouse for BI/analytical query, ELT is the dominant
  pattern because cloud-warehouse compute economics favor
  load-then-transform, and its baseline's own worked example (a
  from-source scraping pipeline) is analytics-shaped. **This category's
  framing is different in intent, even when the mechanics look similar**:
  system-to-system integration moves data *because another operational
  system needs it to function* — a CRM needs the latest order status, a
  billing system needs a subscription change, a partner's system needs a
  webhook — not because an analyst needs to query it later. The boundary
  is genuinely fuzzy rather than clean, and pretending otherwise would be
  dishonest: **Change Data Capture (CDC)** tooling (Debezium — see
  libraries.md) is the clearest example of something that serves both
  framings simultaneously — the same CDC stream off a production database
  can feed an operational event bus (this category) and a warehouse
  ingestion pipeline (the analytics baseline) with no difference in the
  underlying mechanism, only in what consumes the resulting topic.
  Practical rule of thumb for which baseline a given data-movement concern
  belongs to: if the destination is a warehouse/lakehouse and the
  consumer is a query engine or BI tool, it's the Data & Analytics
  Platforms baseline's territory (ELT, dbt-style transforms, data-quality
  testing frameworks); if the destination is another live operational
  system and the consumer is application code reacting to the data, it's
  this baseline's territory (message brokers, webhooks, CDC-to-event-bus,
  workflow orchestration coordinating multi-system operations). A single
  platform commonly needs both, sourced from the same CDC stream — that
  overlap is normal, not a modeling failure. **ETL still applies within
  this category specifically** (transform-before-load, not
  load-then-transform) when the destination system enforces a schema on
  write and can't be handed raw/malformed data — a legacy system-of-record
  a webhook must post clean, pre-validated payloads to is a concrete
  instance of exactly this ETL-shaped case, same reasoning the sibling
  baseline uses for its own ETL exception, just triggered by "the
  operational destination requires it" instead of "the analytical
  destination requires it."

- **Workflow orchestration — durable execution vs. DAG-scheduling, and
  where each fits this category** — impact: high — depth: paragraph,
  full tooling detail in libraries.md. Two genuinely different engine
  models exist and get conflated under "orchestration" generically:
  **DAG/schedule-oriented orchestration** (Airflow's original model —
  a DAG of tasks, typically triggered on a schedule or an external
  trigger, each task usually short-lived and stateless between runs) fits
  batch-shaped, primarily time-triggered work — this is the shape the
  Data & Analytics Platforms baseline already covers for pipeline
  scheduling. **Durable-execution orchestration** (Temporal's model — a
  workflow is regular code that can run for days, survive process
  crashes, and resume exactly where it left off, with the engine
  persisting execution history rather than just task-completion state)
  fits long-running, stateful business processes with real branching
  logic and human-in-the-loop or external-event waits — a multi-step
  order-fulfillment saga, a multi-day approval workflow, a Saga-pattern
  orchestrator (above) that needs to survive its own process restarting
  mid-saga. This is the discriminator that actually matters for *this*
  category: an integration system coordinating multiple external systems
  over an unpredictable timeframe (waiting on a partner's webhook that
  might arrive in five seconds or five days) is durable-execution-shaped,
  not DAG-schedule-shaped, even though both tools get marketed under
  "orchestration."

## Explicitly out of scope

- Specific library/broker/vendor names, licenses, and adoption signals —
  belongs entirely to the companion `libraries.md` baseline; this doc
  names categories, decision rules, and mechanisms only.
- Data-pipeline/analytics-specific ELT mechanics (dbt-style
  transformation, data-quality/data-testing frameworks, warehouse/
  lakehouse selection) — belongs to Data & Analytics Platforms; the
  fuzzy-boundary section above names where the two baselines' territory
  meets rather than duplicating either.
- Full REST/GraphQL/gRPC API design, versioning, and auth mechanics —
  belongs to Backend & API Services; this doc only covers the async/
  event-driven surface (webhooks, message consumption), consistent with
  that baseline's own explicit deferral.
- Deep service-mesh/mTLS/sidecar mechanics — out of scope for the same
  reason the Backend & API Services baseline excludes it: a
  maturity/scale threshold most early integration platforms don't cross.
  Named only where it intersects broker security (out of scope here
  entirely — broker-level authn/authz/TLS configuration is
  product-specific detail for libraries.md or an authored doc's
  operations section, not architecture).
- Two-phase commit / distributed-transaction coordinators (XA,
  cross-service ACID) — named only as the thing the Saga pattern exists
  to avoid, not researched as a viable alternative; the field has
  converged on sagas-plus-compensation over 2PC for cross-service
  consistency for reasons well outside this baseline's scope to relitigate.
- Stream-processing/computation frameworks proper (Kafka Streams, Flink,
  Spark Streaming as *stateful transformation* engines rather than as
  brokers) — these sit closer to the Data & Analytics Platforms
  baseline's stream-processing concerns than to this baseline's
  system-to-system integration framing; named here only as an open
  question below, not researched at depth this pass.
- Numeric performance-benchmark claims (broker throughput multipliers,
  "X% faster" migration figures) not traceable to a primary source —
  several turned up in search results this pass (blog "40-60% faster"
  style figures around message-broker migrations) and are deliberately
  excluded, matching this baseline's own no-unverified-numbers standard.
- Cost modeling / cloud-managed-broker pricing comparisons (MSK vs.
  Confluent Cloud vs. self-hosted TCO) — same no-pricing convention as
  the other stack baselines in this series.

## Sources

- Local repo direct read: `C:\Users\devop\GitHub\MCPg\src\mcpg\listen.py`
  — LISTEN/NOTIFY-to-tool-poll bridge, module docstring's own
  durability caveat ("subscriptions live in process memory... an
  operator wanting durability stands up a broker between PG and their
  consumers") — read 2026-08-19
- https://cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging
  — direct fetch: KIP-98, idempotent producer (producer ID + per-partition
  sequence number, duplicate-vs-out-of-sequence error handling) and
  transactional (atomic multi-partition write) mechanics, introduced
  Kafka 0.11; also the explicit consumer-side scope limit quoted in the
  stack — "we cannot guarantee that all the messages of a committed
  transaction will be consumed all together" (compacted-topic overwrites,
  log-segment deletion, arbitrary consumer seeks) — retrieved 2026-08-19
- https://microservices.io/patterns/communication-style/idempotent-consumer.html
  — direct fetch: idempotent-consumer pattern definition, the
  `PROCESSED_MESSAGES` table mechanism keyed by (subscriber ID, message
  ID) — retrieved 2026-08-19
- https://microservices.io/patterns/data/saga.html — direct fetch: Chris
  Richardson's own saga/choreography/orchestration definitions, quoted
  directly in the stack (choreography/orchestration framing further
  corroborated across AWS Prescriptive Guidance and Temporal's own blog,
  which independently converge on the same two-mode framing) — retrieved
  2026-08-19
- https://docs.confluent.io/platform/current/schema-registry/fundamentals/schema-evolution.html
  — direct fetch: exact backward/forward/full compatibility-mode
  definitions and their required deployment orders, the `_TRANSITIVE`
  variant distinction, and confirmation that BACKWARD is the registry's
  own default compatibility mode for a newly registered subject —
  retrieved 2026-08-19
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
  — direct fetch: redrive policy / `maxReceiveCount` mechanics,
  "moves to the back of the queue" behavior after 3+ receives on standard
  queues, DLQ-plus-FIFO ordering warning, DLQ-retention-longer-than-source
  best practice — retrieved 2026-08-19
- https://docs.stripe.com/webhooks — direct fetch: full webhook delivery
  mechanics — 3-day exponential-backoff retry in live mode / 3 retries
  over a few hours in sandbox, redirects treated as failures, fast-2xx-ack
  requirement, `Stripe-Signature` header mechanics (HMAC-SHA256,
  `t=`/`v1=` fields, signed payload = timestamp+"."+body, constant-time
  comparison, 5-minute default replay tolerance), duplicate-event-ID
  dedup as documented best practice, IP allowlisting as a second layer
  — retrieved 2026-08-19
- https://github.com/standard-webhooks/standard-webhooks — Standard
  Webhooks community spec, technical steering committee membership
  (Zapier, Twilio, Mux, ngrok, Supabase, Svix, Kong) — retrieved
  2026-08-19 (via search; spec body at `spec/standard-webhooks.md` not
  independently direct-fetched this pass, flagged in Open questions)
- https://github.com/cloudevents/spec — direct fetch: CNCF graduated
  25 January 2024, current spec version v1.0.2 — retrieved 2026-08-19
- Confluent/Avro schema-compatibility-mode vocabulary (backward/forward/
  full) — direct-fetched against Confluent's own docs this pass (see
  entry above); an earlier draft of this section had the backward-mode
  deployment-order justification backwards (conflated with forward
  compatibility's rationale) and was corrected against the primary
  source before this file was finalized
- AWS "Exponential Backoff and Jitter" architecture blog post — the
  originating primary source for jitter-on-backoff as a distributed-
  systems practice, referenced from training knowledge and corroborated
  by its continued citation across current retry-library documentation
  found in this pass's searches; not independently re-fetched this pass
  — flagged in Open questions
- Data & Analytics Platforms sibling baseline:
  `C:\Users\devop\GitHub\agent-skills\research\stacks\data-analytics-platforms\stack.md`
  — read directly for the ELT/ETL framing this doc's fuzzy-boundary
  section responds to — read 2026-08-19
- Backend & API Services sibling baseline:
  `C:\Users\devop\GitHub\agent-skills\research\stacks\backend-api-services\stack.md`
  — read directly to confirm what was explicitly deferred here
  (event-driven/message-broker architecture, webhook delivery/retry/
  signature mechanics) — read 2026-08-19
- architecture-templates.md cross-cutting baseline:
  `C:\Users\devop\GitHub\agent-skills\research\architecture-templates.md`
  — grepped for existing event-driven/CQRS framing this doc specializes
  — read 2026-08-19

## Open questions for the user

- Stream-processing frameworks (Kafka Streams, Flink) were placed
  out-of-scope as closer to the Data & Analytics Platforms baseline's
  territory — confirm that placement, since a strong case also exists for
  covering them here as "what a Saga orchestrator or CDC pipeline is
  commonly built on" rather than purely as an analytics concern.
  This baseline made a judgment call to exclude them for depth reasons,
  not because the boundary is obviously clean.
- The ETL/ELT fuzzy-boundary section proposes a destination-based rule of
  thumb (warehouse/BI-consumer → analytics baseline; live operational
  system/app-code-consumer → this baseline). Confirm this is the right
  level of prescriptiveness for the authored doc, versus stating the
  boundary is inherently case-by-case with no crisp rule at all.
- Event sourcing was named as "crossing the rarely-justified bar more
  often in this category than elsewhere" but not researched at the depth
  the cross-cutting doc gives CQRS generally (e.g., no direct fetch of a
  primary event-sourcing reference analogous to Fowler's CQRS bliki post).
  Confirm whether the authored doc needs a dedicated event-sourcing
  subsection or whether this paragraph-level treatment is sufficient.

## Resolutions (Checkpoint D review, 2026-08-19)

- **Stream-processing frameworks placement**: resolved — this baseline
  owns the topic (see `research/skill-flow-decisions.md`'s cross-checkpoint
  conflict resolution). Not researched at this depth during Checkpoint D
  itself; add Kafka Streams/Flink/Spark Structured Streaming coverage
  during Phase 2 authoring as new content, not a promotion of existing
  baseline material.
- **ETL/ELT fuzzy-boundary prescriptiveness**: keep the destination-based
  decision rule (warehouse/BI-consumer → analytics baseline; live
  operational system → this baseline) rather than declaring it fully
  case-by-case — matches this repo's established opinionated-default
  convention.
- **Event sourcing depth**: confirmed as-is (paragraph-level) — no
  dedicated subsection needed for v1.

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/integration-event-driven-systems.md
  — est. 480–540 lines (9 subsections per the In-scope list above,
  several as tables given the broker-topology/schema-evolution/saga/
  webhook sections' density; roughly matches the Backend & API Services
  baseline's actual length).
