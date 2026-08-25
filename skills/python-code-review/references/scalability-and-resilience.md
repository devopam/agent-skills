# Scalability & Resilience

This is the scalability-and-resilience domain of the `python-code-review`
skill's domain set. It reviews whether a codebase survives the failure
modes that only show up under load or under a dependency outage: no
circuit breaker on an external call, no timeout, in-process background
work standing in for a real task queue, session state pinned to one
instance. Two sibling files own adjacent territory this file deliberately
doesn't re-derive: [Security](../references/security.md#rate-limiting-and-brute-force-defense)
owns rate limiting in depth (per-IP/per-account limits, lockout, CAPTCHA);
[Architecture](../references/architecture.md#health-readiness-and-startup-probes)
owns the probe taxonomy (liveness restarts, readiness gates traffic,
startup protects slow boots) and the worker-count/process-manager
mechanics — this domain's angle on probes is narrower and different: the
HA consequence of a missing one, not the mechanics of adding one.

This domain also works differently from most of this skill's other
files. Where most domains flag code that's present and wrong, this one
spends at least as much effort flagging a *pattern that's absent
entirely* — see [Reporting Absence as a Finding](#reporting-absence-as-a-finding)
below. A codebase with zero circuit breakers, zero timeouts, and an
in-process job runner standing in for a queue has no active bug to point
at, and that's exactly the finding: the risk is latent until the first
outage, not until someone reads a stack trace.

## Table of Contents

- [Tier Applicability](#tier-applicability)
- [Reporting Absence as a Finding](#reporting-absence-as-a-finding)
- [Circuit Breakers](#circuit-breakers)
- [Distributed Task Queues](#distributed-task-queues)
- [Timeouts on External Calls](#timeouts-on-external-calls)
- [Retry with Backoff (Cross-Reference)](#retry-with-backoff-cross-reference)
- [Readiness Probes: the HA Consequence](#readiness-probes-the-ha-consequence)
- [Statelessness and Horizontal Scaling](#statelessness-and-horizontal-scaling)
- [Graceful Degradation and Backpressure](#graceful-degradation-and-backpressure)
- [Idempotency (Cross-Reference)](#idempotency-cross-reference)
- [Enterprise-Tier HA, DR, and Data Consistency](#enterprise-tier-ha-dr-and-data-consistency)
- [Out of Scope](#out-of-scope)
- [Scoring Guide](#scoring-guide)
- [Sources](#sources)

---

## Tier Applicability

| Check | Script | Web | Enterprise |
|---|---|---|---|
| Timeouts on external calls (HTTP clients, DB drivers, queue ops) | No | Yes | Yes |
| Circuit breakers on external service calls | No | Yes | Yes |
| Retry with exponential backoff + jitter (tenacity — cross-ref [standards-compliance.md](standards-compliance.md)) | No | Yes | Yes |
| Statelessness / horizontal-scaling readiness | No | Yes | Yes |
| Readiness probe present (HA consequence — cross-ref [architecture.md](architecture.md#health-readiness-and-startup-probes)) | No | Yes | Yes |
| Graceful degradation / backpressure | No | Yes | Yes |
| Rate limiting (cross-ref [security.md](security.md#rate-limiting-and-brute-force-defense)) | No | Yes | Yes |
| Distributed task queue for background work (Celery/RQ/Dramatiq) | No | Optional | Yes |
| Idempotency on retried/at-least-once operations (cross-ref [integration-event-driven-systems.md](../../project-incubation/references/stacks/integration-event-driven-systems.md#delivery-semantics-exactly-once-vs-at-least-once-vs-at-most-once)) | No | Optional | Yes |
| HA infra, DR strategy, sharding, chaos hooks (documentation-presence only) | No | No | Yes |

A script-tier project has no fleet to keep available and no traffic spike
to absorb — none of this domain's checks apply until a second instance,
a real user base, or an SLA enters the picture. Timeouts, circuit
breakers, retries, statelessness, and a readiness probe become real the
moment a project moves to web tier: these are the load-bearing minimum
for a service other people depend on. A distributed task queue is
optional at web tier — a lot of legitimate web-tier services have no
background-job surface at all — and becomes expected once enterprise
scale and reliability commitments are in play. HA infrastructure, DR
strategy, sharding, and chaos-engineering hooks are enterprise-only, and
even there this domain checks for their *documentation*, not their
implementation — see [Enterprise-Tier HA, DR, and Data Consistency](#enterprise-tier-ha-dr-and-data-consistency).

---

## Reporting Absence as a Finding

Most domains in this skill review code that exists and point out what's
wrong with it. This domain does that too, but its more distinctive job
is reviewing for patterns that **don't exist at all** — and reporting
that absence as a finding in its own right, not as a footnote to
something else. A codebase can pass every other check in this file and
still be one dependency outage away from cascading failure if it has no
circuit breaker anywhere, because nothing in the code is technically
broken until the moment it is.

Findings of this shape should read as:

```
[SCALABILITY] NOT IMPLEMENTED: <pattern>
Tier: <script | web | enterprise>
Risk: <what happens under the failure condition this pattern exists to contain>
Recommendation: <specific library or pattern, matched to what the codebase already uses>
```

For example: a Flask service that calls three downstream APIs with
`requests.get()` and no `timeout=` argument anywhere, no circuit breaker,
and no retry logic gets three separate `NOT IMPLEMENTED` findings — one
per pattern — each naming the specific call sites at risk, not a single
vague "improve resilience" note.

This shapes the scoring guide too: **a codebase with zero resilience
patterns present scores low even when nothing is actively on fire.**
Absence of a bug is not evidence of resilience — it's evidence the
codebase hasn't yet met the failure condition that would expose the gap.
See [Scoring Guide](#scoring-guide).

The corollary is just as important: this mechanic only applies to
patterns actually verifiable from the Python source in front of the
reviewer. HA infrastructure topology, DR drill cadence, and cluster
failover configuration live in Terraform, Helm charts, or a runbook this
skill never reads — reporting those as `NOT IMPLEMENTED` from source
absence alone would be a false positive against a codebase that may have
perfectly good HA/DR sitting one directory over, or one repo over. That's
why the enterprise-tier bullets below are scoped to *documentation
presence*, not inferred implementation — see
[Enterprise-Tier HA, DR, and Data Consistency](#enterprise-tier-ha-dr-and-data-consistency).

---

## Circuit Breakers

Two libraries are current and installable today; recommend whichever
fits the codebase's existing async/threading model rather than treating
either as the default:

- **`pybreaker`** (1.4.1, released 2025-09-21, Production/Stable)
  implements the Nygard "Release It!" circuit breaker: configurable
  failure thresholds, event listeners for state-transition hooks,
  thread-safety, optional Redis-backed shared state for coordinating
  breaker state across multiple processes or hosts, and Tornado async
  support.
- **`circuitbreaker`** (2.1.3, released 2025-03-31) is a lighter-weight
  `@circuit` decorator with the standard closed → open → half-open state
  machine and fallback-function support, covering both sync and async
  call sites. Its PyPI classifiers list Python 3.8 through 3.10+ — a
  wider but slightly staler-looking runtime range than Dramatiq's
  3.10–3.14 below, consistent with a March 2025 release predating
  pybreaker's later September 2025 one.

**Review angle:** flag external service calls — HTTP clients, DB
drivers, downstream API SDKs — with no circuit breaker *and* no
equivalent hand-rolled failure-threshold/open-state logic. This is not
"must use pybreaker or circuitbreaker specifically": a custom
implementation of the same closed/open/half-open pattern is an equally
valid pass. The finding is the absence of the pattern, not the absence
of a particular package.

---

## Distributed Task Queues

All three of the original checklist's named queues are current and
actively released:

- **Celery** — 5.6.3 (2026-03-26), 5 maintainers, Production/Stable.
  Highest maintainer count of the three and the widest-adopted choice —
  the natural default recommendation absent a reason to prefer another.
- **RQ** — 2.11.0 (2026-08-17), 2 maintainers, Production/Stable. The
  simpler Redis-backed option, a reasonable fit when Celery's broker
  flexibility and feature surface aren't needed.
- **Dramatiq** — 2.2.0 (2026-06-17), 1 maintainer, actively released.
  **Requires Python >=3.10** per its classifiers — a real constraint
  worth flagging if a codebase both targets an older Python floor and
  uses Dramatiq, since that combination won't upgrade cleanly.

Maintainer count is the one comparative signal these package registries
actually expose — broker-support breadth and tooling-ecosystem claims
beyond that aren't asserted here.

**Review angle:** the finding is background jobs running as in-process
threads or bare `asyncio` tasks with no distributed queue behind them —
work that dies with the process, can't be retried independently, and
doesn't survive a deploy mid-flight. It is *not* "which of the three
queues is used" — that choice is a legitimate architectural decision on
its own merits, not a defect to flag either way.

---

## Timeouts on External Calls

A Critical-tier check on its own, independent of whether a circuit
breaker is also present: every external call — HTTP client request, DB
driver query, queue operation — needs an explicit timeout. A call with
no timeout blocks its worker (or its whole event loop, under `asyncio`)
for as long as the remote end takes to fail, which under load is
frequently "never" — one slow or hung dependency exhausts the worker
pool and takes the whole service down with it. This is the same
cascading-failure mechanism circuit breakers and backoff-retries exist
to contain, so it shares their sourcing rather than needing its own:
look for `timeout=` (or the driver-specific equivalent) on every
outbound `requests`/`httpx` call, DB connection/query, and queue publish
or consume operation, and flag any that rely on the library's default —
which, for several popular HTTP clients, is no timeout at all.

---

## Retry with Backoff (Cross-Reference)

Retry logic with exponential backoff and jitter is owned by
[standards-compliance.md](standards-compliance.md), which verified
**tenacity** at 9.1.4 (released 2026-02-07, actively maintained, no
displacement found) in its own currency pass. This domain doesn't
re-verify it — flag a bare retry loop with fixed-interval sleeps or no
jitter as a finding, and point to tenacity as the fix, but the library
research lives in that file.

---

## Readiness Probes: the HA Consequence

Architecture's [probe section](architecture.md#health-readiness-and-startup-probes)
already covers the taxonomy — liveness restarts a hung container,
readiness pulls a pod out of a load balancer's rotation without
restarting it, startup protects a slow-initializing process from being
killed mid-boot — sourced directly against Kubernetes' own pod-lifecycle
docs. This domain doesn't re-derive that; the angle here is narrower and
specific to resilience: **what happens to the fleet when a readiness
probe is missing entirely.** Without one, a load balancer or Kubernetes
Service has no signal that a given pod's DB connection or downstream
dependency has dropped, and keeps routing live traffic to it anyway —
turning what should be one instance's dependency failure, cleanly
drained and retried elsewhere, into user-visible errors smeared across
the whole fleet. Flag a missing readiness probe on any service running
behind a load balancer or orchestrator, and cite Architecture for the
probe taxonomy itself rather than re-explaining it here.

---

## Statelessness and Horizontal Scaling

No single library governs this — the pattern (statelessness enables
horizontal scaling) is architecturally well-established rather than a
tool-currency claim — so this stays checklist depth:

- No in-process session storage (an in-memory dict, a `Flask` session
  backed by the default signed-cookie-only or filesystem session
  interface) — session state externalized to Redis, Memcached, or a
  database instead.
- File uploads written to object storage (S3, GCS, Azure Blob), not
  local disk — local disk doesn't survive a pod reschedule and isn't
  shared across replicas.
- DB connection pooling sized with multiple app instances in mind, not
  just one process's concurrency — see Architecture's
  [connection-pooling section](architecture.md#connection-pooling--architectures-lens-only)
  for the pool-sizing angle specifically.
- No reliance on local cron (`cron`, APScheduler running in-process) for
  anything that must run exactly once across a fleet — use a distributed
  scheduler or an external trigger instead, or every replica fires the
  job independently.

Any one of these is a finding on its own; together they're the
difference between "add another replica" being a one-line config change
and being an incident.

---

## Graceful Degradation and Backpressure

Also checklist depth — no single canonical library to version-check
here, and rate limiting specifically is owned by
[Security](security.md#rate-limiting-and-brute-force-defense) rather
than duplicated in this list:

- Cache-aside reads fall back to serving stale data on a cache-backend
  outage, rather than the whole request failing when the cache is
  unreachable.
- Feature flags or kill switches exist for non-essential functionality,
  so a degraded dependency can be shed without a full outage.
- The service rejects or queues excess load rather than accepting
  everything and running out of memory under it — an unbounded queue or
  unbounded thread pool is the same failure mode as no backpressure at
  all, just delayed.
- Rate limiting, per-user and global, protects against traffic spikes —
  see Security's file for the actual checklist (per-IP/per-account
  limits, lockout behavior, CAPTCHA) rather than re-listing it here.

---

## Idempotency (Cross-Reference)

Kept principle-only in this domain by design. The short version: an
operation is safe to retry without side effects — an idempotency key on
payment or order-creation endpoints, `INSERT ... ON CONFLICT` in place of
a blind insert, checking state before acting inside a retry path. This
matters directly to this domain's other checks: a retry-with-backoff
policy or an at-least-once task queue is only actually safe once the
operation it's retrying is idempotent, otherwise the retry *is* the bug
(a duplicate charge, a duplicate order). The deeper treatment — delivery
semantics, the idempotent-consumer pattern, and worked examples — lives
in
[integration-event-driven-systems.md's delivery-semantics section](../../project-incubation/references/stacks/integration-event-driven-systems.md#delivery-semantics-exactly-once-vs-at-least-once-vs-at-most-once);
this file cross-references it rather than re-deriving it.

---

## Enterprise-Tier HA, DR, and Data Consistency

High availability infrastructure (DB primary-replica failover, Redis
Sentinel/Cluster, clustered message brokers, load balancer topology),
disaster recovery (RPO/RTO commitments, backup strategy, DR drill
cadence), and distributed data consistency (sharding/partitioning
strategy, saga/2PC for distributed transactions, conflict resolution for
multi-writer scenarios) are all real enterprise-tier concerns — and all
of them live in Terraform, Helm charts, cloud-console configuration, or
an operational runbook, not in `.py` source. A Python code reviewer has
no reliable way to verify any of these directly, so this domain treats
them as **documentation-presence checklists**, not code-inspection
claims:

- Is there a documented DR/HA runbook or infra-as-code reference in the
  repo backing an HA or DR requirement the project claims to meet?
- Is a distributed-data-consistency strategy documented anywhere the
  repo can point to, for a system that spans multiple writers or
  services?

The finding, when one applies, is "HA/DR is claimed as a requirement
(in a README, an SLA, a compliance doc) but no infra-as-code or runbook
reference exists in the repo" — never "no HA/DR implementation found,"
which this domain has no way to verify and would be a false positive
against infrastructure the skill simply can't see.

---

## Out of Scope

- **Zero-downtime deployment patterns** (rolling updates, blue-green,
  canary) — Kubernetes Deployment strategy, load balancer configuration,
  and CI/CD pipeline behavior, none of it visible in Python source.
  Architecture's [ASGI/WSGI deployment section](architecture.md#asgiwsgi-deployment-and-process-management)
  covers the code-visible adjacent surface (process manager choice,
  worker-count reasoning). At most, this domain can note the *absence*
  of a health check endpoint a rolling-update strategy would depend on —
  already covered under [Readiness Probes](#readiness-probes-the-ha-consequence).
- **High availability infrastructure implementation** and **disaster
  recovery implementation** — infra/ops configuration; see
  [Enterprise-Tier HA, DR, and Data Consistency](#enterprise-tier-ha-dr-and-data-consistency)
  for the documentation-presence check this domain uses instead.
- **Distributed transactions (saga, 2PC), event sourcing/CDC, and
  sharding/partitioning strategy in depth** — each is a deep
  architectural topic on its own; kept at the single documentation-
  presence checklist line above rather than expanded to paragraph depth.
- **Chaos engineering hooks** (toxiproxy, chaos-monkey, and similar) —
  low-impact, checklist-depth at most: does the codebase or its test
  suite have any fault-injection tooling wired in at all.
- **Rate limiting implementation detail** — owned by
  [Security](security.md#rate-limiting-and-brute-force-defense); this
  domain references it under Graceful Degradation rather than
  duplicating it.
- **Idempotency implementation detail** — owned by
  [integration-event-driven-systems.md](../../project-incubation/references/stacks/integration-event-driven-systems.md#delivery-semantics-exactly-once-vs-at-least-once-vs-at-most-once);
  see [Idempotency](#idempotency-cross-reference) above.
- **Probe taxonomy and worker-count/deployment mechanics** — owned by
  [Architecture](architecture.md#health-readiness-and-startup-probes);
  this domain covers only the HA consequence of a missing readiness
  probe.

---

## Scoring Guide

Scoring here weighs *presence of pattern*, not just absence of an active
bug — a codebase with nothing broken and nothing implemented still
scores low, because the risk is latent rather than triggered. See
[Reporting Absence as a Finding](#reporting-absence-as-a-finding).

- **10** — Timeouts on every external call, circuit breakers around
  downstream dependencies, retry-with-backoff via tenacity, a readiness
  probe backing the load balancer's routing decisions, statelessness
  fully externalized (sessions, uploads, scheduling), and a distributed
  task queue behind background work where one is warranted.
- **8-9** — Core patterns (timeouts, circuit breakers, statelessness)
  in place; one gap, such as a missing readiness probe or background
  jobs still running in-process on an otherwise-resilient service.
- **6-7** — Timeouts present but circuit breakers and backoff-retry are
  absent or informal (hand-rolled without the open-state/half-open
  behavior); statelessness partially externalized.
- **4-5** — No circuit breakers, no distributed task queue for
  background work that clearly needs one, session state or file uploads
  still local to the instance. Nothing actively broken yet, but the
  service cannot survive a dependency outage or a second replica without
  incident.
- **1-3** — No timeouts on external calls (a single hung dependency can
  take the whole service down), no readiness probe on a load-balanced
  service, and no resilience pattern present anywhere in the codebase.

---

## Sources

- <https://pypi.org/project/pybreaker/> — version 1.4.1, released
  2025-09-21, 1 maintainer, Production/Stable, Redis-backed shared state
  and Tornado async support confirmed. Retrieved 2026-08-24.
- <https://pypi.org/project/circuitbreaker/> — version 2.1.3, released
  2025-03-31, `@circuit` decorator, closed/open/half-open states,
  sync+async support confirmed. Retrieved 2026-08-24.
- <https://pypi.org/project/celery/> — version 5.6.3, released
  2026-03-26, 5 maintainers, Production/Stable. Retrieved 2026-08-24.
- <https://pypi.org/project/rq/> — version 2.11.0, released 2026-08-17,
  2 maintainers, Production/Stable. Retrieved 2026-08-24.
- <https://pypi.org/project/dramatiq/> — version 2.2.0, released
  2026-06-17, 1 maintainer, requires Python >=3.10. Retrieved
  2026-08-24.
- [`architecture.md`](architecture.md#health-readiness-and-startup-probes)
  — Kubernetes probe taxonomy (liveness/readiness/startup), sourced
  against Kubernetes' own pod-lifecycle docs; cross-referenced, not
  re-fetched.
- [`standards-compliance.md`](standards-compliance.md) (§9.1.4) —
  tenacity 9.1.4 (2026-02-07), actively maintained; cross-referenced,
  not re-verified.
- [`security.md`](security.md#rate-limiting-and-brute-force-defense) —
  rate limiting and brute-force defense checklist; cross-referenced, not
  duplicated.
- [`integration-event-driven-systems.md`](../../project-incubation/references/stacks/integration-event-driven-systems.md#delivery-semantics-exactly-once-vs-at-least-once-vs-at-most-once)
  — idempotent-consumer pattern and delivery-semantics depth;
  cross-referenced, not duplicated.
- `research/python-code-review/scalability-and-resilience.md` (this
  repo) — the approved research baseline this file was authored from;
  retained as the provenance record for the decisions above.
