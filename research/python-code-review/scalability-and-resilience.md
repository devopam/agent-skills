# Baseline: Scalability & Resilience
Status: user-approved      Date: 2026-08-24

## Resolutions (Checkpoint D review, 2026-08-24)

- **Rate limiting**: confirmed already covered by Security's baseline
  ("Rate limiting & brute-force defense," Checkpoint A) — this domain
  cross-references rather than duplicates.
- **Idempotency cross-reference**: accepted — point to
  `project-incubation/references/stacks/integration-event-driven-systems.md`,
  keep principle-only here.
- **Enterprise-tier HA/DR/sharding bullets**: keep as documentation-
  presence checklists (not code-inspection claims) rather than cutting
  entirely — matches the comprehensive-coverage directive while staying
  honest about what's actually verifiable from source.
- **Probe/worker-count duplication with Architecture**: confirmed — this
  domain cross-references Architecture's already-sourced content rather
  than re-listing it.

## Summary of verification against the original tool

The original tool's domain file (`original-tool/review-domains/scalability-and-resilience.md`,
117 lines) names three circuit-breaker libraries/patterns and three task queues as
examples inside bullet points, without version numbers or dates. All five were
re-verified directly against PyPI. Findings:

- `pybreaker` — current, actively maintained, **version bump needed**: original
  cites it generically; current is 1.4.1 (2025-09-21), 1 maintainer, Production/Stable.
- `circuitbreaker` — current, version 2.1.3 (2025-03-31), supports Python 3.8 through
  3.10+ per its classifiers — a wider but slightly staler-looking range than
  Dramatiq's 3.10-3.14 (below), consistent with predating pybreaker's later 2025
  release (see below).
- `Celery` — current, version 5.6.3 (2026-03-26), 5 maintainers listed, Production/Stable.
  Highest maintainer count of the three; original tool's citation holds.
- `RQ` — current, version 2.11.0 (2026-08-17), 2 maintainers, Production/Stable.
- `Dramatiq` — current, version 2.2.0 (2026-06-17), 1 maintainer (Bogdan Popa),
  actively released, requires Python >=3.10 per its classifiers — narrower runtime
  support than Celery/RQ (not independently version-checked this pass), worth noting
  as a trade-off when a codebase targets older Python.

No dead or renamed packages found among the original's five named tools — this is a
"confirm and add precision" domain, not a "correct and replace" one.

## Tier applicability (carried forward from original, minus rows moved out of scope)

| Check | Script | Web | Enterprise |
|-------|--------|-----|------------|
| Graceful degradation | No | Yes | Yes |
| Horizontal scaling readiness (statelessness) | No | Yes | Yes |
| Circuit breakers | No | Yes | Yes |
| Timeouts on external calls | No | Yes | Yes |
| Retry with backoff (tenacity — cross-ref standards-compliance.md) | No | Yes | Yes |
| Readiness probe present (HA consequence — cross-ref architecture.md) | No | Yes | Yes |
| Queue-based workloads (Celery/RQ/Dramatiq) | No | Optional | Yes |
| HA infra, DR strategy, sharding, chaos hooks | No | No | Yes |

The original's separate rows for "Health/liveness/readiness probes," "Statelessness,"
and "HA architecture" / "DR strategy" / "Multi-region readiness" / "Chaos engineering
hooks" (original lines 9-20) are consolidated above: probe mechanics stay with
Architecture's table (not duplicated here), and the four enterprise-only rows in the
original's bottom half collapse into one row pending the scope decision flagged in
Open Questions below.

## In scope

- **Circuit breaker libraries (pybreaker, circuitbreaker)** — impact: high — depth: paragraph.
  Both current and installable today. `pybreaker` (1.4.1, 2025-09-21) implements the
  Nygard "Release It!" circuit breaker with configurable failure thresholds, event
  listeners, thread-safety, optional Redis-backed shared state for multi-process
  deployments, and Tornado async support. `circuitbreaker` (2.1.3, 2025-03-31) is a
  lighter-weight `@circuit` decorator with closed/open/half-open state transitions and
  fallback function support, sync and async, supporting Python 3.8 through 3.10+ per
  its PyPI classifiers — a wider but slightly staler-looking runtime range than
  Dramatiq's 3.10-3.14 (below), consistent with its March 2025 release predating
  pybreaker's September 2025 one. Review angle: flag external service calls (HTTP
  clients, DB drivers, downstream API SDKs) with no circuit breaker AND no equivalent
  hand-rolled failure-threshold/open-state logic — not "must use these exact
  libraries," since a custom implementation of the same pattern is equally valid.

- **Distributed task queues (Celery, RQ, Dramatiq)** — impact: high — depth: paragraph.
  All three current and actively released as of the dates above. Celery remains the
  most load-bearing / widest-adopted choice per the original tool's citation and its
  5-maintainer listing (vs. RQ's 2 and Dramatiq's 1) — maintainer count is the one
  comparative signal actually returned by the PyPI fetches, so it's the one used here;
  broker support and tooling ecosystem claims are NOT independently verified this pass
  and are deliberately omitted rather than asserted from memory. Dramatiq requires
  Python >=3.10 per its classifiers, which is a real constraint for codebases pinned to
  older runtimes — flag this if a codebase both targets an older Python and uses
  Dramatiq (mismatch worth surfacing, not necessarily wrong). Review angle unchanged
  from original: background jobs running as in-process threads/`asyncio` tasks with no
  distributed queue behind them is the finding, not "which of the three queues" — that
  choice is a legitimate architectural decision, not a defect.

