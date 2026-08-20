# Business Applications — Architecture & Stack

A "business application," for this doc, is a multi-tenant or single-tenant
SaaS/enterprise CRUD system: a persistent database, a UI that end-users and
business operators interact with directly, and typically both a backend and
a frontend owned under one product — a B2B SaaS product, an internal
back-office/admin tool, an ops dashboard, a CRM-style app. What distinguishes
it from a [Backend & API Services](backend-api-services.md) project is
owning the UI layer, not just exposing an API for other systems to consume.

## Table of contents

- [Default architecture pattern: modular monolith](#default-architecture-pattern-modular-monolith)
- [Multi-tenancy architecture](#multi-tenancy-architecture)
- [Frontend architecture](#frontend-architecture)
- [Auth and permission-model architecture: RBAC to ABAC](#auth-and-permission-model-architecture-rbac-to-abac)
- [Background job and async-task architecture](#background-job-and-async-task-architecture)
- [Audit logging as an architectural concern](#audit-logging-as-an-architectural-concern)
- [Admin-panel and back-office tooling: build vs. buy](#admin-panel-and-back-office-tooling-build-vs-buy)
- [Billing, subscription, and metering architecture](#billing-subscription-and-metering-architecture)
  - [Usage-based billing: event, aggregation, and sync](#usage-based-billing-event-aggregation-and-sync)
  - [Plan-gating and entitlement architecture](#plan-gating-and-entitlement-architecture)
  - [Build vs. buy for the billing engine](#build-vs-buy-for-the-billing-engine)
  - [Idempotency and reconciliation](#idempotency-and-reconciliation)
  - [Multi-tenancy interaction](#multi-tenancy-interaction)
- [Out of scope](#out-of-scope)
- [Sources](#sources)

## Default architecture pattern: modular monolith

Modular monolith is the honest default for this category at typical
starting scale — not a hedge, a confirmed position. The reason is specific
to this category, not generic monolith-first advice: multi-tenancy, RBAC,
billing, notifications, and reporting are naturally separable modules from
day one, which is exactly what makes "modular" tractable inside a single
deployable rather than an aspiration that erodes immediately.

Start modular monolith; extract a service only when a **concrete, named
forcing function** appears — independent scaling need for one module (report
generation is CPU-heavy and needs to scale independently of the request
path), a compliance boundary requiring physical data or process isolation,
or a second team that needs to own and deploy a module independently. "We
might need to scale later" is not a forcing function, and neither is a
headcount number: the coordination overhead of microservices — cross-service
contracts, distributed debugging, N deployment pipelines — only pays off
once there are enough independent teams that the monolith's shared-codebase
coordination cost exceeds it, which is a qualitative threshold, not a
number of engineers. Treat any specific numeric team-size threshold you
encounter elsewhere with suspicion — that framing shows up mostly in
SEO-aggregator content with no identifiable primary source behind the
numbers.

This specializes [architecture-templates.md](../architecture-templates.md)'s
general framework: business apps almost never need event-driven or CQRS as
the *primary* architecture — those apply as targeted techniques (CQRS for a
reporting module with heavy read/write asymmetry, event-driven for
cross-module notifications) layered inside the modular monolith, not as the
top-level shape. Microservices become the default only once the
team-size/compliance forcing functions above are met. This is a genuine
divergence from a backend-services default, where independent deployability
can matter sooner.

## Multi-tenancy architecture

**Postgres native Row-Level Security is the default enforcement mechanism
for shared-schema multi-tenancy in this category** — not one option among
several. Move off it only for the compliance- or scale-driven reasons named
below.

Three real patterns exist on a spectrum from shared-everything to
shared-nothing. RLS is not a fourth pattern; it's the concrete enforcement
mechanism layered onto the first one.

1. **Shared schema + row-level isolation** — a `tenant_id` column on every
   tenant-scoped table, filtered on every query. Lowest cost, single
   migration path, fastest tenant onboarding (one row insert). The real risk
   is a missed `WHERE tenant_id = ?` — a data breach, not a bug — and
   "noisy neighbor" tenants degrading others sharing the same tables and
   indexes. **Enforce isolation in the database, not just the app layer**:

   ```sql
   CREATE POLICY tenant_isolation ON invoices
     USING (tenant_id = current_setting('app.tenant_id')::uuid)
     WITH CHECK (tenant_id = current_setting('app.tenant_id')::uuid);
   ```

   Two mechanics make this actually work, and both are easy to get wrong
   silently: the application must connect as a **non-superuser role** —
   Postgres superusers bypass RLS entirely, so a policy with a superuser
   connection string enforces nothing — and every write path needs
   `WITH CHECK` in addition to `USING`. `USING` gates which rows a query can
   see (reads); a policy that only defines `USING` protects reads but leaves
   writes unguarded. This is the correct default for most B2B SaaS at
   typical starting scale — hundreds to low-thousands of tenants on shared
   infrastructure.

2. **Schema-per-tenant** — one Postgres database, one schema per tenant, the
   app routes queries by switching `search_path`/schema based on tenant
   context. Stronger isolation than shared-schema (a query can't cross
   schemas by accident), still one physical database to operate and back up.
   Cost: migrations run per-schema (N schemas means N migration runs), and
   connection/schema-routing logic adds real operational complexity once
   tenant count reaches the high hundreds to low thousands. `django-tenants`
   (Django/Postgres) is the concrete tool for this pattern — see
   [Preferred Libraries: Business Applications](../preferred-libraries/business-applications.md).

3. **Database-per-tenant** — full physical isolation: clean per-tenant
   backup/restore/export, the easiest story for regulatory data-residency
   requirements (a specific tenant's data can live in a specific
   region/instance), trivial tenant offboarding (drop the database). Cost
   scales roughly linearly with tenant count — connection pooling across N
   databases, N-way migration orchestration, and provisioning latency all
   become real engineering problems past dozens to low-hundreds of tenants.
   Reserve this for enterprise tenants with contractual or regulatory
   isolation requirements (healthcare, finance, government), or for tenant
   counts low enough — tens, not thousands — that per-tenant infrastructure
   cost is a non-issue.

**Decision rule**: default to shared-schema + Postgres RLS. Move to
schema-per-tenant only when a compliance/audit requirement demands
schema-level separation without full database-per-tenant cost. Move to
database-per-tenant only when a named tenant contract or regulation — not a
hypothetical — requires it, or tenant count is small enough that per-tenant
cost is a non-issue. This is the sub-topic where guidance differs most by
scale in this category: the right answer at 50 tenants and 5,000 tenants is
genuinely different, and the pattern above should move with that number, not
stay fixed at whichever pattern was chosen at launch.

## Frontend architecture

The category-specific nuance, versus a general frontend-architecture
reference: business apps are almost always **fully authenticated, behind a
login** — which changes the calculus that drives public-facing SSR/SEO
recommendations elsewhere.

For a fully authenticated, non-SEO-relevant surface — the overwhelming
majority of admin panels, internal tools, back-office CRUD — a
client-rendered SPA (React + Vite, or React Router in framework mode
without server rendering) remains a legitimate, simpler choice: no
server-rendering infrastructure, no hydration-mismatch class of bugs,
straightforward client-side auth/routing.

React Server Components (Next.js App Router) earn their complexity in this
category specifically in two shapes: dashboards with first-load-heavy data,
where the server fetches with the session cookie already available and
avoids client fetch waterfalls after a blank shell; or products where
marketing/signup pages share a codebase with the authenticated app and
genuinely need SEO — a common shape for SaaS (marketing site + app in one
Next.js repo). State the trade-off honestly: RSC/App Router adds real
operational complexity — hydration model, server/client component boundary
discipline, caching semantics that have shifted across Next.js versions —
that a pure back-office tool with no public/SEO surface does not need to
take on.

htmx / server-rendered-HTML-over-the-wire is a legitimate lower-complexity
alternative specifically for CRUD-heavy internal tools (less client JS,
simpler mental model). It's worth naming as an option; specific "% JS
reduction" figures circulating for htmx (commonly 40-60%) don't trace to an
identifiable primary benchmark and shouldn't be cited as fact.

**Decision rule**: default to a client-rendered SPA for internal/back-office
tools with no public or SEO surface. Default to Next.js App Router (RSC)
when the same codebase serves a public/marketing surface alongside the
authenticated app, or when first-load dashboard performance with heavy
server-side data is a named requirement.

## Auth and permission-model architecture: RBAC to ABAC

RBAC (role → permissions — "admin," "editor," "viewer") is the correct
starting default: cheap to implement, easy to reason about, and it matches
how most business apps actually onboard users — assign a role at invite
time.

ABAC (attributes of user, resource, and environment — "a manager can approve
requests from their own department, only during business hours") becomes
necessary when permission logic depends on data a role alone can't capture:
org hierarchy, resource ownership, time/location constraints, per-record
exceptions. This is a real, common outgrowth in B2B SaaS the moment a
customer asks "can user X see only their team's records" — a request RBAC
alone cannot express cleanly.

**Decision rule**: start RBAC. Introduce ABAC/policy-based rules
incrementally, scoped to the specific resource types that actually need
attribute-based logic (ownership, department scoping), rather than replacing
RBAC wholesale. The common real-world pattern is RBAC for coarse role gating
plus a small number of attribute-based rules layered on top — via a policy
library such as Casbin (see
[Preferred Libraries: Business Applications](../preferred-libraries/business-applications.md))
— not a full ABAC rewrite.

One multi-tenant-specific wrinkle this category must get right from day one:
role scoping needs a tenant dimension — "admin *within tenant X*," not
"admin" globally. Treating roles as global when they're actually per-tenant
is a common early-stage bug, and it's expensive to retrofit once real data
depends on the (wrong) global assumption.

## Background job and async-task architecture

Business apps have a small, recognizable set of async needs: report/export
generation, transactional and bulk email, scheduled/recurring jobs (billing
runs, reminders, digest emails), and webhook delivery with retry.

The architectural point is not just tool choice: separate the request path
from anything that (a) takes more than 1-2 seconds, (b) needs
retry-on-failure semantics, or (c) runs on a schedule. Push these to a queue
plus worker process — never inline in the request/response cycle.

The category-specific decision is queue-backed library (self-run workers —
BullMQ, Celery, Sidekiq) versus managed durable-execution platform (Inngest,
Trigger.dev); see
[Preferred Libraries: Business Applications](../preferred-libraries/business-applications.md)
for the concrete trade-off. The architectural point to carry here is that a
**durable-execution model** — steps individually retriable, resumable
across deploys — is increasingly the right default for business-workflow
jobs specifically, because business workflows (multi-step approval flows,
onboarding sequences) benefit from step-level durability more than raw
throughput.

## Audit logging as an architectural concern

Business apps — especially B2B SaaS selling into regulated or enterprise
buyers — routinely need "who did what, when" as a first-class, queryable
record, not just application logs scraped after the fact.

Two real implementation shapes exist. A **dedicated append-only `audit_log`
table or service** that every mutating action writes to explicitly is the
simplest: it works with any architecture and is easy to reason about and
query. **Full event sourcing**, where the event log *is* the source of
truth and current state is derived from it, gives a strong audit guarantee
"for free" but is a much bigger architectural commitment — it changes how
every write path and every read model works.

**Decision rule**: default to the dedicated audit-log-table approach inside
the modular-monolith default for this category — it delivers the
compliance/audit requirement without forcing an event-sourcing rewrite of
the whole data model. Reserve full event sourcing for cases where temporal
queries ("what did this record look like on date X") or event replay are
themselves product requirements, not just an audit nice-to-have.

A baseline audit log needs, at minimum: actor, tenant, action, resource,
before/after (or a diff), timestamp, and a request/correlation ID. Missing
any of these turns the log into a record that can't actually answer "who
did what, when" for a specific tenant's specific record.

## Admin-panel and back-office tooling: build vs. buy

Batteries-included frameworks — Django, Rails (with ActiveAdmin), Laravel
(with Filament) — ship a first-party or near-first-party admin generator
that reads the data model and produces working CRUD screens with auth
already wired. For these stacks, using the built-in/first-party admin
generator is close to a free default and should be the starting
recommendation; building a custom admin panel from scratch duplicates work
the framework already does well.

For JS/TS full-stack stacks without a built-in admin (Next.js, React
Router), the category needs a named third-party layer: a headless framework
(Refine) that generates CRUD UI on top of an existing API/data layer with
full code ownership, or an auto-generated admin UI bound directly to the
DB/ORM models (AdminJS). React Admin is the older, still-maintained option
for building a fully custom admin SPA against a REST/GraphQL API rather than
generating one.

**Decision rule**: if the backend framework has a mature first-party admin
(Django Admin, Filament, ActiveAdmin) and the internal tool's needs stay
close to "CRUD over the data model," use it. Reach for Refine, AdminJS, or
React Admin only when the admin needs custom workflows, or the backend is
JS/TS-only with no first-party option. Reach for a no-code/low-code tool
(Retool-style) only for internal tools with no need to ship as part of the
product codebase — that's a different category of decision, see
[Out of scope](#out-of-scope).

## Billing, subscription, and metering architecture

Near-universal in this category — any B2B SaaS with paid plans needs this —
and architecturally distinct from "add a Stripe SDK call." Four real
sub-concerns, each with its own decision rule.

### Usage-based billing: event, aggregation, and sync

The naive approach — call the billing provider's API synchronously at the
point of usage — couples the request path's latency and availability to a
third-party vendor's API, and loses events on any transient failure. The
correct shape has three steps:

1. **Capture** a metering event at the point of usage, written durably and
   fast — an append to a local table or stream, not a call that can fail
   the user-facing action — with a client-generated idempotency/dedup key.
2. **Aggregate** events locally (in-process counters, Redis, or a stream)
   rather than sending one API call per usage event, both to survive vendor
   rate limits and because most billing providers charge or throttle per
   ingest call, not per unit.
3. **Flush** aggregated usage to the billing provider on a cadence
   (per-minute or per-hour, not per-event) via an idempotent sync job that
   can safely retry.

This is the same "async, not inline" instinct as the
[background-job architecture](#background-job-and-async-task-architecture)
above, applied to metering specifically: metering sync is a background job,
not a request-path concern.

### Plan-gating and entitlement architecture

The naive approach — query the billing provider's API on every request to
check "is this tenant on a plan that allows X" — doesn't scale: it adds an
external network round-trip, and a hard external dependency, to every gated
request, and most billing providers rate-limit or are simply too slow for
per-request checks.

The correct pattern: entitlements are a **denormalized snapshot stored in
the product's own database** (or a fast cache in front of it), tenant-scoped,
written by the billing webhook consumer whenever the provider reports a
plan/subscription change, and read locally on every request with no external
call in the hot path. The billing provider is never in the request path.

Name the staleness bound this introduces honestly: the snapshot is only as
fresh as the last successfully processed webhook, so plan a periodic
reconciliation sweep — a scheduled job that re-pulls current subscription
state from the provider's API and corrects drift — as the mitigation for a
missed or failed webhook silently leaving a tenant on a stale plan. A
subtler ordering bug worth naming explicitly: the entitlement check often
needs to run *before* tenant context is fully resolved in request
middleware — get the tenant-resolution-then-entitlement-check ordering
right, not the reverse.

### Build vs. buy for the billing engine

Three real tiers, not two:

- **Hand-rolled** — viable only for simple flat-rate/seat-based plans with
  no usage metering. Do not hand-roll usage aggregation/rating logic; it is
  a correctness-critical, easy-to-get-wrong domain (proration, mid-cycle
  plan changes, currency/tax) that mature tools have already solved.
- **Managed vendor** — Stripe's usage-based billing path now routes through
  **Metronome** for any new integration (Stripe acquired Metronome, deal
  completed January 14, 2026). Stripe's own docs state the legacy Billing
  Meters API is appropriate only for teams already using it; new
  integrations — including adding usage pricing to an existing flat-rate
  Stripe Billing subscription — should use Metronome instead. "Stripe
  Billing" as a recommendation now means Stripe's billing rails plus a
  Metronome-run metering/rating engine, not the older self-service Meters
  API.
- **Dedicated open-source billing/metering platform** — self-hosted control
  over billing/rating logic, no per-seat/per-event vendor metering fee, at
  the cost of operating a stateful, correctness-critical service yourself.
  See
  [Preferred Libraries: Business Applications](../preferred-libraries/business-applications.md)
  for the concrete options and their license/maintenance signals.

**Decision rule**: start with the managed path (Stripe + Metronome) for
flat-rate or simple usage-metered plans, and for teams without a strong
reason to self-host billing. Consider a dedicated open-source platform when
data residency/compliance rules out sending usage or customer billing data
to a US vendor, when billing logic is a genuine product differentiator worth
owning, or when vendor lock-in / per-event metering cost at scale becomes a
named concern. Never hand-roll usage rating or proration logic from scratch.

### Idempotency and reconciliation

This is not a new concept here — it's the same idempotent-consumer
discipline this category already needs elsewhere
([Background job and async-task architecture](#background-job-and-async-task-architecture)),
applied in two directions. See
[Backend & API Services: Idempotency for mutating endpoints](backend-api-services.md#idempotency-for-mutating-endpoints)
for the underlying mechanics (anchored on Stripe's own idempotent-request
API) rather than re-deriving idempotency from scratch here. The
billing-specific instances of that pattern:

- **Outbound** — metering events need a client-generated idempotency key at
  emission time, because a retried HTTP call from the metering-sync job must
  not double-count usage or double-bill.
- **Inbound** — billing-provider webhooks (subscription updated, invoice
  paid, payment failed) must be deduped on the provider's event ID before
  being applied to the local entitlement snapshot, because providers
  explicitly document at-least-once webhook delivery and will redeliver on
  any non-2xx response or timeout.

### Multi-tenancy interaction

Subscription, entitlement, and invoice tables are tenant-scoped data and
belong under the same isolation pattern as the rest of the tenant's data —
Postgres RLS in the shared-schema default, per-schema or per-database in the
stronger-isolation patterns above. There is no special-case exemption for
billing tables.

Two wrinkles are specific to billing, though. First, raw metering events are
comparatively high-write-volume next to the app's normal CRUD path, and are
usually worth keeping in a separate table or store from the OLTP tables the
rest of the app writes to, even within the same database — so a usage spike
from one tenant doesn't degrade query performance on core app tables.
Second, database-per-tenant (the strongest-isolation pattern above) has a
real cost specific to billing: cross-tenant revenue reporting and
reconciliation — MRR rollups, dunning queues, "which invoices are overdue
across all tenants" — becomes genuinely painful once tenant data is split
across N physical databases. Surface this as a concrete downside of that
pattern whenever billing/finance reporting is a named requirement.

## Out of scope

- **No-code/low-code internal-tool builders** (Retool, Appsmith, and
  similar) — this is a build-vs-buy decision for the entire internal tool,
  not a library choice within a codebase, and belongs to tool procurement
  rather than code-owned skill guidance.
- **Full event-sourcing/CQRS as the primary architecture** — covered above
  as a targeted technique layered inside the modular-monolith default (the
  audit-log and reporting sub-cases specifically); the general case is
  [architecture-templates.md](../architecture-templates.md)'s territory,
  not re-derived here.
- **Mobile-app frontend architecture** — this category is web business apps
  (SaaS/back-office); mobile client architecture is a distinct concern with
  its own needs.
- **Detailed database schema/indexing design** — data-layer implementation
  detail, not an architecture-selection signal.

## Sources

- Bytebase, ["Multi-Tenant Database Architecture Patterns Explained"](https://www.bytebase.com/blog/multi-tenant-database-architecture-patterns-explained/) —
  the three multi-tenancy DB patterns and their trade-offs. Retrieved
  2026-08-19.
- The Road to Enterprise, ["Postgres RLS for Multi-Tenant SaaS"](https://theroadtoenterprise.com/blog/postgres-rls-multi-tenant-saas) —
  the concrete RLS pattern (`set_config` + `CREATE POLICY`), including the
  superuser-bypass and USING-vs-WITH-CHECK caveats. Retrieved 2026-08-19.
- OsoHQ, ["RBAC vs ABAC"](https://www.osohq.com/learn/rbac-vs-abac) — RBAC
  vs. ABAC definitions and hybrid-approach framing, from an
  authorization-tooling vendor with direct domain expertise. Retrieved
  2026-08-19.
- Frontegg, ["RBAC vs ABAC"](https://frontegg.com/guides/rbac-vs-abac) —
  corroborating decision criteria (team size, distributed workforce,
  time/location-based rules). Retrieved 2026-08-19.
- microservices.io, ["Event Sourcing pattern"](https://microservices.io/patterns/data/event-sourcing.html)
  and ["Audit Logging pattern"](https://microservices.io/patterns/observability/audit-logging.html) —
  event sourcing as an audit mechanism vs. a simpler dedicated audit-log
  table. Retrieved 2026-08-19.
- GitHub API, `django-tenants/django-tenants` — MIT, 1,881 stars, pushed
  2026-08-10. Retrieved 2026-08-19.
- GitHub API, `refinedev/refine` — MIT, 35,533 stars, pushed 2026-06-05.
  Retrieved 2026-08-19.
- GitHub API, `casbin/casbin` — Apache-2.0, 20,330 stars, pushed 2026-08-13;
  explicitly supports ACL, RBAC, and ABAC models, the concrete tool behind
  the RBAC→ABAC layering decision rule. Retrieved 2026-08-19.
- Stripe docs, [Usage-based billing](https://docs.stripe.com/billing/usage-based)
  and [Recording usage](https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage) —
  current usage-based billing docs lead with Metronome; the legacy Billing
  Meters/meter-events API is stated to be appropriate only for teams already
  using it. Retrieved 2026-08-19.
- Stripe Newsroom, ["Stripe Completes Metronome Acquisition"](https://stripe.com/newsroom/news/stripe-completes-metronome-acquisition) —
  deal completed January 14, 2026. Retrieved 2026-08-19.
- OpenMeter, ["OpenMeter is joining Kong"](https://openmeter.io/blog/openmeter-is-joining-kong) —
  Kong's acquisition of OpenMeter announced September 3, 2025, full Kong
  Konnect integration targeted early 2026; OpenMeter states it "remain[s]
  open source" under Apache-2.0. Retrieved 2026-08-19.
- Orb, ["Orb is joining Adyen, and we're only getting better for our
  customers"](https://www.withorb.com/blog/orb-next-chapter) — Orb's own,
  CEO-authored announcement; the acquisition closed July 1, 2026. Fetched
  directly from Orb's own blog as a follow-up verification pass — the
  original research baseline had this sourced only to a competitor's
  (Lago's) blog post; that competitor-sourced citation is superseded by
  this primary source. Retrieved 2026-08-20.
- GitHub API, `killbill/killbill` — Apache-2.0, 5,694 stars, pushed
  2026-08-19. Retrieved 2026-08-19.
