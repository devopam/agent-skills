# Business Applications — Preferred Libraries

Snapshot date: 2026-08-19 (Adyen/Orb citation follow-up: 2026-08-20). Every
adoption/maintenance signal below was fetched directly from the GitHub API
(`api.github.com/repos/...`) or the PyPI JSON API on that date unless marked
otherwise — not taken from a secondary blog's claimed number. Star counts are
a weak proxy (they measure attention, not usage) and are reported alongside
`pushed_at` (last push date) specifically so staleness is visible, not just
popularity. See [Stack: Business Applications](../stacks/business-applications.md)
for the architectural reasoning these picks support.

GitHub's license detector returned NOASSERTION for Avo, Sidekiq, Inngest,
and Celery's repos — a null result that, left unchecked, reads as "no
license restriction" when the opposite was true for three of the four
(LGPLv3, LGPLv3, and SSPL respectively; Celery turned out to be permissive
BSD-3-Clause, confirmed via PyPI instead). Every table entry below that
carries a "confirmed by reading the license file directly" note exists
because the automated signal was insufficient for that repo — treat
NOASSERTION on any future check the same way: as "go read the file," not as
"unlicensed."

## Table of contents

- [Full-stack / batteries-included frameworks](#full-stack--batteries-included-frameworks)
- [ORM / database migrations](#orm--database-migrations)
- [Auth / identity: build vs. buy](#auth--identity-build-vs-buy)
- [Authorization / policy libraries: RBAC to ABAC](#authorization--policy-libraries-rbac-to-abac)
- [Admin panel / back-office generators](#admin-panel--back-office-generators)
- [Background job / async-task libraries](#background-job--async-task-libraries)
- [Multi-tenancy libraries and tooling](#multi-tenancy-libraries-and-tooling)
- [Billing / subscription / metering platforms](#billing--subscription--metering-platforms)
- [Out of scope](#out-of-scope)
- [Sources](#sources)

## Full-stack / batteries-included frameworks

| Framework | For | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **Next.js** (App Router) | React meta-framework: RSC, SSR, API routes, file-based routing | MIT | 2026-08-19 | 141,863 | Default when the app needs a public/marketing surface alongside the authenticated product, or first-load performance on data-heavy dashboards matters. See the stack doc's [Frontend architecture](../stacks/business-applications.md#frontend-architecture) section — don't reach for this by default for a pure internal tool. |
| **React Router v7** (framework mode) | React meta-framework, SSR-optional | MIT | 2026-08-18 | 56,557 | Lighter-weight alternative to Next.js when SSR is wanted without the App Router's RSC model. Remix merged into React Router v7 in November 2024 — "Remix" as a separate framework is now legacy naming. |
| **Django** | Python batteries-included web framework | BSD-3-Clause | 2026-08-19 | 88,474 | Strongest "batteries-included" option for this category specifically because of Django Admin (see [Admin panel generators](#admin-panel--back-office-generators)) and a first-party, mature ORM/migrations story. Best default when the team is Python-first and wants the least third-party assembly. |
| **Ruby on Rails** | Ruby batteries-included web framework | MIT | 2026-08-19 | 58,695 | First-party ORM (Active Record), migrations, and — via ActiveAdmin — a mature, unambiguously-licensed admin option. Best default for Ruby-first teams; convention-over-configuration reduces architecture bikeshedding for CRUD-shaped business apps. |
| **Laravel** | PHP batteries-included web framework | MIT | 2026-08-18 | 34,874 (framework repo) | Paired with Filament, gives one of the fastest build-vs-buy admin stories of any stack here. PHP/Laravel remains a live, high-volume choice for SMB/mid-market business apps, not a legacy pick. Note: `laravel/laravel` (84,825 stars) is the project skeleton, not the framework — `laravel/framework` is the library actually verified here. |

**Decision rule**: pick the framework matching the team's existing
language/ecosystem first. Django, Rails, and Laravel win on
time-to-admin-panel for CRUD-shaped apps; Next.js and React Router win when
the team is already React-first or needs a unified marketing-plus-app
codebase.

## ORM / database migrations

| Tool | Ecosystem | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **Prisma** | Node/TypeScript | Apache-2.0 | 2026-08-19 | 47,569 | Most-adopted TS-first ORM with first-party migrations (`prisma migrate`); strong fit for Next.js/React Router stacks. Trade-off worth stating: Prisma's query engine has historically had cold-start/binary-size overhead in serverless environments — a real consideration, not disqualifying. |
| **Drizzle ORM** | Node/TypeScript | Apache-2.0 | 2026-08-19 | 35,519 | Newer, SQL-closer alternative to Prisma — no separate query-engine binary, TypeScript-native schema-as-code. Growing fast, comparable push cadence to Prisma, and increasingly the default recommendation for new TS projects wanting less abstraction over SQL and lighter serverless cold-starts. Trade-off: smaller ecosystem of guides/tooling than Prisma's maturity. |
| **drizzle-kit** | Node/TypeScript (migrations/introspection for Drizzle) | Apache-2.0 (same org and license as Drizzle ORM) | — | — | Drizzle's first-party migration/schema-push CLI — required alongside Drizzle ORM above, which doesn't cover migrations on its own. |
| **SQLAlchemy** | Python | MIT | 2026-08-18 | 12,093 | The Python ORM outside Django's own ORM; relevant when the team wants Python but not Django's full-stack opinions — e.g. FastAPI + SQLAlchemy for the API layer paired with a separate frontend. Django's built-in ORM remains the default *inside* Django itself. |
| **Alembic** | Python (migrations for SQLAlchemy) | MIT | 2026-08-14 | 4,329 | SQLAlchemy has no built-in migration tool — Alembic is the de facto companion wherever SQLAlchemy is chosen outside Django. Required pairing, not optional. |
| **Active Record** (Rails built-in) | Ruby | MIT (bundled with Rails) | — | — | First-party, not a separate adoption decision — the default inside Rails. Listed for completeness since ORM choice is often assumed rather than stated. |

## Auth / identity: build vs. buy

The real axis in this category is **managed/hosted vs. self-hosted**, not
vendor-vs-vendor.

**Managed/hosted** trades ongoing infra/security ownership for per-user or
per-org metering cost and vendor dependency:

- **Clerk** — proprietary hosted service; the primary React/Next.js SDK
  (`@clerk/nextjs`) is MIT-licensed even though the backend service is
  closed/hosted. Pricing shape: a free tier up to a fixed retained-user
  count, then metered per monthly-retained-user (MRU — counts only users who
  return, a materially different metric from raw MAU), plus a separate
  per-active-organization charge for B2B multi-tenant features. Best fit:
  developer velocity, consumer or SMB-facing products where enterprise
  compliance (SAML/SCIM) isn't a near-term requirement. Exact dollar figures
  move — described by shape only here; WorkOS's own comparison post has
  current numbers, read as vendor-authored and directional, not neutral.
- **WorkOS (AuthKit)** — proprietary hosted service explicitly positioned for
  B2B SaaS; enterprise-readiness (SSO/SAML, SCIM directory sync, audit logs)
  is bundled rather than paywalled behind an "enterprise tier" — the
  opposite of how Auth0/Clerk historically gated those features. Pricing
  shape: a free tier with a high active-user ceiling, then metered, with
  enterprise-buyer features reachable without a large plan jump. Best fit:
  B2B SaaS selling to companies (not just consumers) where a customer will
  eventually demand SSO.
- **Auth0** — the incumbent managed IDaaS; broad feature surface and
  maturity, but per-MAU pricing has reportedly risen sharply in recent
  repricing (multiple 2026 vendor-comparison sources cite a jump from
  roughly $0.023 to $0.07/MAU — vendor/competitor-sourced, not
  independently verified; a directional signal that Auth0 has gotten
  materially more expensive at scale, not a hard number).

**Self-hosted** (build on top of, not from scratch) means zero per-user
metering and full data control, at the cost of real ops burden:

- **Keycloak** — Apache-2.0, 36,277 stars, pushed 2026-08-19 (very active).
  The enterprise on-prem/self-hosted workhorse (Red Hat-backed). Best fit:
  regulated/enterprise environments needing full control over identity
  infrastructure, willing to run and patch a Java-based IdP themselves.
- **Ory Kratos** — Apache-2.0, 13,833 stars, pushed 2026-07-29. Headless,
  API-first identity server (Go) — no bundled UI, built for teams that want
  to own the entire auth UI/UX and just need identity/session primitives.
- **Better Auth** — MIT, 29,592 stars, pushed 2026-08-19 (very active).
  TypeScript-native, self-hosted-by-default auth *library* — runs inside a
  Node/TS app rather than as a separate identity server. Increasingly the
  default recommendation for TS full-stack apps (Next.js/React Router) that
  want to self-host without standing up Keycloak/Ory as separate
  infrastructure.
- **Auth.js (NextAuth)** — ISC, 28,332 stars, pushed 2026-07-22. The
  longer-established TS-native auth library, with a broad OAuth-provider
  adapter ecosystem. Better Auth has overtaken it in growth momentum and is
  the newer default recommendation as of this snapshot, but Auth.js remains
  a safe, mature choice with a larger existing body of integration guides.

**Decision rule**: if the product sells to businesses (not just consumers)
and enterprise SSO/SCIM is plausible within 12-18 months, default to
WorkOS. If the product is consumer/SMB-facing and developer velocity
matters most, default to Clerk. If data residency, compliance, or
cost-at-scale rules out per-user metering entirely, default to self-hosted —
Better Auth for a TS app willing to own its own auth server code, Keycloak
or Ory when a dedicated identity-server process is acceptable or preferred.

## Authorization / policy libraries: RBAC to ABAC

| Tool | For | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **Casbin** | Policy-based authorization supporting ACL, RBAC, and ABAC models; multi-language (Go core + Node/Python/Java/.NET ports) | Apache-2.0 | 2026-08-13 | 20,330 | The concrete tool behind the stack doc's [RBAC-to-ABAC layering](../stacks/business-applications.md#auth-and-permission-model-architecture-rbac-to-abac) decision rule — model-agnostic, so a project can start RBAC and add attribute-based policies to specific resource types without switching libraries. |

~~Oso~~ (`osohq/oso`) is excluded from this table, not an oversight: the
repo description now reads "Deprecated: See README" and the last push
(2025-02-26) predates this snapshot by 18 months. Oso pivoted to a hosted
product (Oso Cloud); the open-source library is no longer the vendor's
focus. Named here only so it isn't independently rediscovered and
recommended without this context.

## Admin panel / back-office generators

| Tool | Ecosystem | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **Django Admin** | Django (Python) | BSD-3-Clause (bundled) | — | — | First-party, ships with the framework. Auto-generates CRUD screens from models with auth already wired. Default whenever the backend is already Django. |
| **Filament** | Laravel (PHP) | MIT | 2026-08-18 | 31,840 | The Laravel-ecosystem equivalent of Django Admin's build-in-minutes pitch, built on Livewire. Fastest admin story of any stack surveyed here for PHP teams. |
| **ActiveAdmin** | Ruby on Rails | MIT | 2026-08-19 | 9,704 | **The Rails default.** Unambiguously MIT, with a higher star count and more active push cadence than Avo in this snapshot. Use this unless Avo's Pro/Advanced commercial features are specifically worth taking on Avo's more restrictive open-source license for. |
| **Avo** | Ruby on Rails | Open-core: the open-source edition is **LGPLv3**, confirmed by reading `LICENSE.md` directly (GitHub's detector had returned NOASSERTION); Avo Pro and Avo Advanced are separately licensed under a commercial-friendly license (terms at avohq.io) | 2026-08-19 | 1,797 | **The documented alternative to ActiveAdmin**, not a co-equal pick. Avo is more actively promoted in current comparisons and has a newer feature set, but its LGPLv3 open-source tier is a real license difference from ActiveAdmin's plain MIT — copyleft terms more restrictive than any other admin option in this table. Reach for it specifically when its Pro/Advanced commercial tier is worth that trade-off; otherwise default to ActiveAdmin. |
| **Refine** | React (headless, framework-agnostic backend) | MIT | 2026-06-05 | 35,533 | Best fit for JS/TS stacks (Next.js, React Router) with no first-party admin: generates CRUD scaffolding while leaving full code ownership, rather than a black-box auto-admin. Highest star count of the JS-ecosystem options here. Last push predates this snapshot by roughly 2.5 months — worth a freshness check before adopting, though not stale enough on its own to disqualify given the star count and existing plugin ecosystem. |
| **AdminJS** | Node.js (auto-generated from DB/ORM models) | MIT | 2025-07-15 | 8,979 | Closer to Django Admin's "auto-generate from the data model" approach than Refine's scaffold-and-own approach — pick this when the goal is the fastest possible internal CRUD UI and full code ownership isn't a priority. Last push over a year before this snapshot — check for continued activity before adopting, given how fast this ecosystem moves. |
| **React Admin** | React (SPA against REST/GraphQL) | MIT | 2026-08-09 | 26,897 | The older, still-actively-maintained option for hand-building a fully custom admin SPA against an existing API — pick over Refine/AdminJS when the admin needs bespoke UX beyond CRUD scaffolding and the team wants to build the whole thing in React directly. |

**Decision rule**: for Django, Laravel, or Rails backends, use the
first-party/near-first-party option (Django Admin, Filament, ActiveAdmin) —
building a custom admin panel duplicates work the framework already does
well. For a JS/TS backend with no first-party admin, reach for Refine when
full code ownership matters, AdminJS when speed-to-CRUD matters more than
ownership, and React Admin when the admin needs bespoke UX beyond
scaffolding.

## Background job / async-task libraries

| Tool | Ecosystem | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **BullMQ** | Node/TypeScript, Redis-backed | MIT | 2026-08-19 | 9,305 | The standard self-run Node queue library — you own Redis and worker processes. Right default when the team wants full control, no vendor, and is comfortable operating Redis. |
| **Celery** | Python, multi-broker (Redis/RabbitMQ) | BSD-3-Clause (confirmed via PyPI JSON metadata; GitHub's own license detector returns NOASSERTION for the repo) | 2026-08-18 | 28,795 | The long-standing Python default, especially paired with Django/Flask. Mature but heavier operationally — broker, worker, and beat scheduler for cron-style jobs — than newer managed alternatives. |
| **Sidekiq** | Ruby, Redis-backed | LGPL-3.0 for the open-source core, confirmed by reading `LICENSE.txt` directly (GitHub's detector returns NOASSERTION); Sidekiq Pro/Enterprise are separately licensed commercial add-ons | 2026-08-17 | 13,553 | The Rails-ecosystem default. Open-core model means the free tier is a real, unencumbered LGPL library — paid tiers add reliability/observability features, they don't gate core functionality. |
| **Inngest** | Node/TypeScript, managed durable-execution platform | **Server Side Public License (SSPL) v1** for the open-source repo, confirmed by reading `LICENSE.md` directly (GitHub's detector returns NOASSERTION, which undersells how non-permissive this is) — not OSI-approved open source, carries MongoDB-style copyleft-on-service-operators terms, with a provision that the code relicenses to Apache-2.0 three years after each version's release | 2026-08-19 | 5,740 | Represents the durable-execution shift named in the [background-job architecture](../stacks/business-applications.md#background-job-and-async-task-architecture) section: steps are individually retriable and resumable without the team running Redis/workers itself. The license caveat matters concretely: SSPL is fine for using Inngest as a managed cloud service, but a real constraint if the plan is to self-host the Inngest server as part of a competing offering — read the SSPL terms directly before that decision. |
| **Trigger.dev** | Node/TypeScript, managed durable-execution platform (v4 GA August 2025 per vendor sources) | Apache-2.0 — genuinely permissive, unlike Inngest's SSPL | 2026-08-19 | 16,064 | Same architectural category as Inngest — Apache-2.0 makes this the clearer license choice of the two if self-hosting or license simplicity matters; Inngest's SSPL is the more meaningful differentiator here than star count. |

**Decision rule**: default to the ecosystem-native self-run library
(BullMQ/Celery/Sidekiq) when the team already operates Redis and wants no
new vendor dependency. Default to a managed durable-execution platform when
the jobs in question are genuinely multi-step business workflows that
benefit from step-level durability and the team would rather not operate
queue infrastructure — prefer Trigger.dev over Inngest specifically on
license grounds (Apache-2.0 vs. SSPL), not just feature parity.

## Multi-tenancy libraries and tooling

Multi-tenancy is primarily an architecture decision (see the [stack doc](../stacks/business-applications.md#multi-tenancy-architecture)),
but concrete tooling exists for a subset of stacks.

| Tool | Ecosystem | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **django-tenants** | Django/PostgreSQL | MIT | 2026-08-10 | 1,881 | Concrete schema-per-tenant implementation for Django/Postgres — routes queries by Postgres schema per tenant. The go-to library when the stack doc's schema-per-tenant pattern is the right fit and the stack is Django. |
| **acts_as_tenant** | Ruby on Rails, shared-schema (row-level, app-scoped) | MIT | 2025-04-16 | 1,700 | The actively-maintained Rails shared-schema multi-tenancy gem; scopes Active Record queries automatically by a current-tenant context. Prefer this over `apartment` (below) for new Rails projects. |
| **Postgres Row-Level Security** (native DB feature, not a library) | Any stack on Postgres | N/A — Postgres core feature (PostgreSQL License) | — | — | The cross-ecosystem, framework-agnostic enforcement mechanism that is this category's [default multi-tenancy enforcement mechanism](../stacks/business-applications.md#multi-tenancy-architecture). Not tied to any ORM, though Prisma, Drizzle, SQLAlchemy, and Active Record all have documented patterns for setting the session-level tenant context RLS policies read. |

`apartment` (Rails, schema-per-tenant) is flagged, not recommended: higher
star count (2,684) than acts_as_tenant but last pushed 2024-06-12 — over two
years stale as of this snapshot — with no confirmed license (the field is
empty/unset on GitHub, itself a reason for caution). Treat it as a
documented "was popular, now stale" note, not an active recommendation.

**Node/TypeScript gap, stated plainly rather than papered over**: unlike
Django (django-tenants) and Rails (acts_as_tenant), there is no dominant
standalone multi-tenancy library in the Node/TS ecosystem, despite
Next.js/React Router being this doc's most-recommended frameworks. The
consistent pattern across current sources is hand-rolled: an ORM
client-extension or middleware — Prisma Client Extensions, or an
`AsyncLocalStorage`-based request context in Nest apps — that calls
`set_config('app.tenant_id', ...)` per request/transaction, paired with
Postgres RLS policies (above) as the actual enforcement layer. No library
recommendation exists here because none earns one yet.

## Billing / subscription / metering platforms

| Tool | For | License | Last push | Stars | Why |
|---|---|---|---|---|---|
| **Stripe Billing + Metronome** | Managed billing: subscriptions, invoicing, usage-based/metered pricing | Proprietary hosted service (Metronome is now a Stripe product) | — | — | Stripe completed its acquisition of Metronome on **January 14, 2026**, and Stripe's usage-based billing docs now lead with Metronome — the legacy Billing Meters/meter-events API is stated to be appropriate only for teams already billing customers through it; new integrations, including adding usage pricing to an existing flat-rate subscription, are directed to Metronome. Practical effect: recommending "Stripe Billing" for a new usage-metered integration now means routing through Metronome's ingest/rating engine, not the older self-service Meters API. Best fit: teams that want a managed, non-self-hosted billing engine and are already on or open to Stripe for payments. |
| **Lago** | Open-source metering, rating, invoicing, subscription management; self-hosted or Lago Cloud | AGPL-3.0, confirmed by reading `LICENSE` directly on the actual backend repo (`getlago/lago-api`) | 2026-08-19 | 431 (`lago-api`, the actual engine); the umbrella repo `getlago/lago` shows 10,369 stars — star count concentrates on the umbrella/marketing repo, not the code, the same split pattern as Laravel's skeleton-vs-framework repos above | The clearest open-source Stripe-Billing alternative for teams wanting to self-host the billing engine itself. **License caveat, real and load-bearing**: AGPL-3.0 triggers copyleft on network use, not just distribution — modifying Lago and offering the modified version as a network-accessible service obligates releasing those modifications' source. Fine for internal self-hosting as-is; a real constraint if the plan is to fork/modify Lago and resell it as a competing hosted billing product, the same caveat pattern already flagged for Avo's and Sidekiq's LGPLv3 tiers above. Unlike Metronome (now Stripe-owned) and Orb (Adyen-owned as of July 1, 2026 — see [Sources](#sources)), Lago integrates with multiple payment processors (Stripe, Adyen, GoCardless) without being owned by one — a real differentiator if payment-processor neutrality matters. |
| **OpenMeter** | Open-source real-time usage metering and billing, focused on high-volume event ingestion (APIs, AI token usage) | Apache-2.0, confirmed via direct GitHub API fetch and corroborated by OpenMeter's own acquisition announcement, which states the project is "built as a true open-source project under Apache 2.0" and "will remain open source with ongoing development" | 2026-08-19 | 2,213 | Kong acquired OpenMeter (announced 2025-09-03, full Kong Konnect integration targeted early 2026, customer migration mid-2026) — verified directly via OpenMeter's own blog post, not a secondary source. A smaller, still-independently-licensed project being absorbed into an API-infrastructure vendor (Kong) rather than a payments processor, and Kong's own core products share the same Apache-2.0 license — materially lower lock-in risk than Lago's AGPL-3.0 or a closed-source managed vendor. Best fit: metering-heavy, high-event-volume use cases (API/AI usage billing) specifically, per the project's own stated focus, rather than full subscription/invoicing lifecycle management. |
| **Kill Bill** | Open-source subscription billing and payments platform (JVM/Java) | Apache-2.0 | 2026-08-19 | 5,694 | The older, more mature open-source option in this table (predates Lago and OpenMeter by years) with a genuinely permissive license — no AGPL/LGPL caveat. Worth naming as the alternative when a team wants self-hosted billing without Lago's copyleft terms and is comfortable with a JVM-based stack. Smaller community/momentum than Lago by star count and less focused on modern usage-metering/AI-token use cases than OpenMeter, but a legitimate, actively-maintained third option, not a stale relic. |

**Decision rule**: default to Stripe Billing/Metronome for teams already on
Stripe or without a specific reason to self-host — it's the managed,
lowest-operational-burden path, and it is now the vendor's own recommended
integration point for usage-based pricing. Reach for a self-hosted
open-source platform (Lago, OpenMeter, or Kill Bill) when data
residency/compliance rules out sending usage or customer billing data to a
US-based managed vendor, when billing/rating logic is a genuine product
differentiator worth owning, or when payment-processor neutrality
specifically matters (Lago's pitch, given Metronome's and Orb's 2026
acquisitions by Stripe and Adyen respectively). Among the self-hosted
options: Lago for the broadest current feature set (metering, rating,
invoicing, entitlements, wallets) if the AGPL-3.0 network-copyleft term is
acceptable; OpenMeter specifically for high-volume real-time metering
(API/AI usage) under a more permissive Apache-2.0 license; Kill Bill for
teams wanting a longer-established, JVM-based, unambiguously
permissive-licensed option. Never hand-roll usage rating, proration, or
invoicing logic from scratch — see the stack doc's
[build-vs-buy section](../stacks/business-applications.md#build-vs-buy-for-the-billing-engine)
for why.

## Out of scope

- **No-code/low-code platforms** (Retool, Appsmith, Budibase) — whole-product
  procurement decisions, not libraries to add to a codebase.
- **Frontend UI component libraries** (MUI, shadcn/ui, Ant Design, and
  similar) — a general frontend concern, not specific to this category;
  belongs in a cross-cutting frontend baseline rather than duplicated here.
- **Email-sending/transactional-email providers** (Resend, Postmark,
  SendGrid) — the category-specific concern is background-job architecture
  (in scope above); the choice of email provider itself is a
  vendor-comparison task orthogonal to architecture/library curation.
- **Full event-sourcing frameworks** (EventStoreDB, Axon, and similar) — the
  stack doc scopes event sourcing as a targeted technique, not a primary
  architecture for this category; naming specific event-sourcing framework
  libraries would overstate how often this category needs them.

## Sources

All GitHub `stargazers_count` / `license.spdx_id` / `pushed_at` values below
were fetched directly from `api.github.com/repos/{org}/{repo}` on
2026-08-19 — listed once here rather than per-row for brevity.

- `vercel/next.js`, `remix-run/react-router`, `django/django`,
  `rails/rails`, `laravel/laravel` and `laravel/framework`, `prisma/prisma`,
  `drizzle-team/drizzle-orm`, `sqlalchemy/sqlalchemy`,
  `sqlalchemy/alembic`, `keycloak/keycloak`, `ory/kratos`,
  `better-auth/better-auth`, `nextauthjs/next-auth`, `casbin/casbin`,
  `osohq/oso`, `filamentphp/filament`, `avo-hq/avo`,
  `activeadmin/activeadmin`, `refinedev/refine`,
  `SoftwareBrothers/adminjs`, `marmelab/react-admin`,
  `taskforcesh/bullmq`, `celery/celery`, `sidekiq/sidekiq`,
  `inngest/inngest`, `triggerdotdev/trigger.dev`,
  `django-tenants/django-tenants`, `ErwinM/acts_as_tenant`,
  `influitive/apartment`, `getlago/lago`, `getlago/lago-api`,
  `openmeterio/openmeter`, `killbill/killbill` — license/star/push-date
  values as reported in the tables above, all retrieved 2026-08-19.
- PyPI JSON API, `celery` — license confirmed as BSD-3-Clause ("New BSD
  License") from package metadata, since GitHub's own detector returned
  NOASSERTION for the repo. Retrieved 2026-08-19.
- Direct license-file reads (all used because GitHub's own license
  detector returned NOASSERTION or an unreliable result for these repos):
  `raw.githubusercontent.com/avo-hq/avo/main/LICENSE.md` (Avo's
  open-source tier is LGPLv3; Pro/Advanced are separately licensed);
  `raw.githubusercontent.com/sidekiq/sidekiq/main/LICENSE.txt` (Sidekiq's
  open-source core is LGPLv3; Pro/Enterprise are commercial add-ons);
  `raw.githubusercontent.com/inngest/inngest/main/LICENSE.md` (Inngest is
  SSPL v1, not OSI-approved, with a 3-years-after-release Apache-2.0
  relicense provision); `raw.githubusercontent.com/getlago/lago-api/main/LICENSE`
  (Lago is AGPL-3.0, confirmed — GitHub's detector agreed here, unlike the
  other three). All retrieved 2026-08-19.
- WorkOS, ["WorkOS vs. Auth0 vs. Clerk: The Best Auth Platform for B2B SaaS
  in 2026"](https://workos.com/blog/workos-vs-auth0-vs-clerk-the-best-auth-platform-for-b2b-saas-in-2026) —
  vendor-authored; used only for pricing-model *shape* (metering unit,
  free-tier structure), read with the caveat that WorkOS is a party to the
  comparison, not neutral. Retrieved 2026-08-19.
- The Road to Enterprise, ["Postgres RLS for Multi-Tenant SaaS"](https://theroadtoenterprise.com/blog/postgres-rls-multi-tenant-saas) —
  cross-referenced with the stack doc; the concrete RLS + ORM
  session-variable pattern. Retrieved 2026-08-19.
- dev.to, "NestJS+Postgres+Prisma multi-tenancy using nestjs-cls and Prisma
  Client Extensions" and related search results — corroborates the finding
  that the Node/TS ecosystem has no dominant standalone multi-tenancy
  library, relying instead on ORM client-extensions/middleware plus
  Postgres RLS. Retrieved 2026-08-19.
- Stripe docs, [Usage-based billing](https://docs.stripe.com/billing/usage-based)
  and [Recording usage](https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage) —
  current docs lead with Metronome; legacy Billing Meters API positioned as
  appropriate only for existing users. Retrieved 2026-08-19.
- Stripe Newsroom, ["Stripe Completes Metronome Acquisition"](https://stripe.com/newsroom/news/stripe-completes-metronome-acquisition) —
  deal completed January 14, 2026. Retrieved 2026-08-19.
- OpenMeter, ["OpenMeter is joining Kong"](https://openmeter.io/blog/openmeter-is-joining-kong) —
  acquisition announced 2025-09-03; OpenMeter states it remains open source
  under Apache-2.0. Retrieved 2026-08-19.
- Orb, ["Orb is joining Adyen, and we're only getting better for our
  customers"](https://www.withorb.com/blog/orb-next-chapter) — Orb's own,
  CEO-authored announcement, fetched directly from withorb.com/blog as a
  follow-up verification pass: the acquisition **closed July 1, 2026**.
  This upgrades the citation the original research baseline carried (a
  competitor's — Lago's — blog post) to a primary source. Retrieved
  2026-08-20.