- **Health/liveness/readiness/startup probes — HA/resilience consequence angle only** —
  impact: high — depth: paragraph. The probe *taxonomy* (liveness restarts on hang,
  readiness gates traffic during dependency outages, startup protects slow-initializing
  apps from being killed mid-boot) is already sourced in
  `architecture.md` (lines 208-227, 389-397) against Kubernetes' own pod-lifecycle docs
  — do not re-derive that mechanics here. This domain's distinct angle: the *consequence*
  of a missing readiness probe specifically for HA — without one, a load balancer or
  Kubernetes Service keeps routing traffic to a pod whose DB connection or downstream
  dependency has dropped, turning one instance's dependency failure into
  user-visible errors across the fleet instead of a clean drain-and-retry. This is a
  cross-reference, not new sourcing; keep it to one paragraph tying probe absence to
  the HA failure mode, and point to Architecture for the taxonomy itself.

- **Retry with exponential backoff + jitter (tenacity)** — impact: med — depth: one line
  cross-reference only. Already verified current in `standards-compliance.md` (9.1.4,
  2026-02-07, active, section 9.1.4) — do not re-verify; cite that file's finding.

- **Statelessness / horizontal scaling readiness** — impact: high — depth: checklist.
  Retained from the original almost verbatim: no in-process session storage, session
  state externalized to Redis/Memcached/DB, file uploads to object storage (S3/GCS/
  Azure Blob) not local disk, DB connection pooling sized for multiple app instances,
  no reliance on local cron (use a distributed scheduler or external trigger). This is
  principle-level and doesn't need per-tool version sourcing — the pattern (statelessness
  enables horizontal scaling) is architecturally well-established, not a tool-currency
  claim.

- **Graceful degradation / backpressure** — impact: med — depth: checklist. Retained
  from original: cache-aside fallback to stale data, feature flags/kill switches,
  rate limiting (per-user and global), reject-or-queue rather than OOM under load.
  Kept principle-level; no single canonical tool to version-check here (rate limiting
  libraries are plausibly covered by a different domain — flag as an open question
  below rather than duplicating).

- **Timeouts on external calls** — impact: high — depth: one line. Retained as a
  Critical-tier check from the original ("no timeout on external service calls" causes
  cascading failure). This is a code-level pattern check (explicit timeout params on
  HTTP clients, DB drivers, queue operations), not a library-currency claim, so no
  separate sourcing needed beyond the circuit-breaker/retry citations above, which
  cover the same failure-cascade mechanism.

## Absence-reporting mechanic (distinctive to this domain — recommend keeping)

The original tool's most distinctive feature is that this domain explicitly reports
the ABSENCE of a pattern as a finding (original lines 94-109: a
`[SCALABILITY] NOT IMPLEMENTED: <pattern>` block with tier, risk, and recommendation,
plus a 1-10 scoring guide, lines 111-117, where zero patterns present scores low even
if nothing is technically broken — "the risk is latent"). No other domain in this
research set works this way; most flag what's wrong, not what's missing. Recommend
carrying this mechanic forward unchanged into the rebuilt skill — it's the reason the
out-of-scope calls above matter: a check the skill cannot actually verify from source
(HA infra topology, DR drill cadence) must not be silently scored as "not implemented,"
because that produces a false-positive finding against a codebase that may have
perfectly good HA/DR living in Terraform or a runbook the skill never reads. The
scoring guide and the NOT-IMPLEMENTED block format should be re-verified against
whatever reporting convention the rebuilt skill settles on (not necessarily identical
to the original's exact bracket-tag syntax), but the underlying "score the gap, not
just the bug" behavior is worth preserving as-is.

## Explicitly out of scope

- **Zero-downtime deployment patterns (rolling updates, blue-green, canary)** — this
  is infrastructure/orchestration configuration (Kubernetes Deployment strategy, load
  balancer config, CI/CD pipeline behavior), not something visible in a Python
  codebase's source. `architecture.md` already covers the adjacent code-level surface
  (process manager choice, worker-count reasoning, ASGI/WSGI deployment pattern —
  lines 149-202) — that is the correct home for anything code-visible about
  deployment. A code-review skill has no reliable way to inspect a cluster's rollout
  strategy from source alone; at most it could note the *absence* of a health check
  endpoint that a rolling-update strategy would depend on, which is already captured
  under the probes bullet above. Recommend this stay out of the rebuilt skill's scope
  entirely rather than being forced into a code-level check.

- **High Availability infrastructure (DB primary-replica, Redis Sentinel/Cluster,
  clustered brokers, load balancer topology)** — infra/ops configuration, not
  something a Python source-code reviewer can verify (these live in Terraform/Helm/
  cloud-console config, not `.py` files). The original tool's "enterprise tier" HA
  checklist (lines 64-70) is reasonable as *documentation-presence* checks (does the
  repo have a documented DR/HA runbook?) but not as code-inspection checks. Recommend
  narrowing to "flag if HA/DR is claimed as a requirement but no infra-as-code or
  runbook reference exists in the repo" rather than trying to verify the infra itself.

- **Disaster Recovery (RPO/RTO, backup strategy, DR drills)** — same reasoning as
  above: organizational/process artifacts, not code. At most, presence-of-documentation
  is checkable; the content of an RPO/RTO commitment is a business decision outside a
  code reviewer's remit. Not researched further this pass — treat as out of scope for
  a Python code-review skill.

- **Idempotent operations** — kept principle-only per pacing instructions: "safe to
  retry without side effects" (e.g., using an idempotency key on payment/order-creation
  endpoints, `INSERT ... ON CONFLICT` instead of blind insert, checking-before-acting in
  retry paths). Not independently re-sourced this pass. A more detailed treatment likely
  belongs in `skills/project-incubation/references/stacks/integration-event-driven-
  systems.md` (confirmed to exist at that path, not read in full this pass) — flagged
  as an open question below rather than duplicated here.

