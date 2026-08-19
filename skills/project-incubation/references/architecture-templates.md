# Architecture Template Selection

**Scope note — read this first:** this entire document applies to the
**software path only**. If the project is documentation, research, a
knowledge base, or a dataset rather than code, skip this file entirely —
there's no code architecture to select a pattern for. That fork happens
earlier, during inception, before stack-category selection.

This doc covers, for software projects: the named architecture-pattern
catalog, the decision framework that connects a project's real signals to
a recommendation, Architecture Decision Records as the mechanism for
writing that recommendation down, and a set of cross-cutting concerns
(database choice, API design, network topology, security touchpoints,
storage tiers, frontend architecture) that sit alongside the structural
pattern choice rather than inside it.

**One framing to hold onto throughout:** the output of the decision
framework below is not "pick one pattern." Most real systems combine a
structural pattern with a communication style and a runtime target — the
framework's job is to produce something like *"modular monolith, with an
event-driven overlay for ingestion"* or *"event-driven microservices on
serverless compute,"* not to force a single pure answer. See
[Composing patterns across three axes](#composing-patterns-across-three-axes).

## Table of contents

- [The pattern catalog](#the-pattern-catalog)
  - [Stack-category pairings](#stack-category-pairings)
- [Composing patterns across three axes](#composing-patterns-across-three-axes)
- [The decision framework](#the-decision-framework)
  - [Signal table](#signal-table)
  - [Decision sequence](#decision-sequence)
  - [Compliance signals](#compliance-signals)
  - [What a well-formed answer looks like](#what-a-well-formed-answer-looks-like)
- [Recording the decision: Architecture Decision Records](#recording-the-decision-architecture-decision-records)
- [Cross-cutting: database selection](#cross-cutting-database-selection)
- [Cross-cutting: API design and versioning](#cross-cutting-api-design-and-versioning)
- [Cross-cutting: network topology](#cross-cutting-network-topology)
- [Cross-cutting: security-by-design touchpoints](#cross-cutting-security-by-design-touchpoints)
- [Cross-cutting: storage tier selection](#cross-cutting-storage-tier-selection)
- [Cross-cutting: UX/frontend architecture](#cross-cutting-uxfrontend-architecture)
- [Sources](#sources)

## The pattern catalog

Seven named patterns. Each row is a genuine option, not a strawman — the
fit signals and trade-offs are what should actually move the decision,
not the pattern's popularity.

| Pattern | Fit signals | Honest trade-offs |
|---|---|---|
| **Layered / N-tier** | Small-to-mid team, low-to-moderate domain complexity, standard deployment (VM/PaaS), CRUD-shaped domain, low-to-moderate scale | Fast to build, easy to onboard new engineers into. Without discipline, the "business logic" layer becomes a dumping ground, and layers usually aren't isolated behind real interfaces — swapping infrastructure later means touching the layer, not just an adapter. |
| **Hexagonal (ports & adapters)** | Domain logic worth protecting from infrastructure churn (multiple real adapters expected — DB, queue, external provider), team disciplined enough to maintain the boundary, moderate-to-high domain complexity | Real testability and infrastructure-swap wins when the ports actually get exercised. AWS Prescriptive Guidance names the cost directly: added complexity, more moving parts to maintain, and potential latency from the extra indirection. Pays off only when you actually swap or mock an adapter — a hexagon with one adapter per port is paying the cost for nothing. |
| **Microservices** | Multiple teams needing independent deploy cadence, domain boundaries already understood (not still being discovered), an organizational or scale problem a single deployable genuinely can't solve | Fowler's "microservice premium": a fixed operational cost (deployment pipelines, service discovery, distributed monitoring, network reliability) paid *before* any benefit shows up. The trigger is domain complexity and organizational scale, not team headcount or line count. |
| **Modular monolith** | Single deployable is acceptable, team wants internal boundaries without paying the deploy-independence tax yet — the default starting point for most new projects | Shopify's production case: modularity without adding deployment units, "the advantages of both monoliths and microservices without so many of the downsides." The risk is boundary erosion — nothing *enforces* the module discipline the way separate deployables would, so it has to be a real practiced discipline, not just a directory layout. |
| **Event-driven** | Naturally asynchronous workloads (ingestion, notification fan-out, cross-system integration), need to decouple producers from consumers, tolerance for eventual consistency | Real decoupling and independent scalability. Debugging a request that crosses several event hops is harder than following a call stack; ordering and idempotency become first-class design problems, not edge cases. |
| **CQRS / event sourcing** | Genuine read/write asymmetry, a complex domain where a full audit trail of state changes has real value, team willing to accept eventual consistency and event-schema versioning as ongoing costs | Fowler's own caution, stated plainly: appropriate only for complex domains or read/write-disparate high-performance systems — "in the majority of cases... this has not been a good idea." Azure's event sourcing guidance adds concrete problems: idempotent event handling, versioning events over time, and a real tension with GDPR right-to-erasure since you can't just delete a fact from an immutable log. |
| **Serverless** *(runtime axis — composes with the others, doesn't compete)* | Spiky or unpredictable traffic, event-triggered workloads, team wants to own zero infrastructure, workload duration fits function time limits | Pay-per-use looks cheap until traffic is steady — AWS's Well-Architected Serverless Applications Lens is explicit that provisioned concurrency is billed whether it's used or not. On-prem/air-gapped deployment constraints rule serverless out immediately: there's no managed function runtime to call into. |

Serverless and event-driven overlap along different axes rather than
compete: serverless is about *where code runs*, event-driven is about
*how components communicate*. "Event-driven microservices on serverless
compute" is a coherent, common combination, not a contradiction — see the
next section.

### Stack-category pairings

Light-touch signal only — one line per stack category, not a substitute
for that category's own stack doc (`references/stacks/*.md`), which owns
the real depth and is authored separately. Treat these as a starting bias
to sanity-check against, not a rule.

| Stack category | Commonly pairs with |
|---|---|
| Agentic & MCP Platforms | Hexagonal core (swappable model/tool providers behind ports) + event-driven overlay for async tool orchestration |
| Backend & API Services | Layered as the simple default; hexagonal core once the domain is complex enough to be worth protecting from transport/DB churn |
| Data & Analytics Platforms | Event-driven for ingestion pipelines, with a CQRS/event-sourcing overlay where transformation audit trail has real value |
| Business Applications | Modular monolith by default; promote a subdomain to its own service only once a real deploy-cadence or team-boundary problem shows up |
| Integration & Event-Driven Systems | Event-driven as the primary pattern, serverless overlay for individual event handlers |

## Composing patterns across three axes

Real systems answer three mostly-independent questions, not one:

1. **Structural pattern** — how is the codebase decomposed? Layered,
   hexagonal, microservices, modular monolith.
2. **Communication style** — how do components talk, and how does state
   change propagate? Event-driven, CQRS/event sourcing. This is an
   *overlay*: it applies to a subdomain within whichever structural
   pattern was chosen, not to the whole system uniformly.
3. **Runtime/deployment target** — where does code actually execute?
   Serverless functions vs. long-running containers/VMs vs. on-prem.

Named combinations that show up repeatedly in practice:

- **Modular monolith, with event-driven overlay for ingestion** — the
  core domain stays one deployable; the ingestion subdomain publishes and
  consumes events so it can be decoupled and scaled independently of the
  rest without splitting the whole system into services.
- **Event-driven microservices on serverless compute** — each service
  reacts to events and runs as a function rather than a long-running
  process; common for integration-heavy systems with spiky, event-
  triggered load and no on-prem constraint.
- **Hexagonal core with a CQRS read model** — the write-side domain logic
  sits behind ports/adapters; a separate, denormalized read model is fed
  by domain events for the reporting or query-heavy side of the system.
- **Layered monolith, on-prem/VM deployment** — the default when an
  on-prem or air-gapped constraint rules out serverless outright and the
  team isn't yet paying for module-boundary discipline.

A recommendation that names a bare pattern with no overlay is a valid
answer too (plenty of small CRUD apps really are just "layered
monolith") — the point is that the framework should *consider* overlays
explicitly rather than never surfacing them.

## The decision framework

### Signal table

| Signal | What it biases toward |
|---|---|
| Domain boundaries still being discovered | Modular monolith first — split later once boundaries are proven, not guessed (Fowler's MonolithFirst) |
| Domain complexity is high (not team size) | Hexagonal for the core that needs protecting from infrastructure churn |
| Multiple teams need independent release cadence *and* boundaries are known | Microservices for the stable boundaries; the rest can stay modular monolith |
| Subdomain is naturally asynchronous / decoupled / fan-out | Event-driven overlay for that subdomain specifically |
| Genuine read/write asymmetry or hard audit-trail requirement | CQRS/event sourcing overlay for that slice — only that slice |
| Spiky, unpredictable, or event-triggered load | Serverless for that workload, unless ruled out by the deployment-constraint signal below |
| On-prem or air-gapped deployment constraint | Rules out serverless outright; biases the affected part toward layered or modular monolith. This is a real, qualitative signal — no single canonical source pins it down the way the others are cited below, but it's the single cleanest example of a deployment constraint overriding every other signal in this table |
| Compliance regime present | See [Compliance signals](#compliance-signals) below |

### Decision sequence

Work through these in order. Each step can add an overlay or rule
something out; it doesn't replace the steps before it.

1. **Deployment constraint check.** Is any part of the system constrained
   to on-prem or air-gapped infrastructure? If yes, rule out serverless
   for that part immediately and default it to layered or modular
   monolith.
2. **Boundary-maturity check.** Are domain boundaries actually known, or
   still being discovered? If still discovering, start modular monolith
   regardless of the eventual scale target — split later, once boundaries
   are proven in production, not guessed on a whiteboard.
3. **Domain-complexity check.** Is the domain complex enough that
   protecting business logic from infrastructure churn is worth the
   overhead? If yes, apply hexagonal to that core — whatever the outer
   structural choice ends up being.
4. **Org-scale check.** Do multiple teams need independently deployable,
   independently releasable units, *and* are the relevant domain
   boundaries now known (not just suspected)? If yes, microservices is
   justified for those specific boundaries; leave the rest modular
   monolith.
5. **Communication-style check.** Are there subdomains with genuinely
   asynchronous, decoupled, or fan-out communication needs — ingestion,
   notifications, cross-system integration? Apply an event-driven overlay
   to those subdomains specifically, not to the whole system.
6. **CQRS/event-sourcing check.** Within an event-driven subdomain, is
   there a real read/write asymmetry or a hard audit-trail requirement?
   Only if yes, add CQRS/event sourcing for that slice. Fowler's own
   caution applies here: most cases that reach for this don't actually
   need it — treat this as the step most likely to be over-applied.
7. **Runtime check.** For workloads that are event-triggered, spiky, or
   short-duration, and not already ruled out in step 1: run them on
   serverless compute regardless of the structural pattern chosen
   elsewhere.
8. **Compliance overlay.** Apply the [compliance signals](#compliance-signals)
   table to any regulated subdomain identified along the way.

The output is a **primary structural pattern plus a named list of
overlays and which subdomain each applies to** — e.g. "Modular monolith
(core), hexagonal (payments subdomain), event-driven overlay (ingestion),
serverless (webhook handlers)." That composed string is what gets
recorded in the project's baseline record and in the ADR that documents
the decision (see [next section](#recording-the-decision-architecture-decision-records)).

### Compliance signals

Explicitly **not** regulatory guidance — full HIPAA/PCI-DSS/SOC2 control
detail is out of scope for this skill. This is a bias signal that feeds
the framework above, nothing more; treat any compliance-relevant project
as needing its own real compliance review beyond what's here.

| Signal | Bias |
|---|---|
| PCI-relevant (cardholder data present) | Isolate the cardholder-data subdomain behind its own boundary — a hexagonal port or a separate service — rather than threading card data through the general domain model. Shrinks PCI scope to the isolated boundary instead of the whole system. |
| HIPAA-relevant (PHI present) | Bias toward event sourcing / a durable audit trail for the affected subdomain. "Who changed what, and when" is a control requirement here, not just a nice-to-have. |
| SOC2 / general audit requirements | Favor patterns with an audit trail by construction (event sourcing) over one bolted on after the fact, for the subdomains actually in scope of the audit. |
| GDPR right-to-erasure | A named, real tension with event sourcing — Azure's own guidance flags it. Plan for it explicitly (crypto-shredding, tombstone events) *before* choosing event sourcing for a personal-data-bearing subdomain, not after someone files an erasure request. |

### What a well-formed answer looks like

Four worked examples, to calibrate the shape the baseline record's
"chosen template + reasoning" field should take:

- *Small team, growing SaaS product, ingestion pipeline needs decoupling
  from the core app* → **"Modular monolith, with event-driven overlay for
  ingestion."**
- *Integration-heavy system, multiple independent teams, spiky event-
  triggered load, cloud-only deployment* → **"Event-driven microservices
  on serverless compute."**
- *Complex domain, real read/write asymmetry, reporting-heavy business
  application* → **"Hexagonal core with a CQRS read model."**
- *Regulated/air-gapped constraint, small team, CRUD-shaped domain* →
  **"Layered monolith, on-prem deployment."**

A bare single-pattern answer ("layered monolith," no overlay) is a
legitimate output too — not every project needs a composed answer. What
the framework should never do is silently default to a single pattern
without having walked the sequence above.

## Recording the decision: Architecture Decision Records

Write an ADR whenever a structural-pattern, technology, or approach
decision has real trade-offs and would look mysterious to someone reading
the repo in a year without the reasoning attached. The output of the
decision framework above — the composed pattern-plus-overlays answer — is
exactly this kind of decision and should get its own ADR during
inception, not just a line in the baseline record.

**Format:** Nygard's 2011 shape — Title, Status, Context, Decision,
Consequences — the reference approach Fowler endorses as the durable
default: short, in Markdown, sequentially numbered, and **immutable once
accepted**. If the decision changes later, don't edit the original —
write a new ADR and mark the old one's Status as superseded. This matters
specifically for `project-incubation` because it re-audits repos over
their lifecycle, and template choices get revisited; an editable ADR
history is a history that lies about what was actually decided when.

**Status field lifecycle:** `proposed` → `accepted` → optionally
`superseded by ADR-000N`. A real example of this in production use: an
ADR recording an initial build-approach decision, later marked
`superseded by ADR-0007` with a short block-quote note pointing to the
replacement — the original Context, Options considered, and Decision
sections were left untouched as the historical record, rather than
rewritten.

**Options considered:** score the real alternatives against criteria
that actually matter for *this* decision — not a generic checklist
copy-pasted between ADRs. For a structural/architectural fork, a scored
table (option × named criteria × verdict) makes the trade-off legible.
For a narrower stack or tooling choice, a flat table (concern → choice →
notes, including what was rejected and why) is often clearer — both
shapes are legitimate; pick the one that fits the decision.

Ship this as a literal, fillable file: copy
[`assets/adr-template.md`](../assets/adr-template.md) to
`docs/adr/0001-<short-slug>.md` in the new repo and fill it in during
inception for the architecture-template decision, then reuse it for every
subsequent significant decision. It's a template, not documentation about
a template — the point is that someone copies the file and fills in
blanks, not that they read about ADRs and write one from scratch each
time.

## Cross-cutting: database selection

| Category | Fit | Cost if misapplied |
|---|---|---|
| **SQL** (Postgres, MySQL, …) | Default choice absent a specific reason otherwise — relational integrity, joins, and transactions matter | None specific — this is the low-regret default |
| **NoSQL** (document / key-value / wide-column) | Schema is genuinely variable, or the access pattern is key-based lookups at a write scale a single SQL primary can't sustain | Losing transactional/relational guarantees you didn't actually need to give up |
| **NewSQL** | Need SQL semantics (transactions, joins) *at* horizontal-scale write volumes that outgrow a single SQL primary — a narrow band, not a default | Operational and cost overhead for a scale problem you don't actually have yet |

**Polyglot persistence** (running more than one of the above) is
justified only when a subdomain's access pattern genuinely doesn't fit
the primary store — search needs a search index, a session store needs a
fast KV cache. The real cost of polyglot persistence is **governance
overhead**, not the technology itself: backup/restore procedures, on-call
expertise, and migration tooling all multiply per store added. Default to
one primary store; add a second only when a specific subdomain
demonstrably doesn't fit it, not preemptively.

## Cross-cutting: API design and versioning

- Design resource-oriented — nouns plus standard methods (Get / List /
  Create / Update / Delete) per Google's AIP-based API design guide —
  rather than RPC-style verbs bolted onto URLs.
- Treat **backward compatibility as the primary goal**; versioning is the
  fallback for when a breaking change is genuinely unavoidable, not a
  routine habit.
- Prefer additive, non-breaking field changes over bumping a version.
  Version at the resource/API-surface level, not per field.
- Pick one versioning strategy up front (URI path, header, or media type)
  and apply it consistently across the whole surface — mixing strategies
  across endpoints is a specific, avoidable footgun, not a flexibility
  win.

## Cross-cutting: network topology

- **API gateway (north-south traffic)** is justified past the first
  externally-facing service: one entry point for auth, rate limiting,
  routing, and TLS termination.
- **Service mesh (east-west traffic: mTLS, retries, tracing between
  internal services)** is justified only past a service-count and
  operational-maturity threshold that most early projects never cross.
  Adopting a mesh before there's enough internal service-to-service
  traffic to need centralized mTLS/retry/observability is a named
  anti-pattern — it pays the sidecar-proxy and control-plane operational
  complexity for a problem the project doesn't have yet.
- Default posture: start with a gateway only. Add a mesh when internal
  service count and traffic volume genuinely need it, not preemptively
  alongside the first two or three services.

## Cross-cutting: security-by-design touchpoints

**Auth pattern selection** — heuristic, not absolute:

| Context | Pattern |
|---|---|
| User-facing | OAuth2/OIDC |
| Service-to-service | mTLS or a client-credentials grant |
| Simple partner/API integration | API keys — never as the sole factor protecting anything sensitive |

**Secrets management** — OWASP's Secrets Management Cheat Sheet is the
durable canonical source; the lifecycle it lays out is the checklist:

- Secure, automated generation — not hand-typed, not reused across
  environments.
- Centralized storage with least-privilege access — not environment
  variables committed to source, not scattered across config files.
- Rotation on a defined schedule.
- A real revocation/expiration path, not just a rotation habit.
- Mandatory audit logging of secret access.

## Cross-cutting: storage tier selection

| Tier | When it fits |
|---|---|
| **Object** | Default posture — use this unless one of the two exceptions below applies |
| **Block** | Low-latency random I/O is required — databases, boot volumes |
| **File** | Genuine concurrent multi-writer file semantics are required — a shared filesystem across multiple compute instances |

Hot/cold tiering complexity is frequently premature: don't build a
tiering policy before there's real access-pattern data showing which data
is actually cold. Object storage's own lifecycle-tiering features cover
the common case once that data exists — building a custom tiering scheme
ahead of evidence is solving a cost problem that may not exist yet.

## Cross-cutting: UX/frontend architecture

Deliberately shallow here: monolith frontend vs. micro-frontends vs. a
backend-for-frontend (BFF) layer is largely orthogonal to the backend
structural pattern chosen above, and gets real depth in the Business
Applications stack doc rather than here. The short version: default to a
single frontend codebase unless multiple independent teams are shipping
genuinely separate UI surfaces on independent release cadences — the same
complexity-not-size trigger that governs the microservices decision
applies here too.

## Sources

- Fowler, "MonolithFirst" — https://www.martinfowler.com/bliki/MonolithFirst.html
  — start monolith, split only once boundaries are known and complexity
  demands it. Retrieved 2026-08-19.
- Fowler, "MicroservicePremium" — https://martinfowler.com/bliki/MicroservicePremium.html
  — names the fixed operational cost paid before microservices' benefits
  show up; complexity, not size, is the trigger. Retrieved 2026-08-19.
- Fowler, "CQRS" — https://martinfowler.com/bliki/CQRS.html — explicit
  caution that CQRS suits only complex domains or read/write-disparate
  high-performance systems; "in the majority of cases... this has not
  been a good idea." Retrieved 2026-08-19.
- Fowler, "ArchitectureDecisionRecord" — https://martinfowler.com/bliki/ArchitectureDecisionRecord.html
  — endorses Nygard's ADR format as the reference approach: short,
  Markdown, sequentially numbered, superseded rather than edited.
  Retrieved 2026-08-19.
- Nygard, Michael. "Documenting Architecture Decisions" (2011) — origin
  of the Title/Status/Context/Decision/Consequences format, reached via
  Fowler's direct endorsement above. Reference copy:
  https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md
- Azure Architecture Center, "Architecture styles" —
  https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/
  — source for the comparison-table *shape* (style × dependency
  management × domain type) reused above; covers N-tier, Web-Queue-
  Worker, Microservices, Event-driven, Big Data, and Big Compute
  specifically — it does not itself name hexagonal, modular monolith, or
  CQRS as styles. Page dated 2025-09-25, content updated 2026-08-18.
  Retrieved 2026-08-19.
- AWS Prescriptive Guidance, "Hexagonal architecture" —
  https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html
  — intent, applicability, and an explicit "issues and considerations"
  list (complexity, maintenance overhead, latency). Retrieved 2026-08-19.
- Azure Architecture Center, "Event Sourcing pattern" —
  https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing
  — exhaustive when-to-use / when-not-to-use lists; names eventual
  consistency, event versioning, idempotency, and GDPR right-to-erasure
  tension explicitly; pairs the pattern with CQRS. Updated 2026-03-27,
  refreshed 2026-08-15. Retrieved 2026-08-19.
- Shopify Engineering, "Deconstructing the Monolith" —
  https://shopify.engineering/deconstructing-monolith-designing-software-maximizes-developer-productivity
  — real production case for modular monolith as a deliberate choice at
  meaningful scale: "We wanted a solution that increased modularity
  without increasing the number of deployment units, allowing us to get
  the advantages of both monoliths and microservices without so many of
  the downsides." Retrieved 2026-08-19.
- AWS Well-Architected Framework, Serverless Applications Lens,
  "Tradeoffs" — https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/tradeoffs.html
  — covers the provisioned-concurrency cost trade-off directly (billed
  whether used or not); points to the general Well-Architected whitepaper
  for the rest. Retrieved 2026-08-19.
- Google Cloud, "API Design Guide" (AIP-based) —
  https://docs.cloud.google.com/apis/design — resource-oriented design,
  standard methods, versioning per AIP-180/AIP-185. Retrieved 2026-08-19.
- OWASP, "Secrets Management Cheat Sheet" —
  https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
  — full lifecycle guidance: generation, centralized least-privilege
  storage, rotation, revocation/expiration, mandatory audit logging.
  Canonical durable source for the secrets-management touchpoint.
  Retrieved 2026-08-19.
- Kong, "The difference between API gateways and service mesh" —
  https://konghq.com/blog/enterprise/the-difference-between-api-gateways-and-service-mesh
  — vendor-authored (Kong sells both product categories), but its
  north-south (gateway) / east-west (mesh) framing was independently
  corroborated by other write-ups (Gravitee, Kasun Indrasiri, DigitalAPI)
  surfaced in the same research pass. Retrieved 2026-08-19.
- Richards, Mark & Ford, Neal. *Fundamentals of Software Architecture: An
  Engineering Approach* (O'Reilly, 2020) —
  https://www.oreilly.com/library/view/fundamentals-of-software/9781492043447/
  — source of "architecture characteristics" and explicit trade-off
  analysis as the framing device for pattern selection used throughout
  this doc.
- Ford, Neal; Richards, Mark; Sadalage, Pramod; Dehghani, Zhamak.
  *Software Architecture: The Hard Parts* (O'Reilly, 2021), ISBN
  978-1-492-08689-5 — companion volume extending trade-off analysis to
  distributed-architecture specifics (service granularity, data
  ownership). Cited by ISBN.
- Local precedent (read directly, not a web source): MCPg's
  `docs/adr/0001-build-approach.md` and `docs/adr/0002-technology-stack.md`
  — real in-repo examples of the ADR shape recommended above (scored
  Options-considered table, flat decision table, Status-field
  supersession). Read 2026-08-19.