- **Distributed transactions (saga, 2PC), event sourcing/CDC, sharding/partitioning
  strategy, conflict resolution for multi-writer scenarios** — original tool's
  "enterprise tier" bullets (lines 80-85). These are deep architectural topics each
  deserving their own research pass if kept; not verified this pass due to budget.
  Recommend either cutting to a single "distributed data consistency strategy
  documented" checklist line, or deferring to a future dedicated research pass — do not
  carry the original's implied depth forward without sourcing.

- **Chaos engineering hooks (toxiproxy, chaos-monkey)** — original tool's Minor-tier
  bullet (line 88). Not verified this pass; low impact, checklist-depth at most if
  retained.

## Sources

- https://pypi.org/project/pybreaker/ — version 1.4.1, released 2025-09-21, 1
  maintainer, Production/Stable, Redis-backed shared state and Tornado async support
  confirmed — retrieved 2026-08-24
- https://pypi.org/project/circuitbreaker/ — version 2.1.3, released 2025-03-31,
  `@circuit` decorator, closed/open/half-open states, sync+async support confirmed —
  retrieved 2026-08-24
- https://pypi.org/project/celery/ — version 5.6.3, released 2026-03-26, 5
  maintainers, Production/Stable — retrieved 2026-08-24
- https://pypi.org/project/rq/ — version 2.11.0, released 2026-08-17, 2 maintainers,
  Production/Stable — retrieved 2026-08-24
- https://pypi.org/project/dramatiq/ — version 2.2.0, released 2026-06-17, 1
  maintainer, requires Python >=3.10 — retrieved 2026-08-24
- `C:\Users\devop\GitHub\agent-skills\research\python-code-review\architecture.md`
  (lines 208-227, 389-397) — Kubernetes probe taxonomy (liveness/readiness/startup),
  already sourced against Kubernetes' own pod-lifecycle docs; cross-referenced not
  re-fetched
- `C:\Users\devop\GitHub\agent-skills\research\python-code-review\standards-compliance.md`
  (line 268, section 9.1.4) — tenacity 9.1.4 (2026-02-07), active; cross-referenced not
  re-verified

## Open questions for the user

- Rate limiting: original tool lists "rate limiting to protect against traffic spikes"
  under this domain's Graceful Degradation section. Is a rate-limiting library
  (e.g., `slowapi`, `django-ratelimit`, framework-native limiters) already covered by
  a different already-researched domain (e.g., a security or standards-compliance
  pass), or does it belong here and need its own verification pass?
- Idempotency: confirm whether `integration-event-driven-systems.md` under
  project-incubation is the right cross-reference target and whether its idempotency
  content is detailed enough to link to directly, or whether this domain needs its own
  short idempotency section with sourced examples (e.g., Stripe's idempotency-key
  pattern, HTTP PUT-is-idempotent semantics).
- Enterprise-tier HA/DR/sharding bullets (original lines 64-92): confirm whether the
  rebuilt skill should keep these as documentation-presence checklists (my
  recommendation above) or cut them entirely as out of a Python-code-reviewer's remit.
  This materially affects estimated length below.
- Should this domain's file explicitly point to Architecture's worker-count/deployment
  section rather than re-listing "process manager present" as its own check, to avoid
  duplicate checks across two domain files scoring the same underlying evidence?

## Target file(s) + estimated length

- `skills/python-code-review/references/scalability-and-resilience.md` — est. 90-130
  lines if enterprise-tier HA/DR/sharding bullets are trimmed to documentation-presence
  checklists per the recommendation above (roughly in line with the original's 117
  lines, since most of it survives review at checklist depth); est. 150-180 lines if the
  user wants deeper per-bullet sourcing on HA infra, DR, and distributed-consistency
  topics restored to paragraph depth — that would require a follow-up research pass,
  not something this budget covered.
