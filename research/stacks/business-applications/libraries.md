# Baseline: Business Applications — Preferred Libraries
Status: user-approved      Date: 2026-08-19      Snapshot date: 2026-08-19

Every adoption/maintenance signal below was fetched directly from the GitHub API (`api.github.com/repos/...`) or PyPI JSON API on 2026-08-19 unless marked otherwise — not taken from a secondary blog's claimed number. Star counts are a weak proxy (they measure attention, not usage) and are reported alongside `pushed_at` (last push date) specifically so staleness is visible, not just popularity.

## In scope

### Full-stack / batteries-included frameworks — impact: high — depth: table

| Framework | For | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **Next.js** (App Router) | React meta-framework: RSC, SSR, API routes, file-based routing | MIT | 2026-08-19 (daily activity) | 141,863 | Default when the app needs a public/marketing surface alongside the authenticated product, or first-load performance on data-heavy dashboards matters. See stack.md for the RSC-vs-SPA decision rule — do not reach for this by default for a pure internal tool. |
| **React Router v7** (framework mode, formerly Remix) | React meta-framework, SSR-optional | MIT | 2026-08-18 | 56,557 | Lighter-weight alternative to Next.js when SSR is wanted but the App Router's RSC model/complexity isn't — good fit for teams wanting server rendering without committing to the RSC mental model. Remix merged into React Router v7 in Nov 2024; "Remix" as a separate framework is effectively legacy naming now. |
| **Django** | Python batteries-included web framework | BSD-3-Clause | 2026-08-19 (daily activity) | 88,474 | Strongest "batteries-included" option for this category specifically because of Django Admin (see admin-panel section) and its ORM/migrations being first-party and mature. Best default when the team is Python-first and wants the least third-party assembly. |
| **Ruby on Rails** | Ruby batteries-included web framework | MIT | 2026-08-19 (daily activity) | 58,695 | Comparable to Django's pitch — first-party ORM (Active Record), migrations, and (via Avo/ActiveAdmin, see below) mature admin options. Best default for Ruby-first teams; convention-over-configuration reduces architecture bikeshedding for CRUD-shaped business apps. |
| **Laravel** | PHP batteries-included web framework | MIT | 2026-08-18 | 34,874 (framework repo) | PHP-first equivalent; paired with Filament (below) gives one of the fastest build-vs-buy admin stories of any stack in this comparison. Worth including because PHP/Laravel remains a live, high-volume choice for exactly this category (SMB/mid-market business apps), not a legacy pick. Note: `laravel/laravel` (84,825 stars) is the project skeleton, not the framework — `laravel/framework` is the actual library and is what was verified for license/activity here. |

**Decision rule**: pick the framework matching the team's existing language/ecosystem first — Django/Rails/Laravel win on time-to-admin-panel for CRUD-shaped apps; Next.js/React Router win when the team is already React-first or needs a unified marketing+app codebase.

### ORM / database migrations — impact: high — depth: table

| Tool | Ecosystem | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **Prisma** | Node/TypeScript | Apache-2.0 | 2026-08-19 | 47,569 | Most-adopted TS-first ORM with first-party migrations (`prisma migrate`); strong fit for Next.js/React Router stacks. Trade-off to state honestly: Prisma's query engine has historically had cold-start/binary-size overhead in serverless environments — worth flagging, not disqualifying. |
| **Drizzle ORM** | Node/TypeScript | Apache-2.0 | 2026-08-19 | 35,519 | Newer, SQL-closer alternative to Prisma — no separate query-engine binary, TypeScript-native schema-as-code. Growing fast (35.5k stars, comparable push cadence to Prisma) and increasingly the default recommendation for new TS projects wanting less abstraction over SQL and lighter serverless cold-starts. Trade-off: smaller ecosystem of guides/tooling than Prisma's maturity. |
| **SQLAlchemy** | Python | MIT | 2026-08-18 | 12,093 | The Python ORM outside Django's own ORM; relevant when the team wants Python but not Django's full-stack opinions (e.g., FastAPI + SQLAlchemy for the API layer, paired with a separate frontend). Django's built-in ORM remains the default *inside* Django itself. |
| **Alembic** | Python (migrations for SQLAlchemy) | MIT | 2026-08-14 | 4,329 | SQLAlchemy has no built-in migration tool — Alembic is the de facto companion for schema migrations wherever SQLAlchemy is chosen outside Django (which has its own first-party migrations). Required pairing, not optional, whenever SQLAlchemy is recommended above. |
| **drizzle-kit** | Node/TypeScript (migrations/introspection for Drizzle) | Apache-2.0 (same `drizzle-team` org and license as Drizzle ORM; not independently re-verified as a separate repo in this pass) | — | — | Drizzle's first-party migration/schema-push CLI — mentioned for completeness since Drizzle ORM alone (row above) doesn't cover migrations; ships from the same team/license as the ORM itself. |
| **Active Record** (Rails built-in) | Ruby | MIT (bundled with Rails) | — | — | First-party, not a separate adoption decision — the default inside Rails. Listed for completeness since ORM choice is often assumed rather than stated. |

### Auth / identity — build vs. buy — impact: high — depth: section

The real axis in this category is **managed/hosted vs. self-hosted**, not just vendor-vs-vendor — state this trade-off explicitly rather than picking a single winner.

**Managed/hosted (buy)** — trades ongoing infra/security ownership for per-user or per-org metering cost and vendor dependency:
- **Clerk** — proprietary hosted auth service; primary React/Next.js SDK (`@clerk/nextjs`) is MIT-licensed even though the backend service is closed/hosted. Pricing shape: free tier up to a fixed retained-user count, then metered per monthly-retained-user (MRU — counts only users who return, a materially different metric from raw MAU), plus a separate per-active-organization charge for B2B multi-tenant features. Best fit: teams prioritizing developer velocity building consumer or SMB-facing products where enterprise compliance (SAML/SCIM) isn't yet a near-term requirement. *(Pricing described by shape only per the research brief — exact dollar figures change and were not treated as stable facts here; see WorkOS's own comparison post for current numbers, read as vendor-authored and directionally useful, not neutral.)*
- **WorkOS (AuthKit)** — proprietary hosted auth service explicitly positioned for B2B SaaS; distinguishing feature is enterprise-readiness out of the box (SSO/SAML, SCIM directory sync, audit logs) bundled rather than paywalled behind an "enterprise tier," which is the opposite of how Auth0/Clerk historically gated those features. Pricing shape: free tier with a high active-user ceiling, then metered — the relevant differentiator for this category is that enterprise-buyer features (SSO/SCIM) are reachable without a large plan jump. Best fit: B2B SaaS selling to companies (not just consumers) where a customer will eventually demand SSO.
- **Auth0** — the incumbent managed IDaaS; broad feature surface and maturity, but per-MAU pricing has reportedly risen sharply in recent repricing (multiple 2026 vendor-comparison sources cite a jump from ~$0.023 to ~$0.07/MAU — flagged as vendor/competitor-sourced, not independently verified, include only as a directional signal that Auth0 has gotten materially more expensive at scale, not as a hard number).

**Self-hosted (build on top of, not from scratch)** — zero per-user metering, full data control, but real ops burden:
- **Keycloak** — Apache-2.0, verified 36,277 stars, pushed 2026-08-19 (very active). The enterprise on-prem/self-hosted workhorse (Red Hat-backed). Best fit: regulated/enterprise environments needing full control over identity infra and willing to run and patch a Java-based IdP themselves.
- **Ory Kratos** — Apache-2.0, verified 13,833 stars, pushed 2026-07-29. Headless, API-first identity server (Go) — no bundled UI, built for teams that want to own the entire auth UI/UX and just need the identity/session primitives. Best fit: API-first teams, or teams already committed to building custom auth UX who don't want an IdP's bundled login pages.
- **Better Auth** — MIT, verified 29,592 stars, pushed 2026-08-19 (very active). TypeScript-native, self-hosted-by-default auth *library* (not a hosted service) that runs inside a Node/TS app rather than as a separate identity server — increasingly the default recommendation for TS full-stack apps (Next.js/React Router) that want to self-host without standing up Keycloak/Ory as separate infrastructure.
- **Auth.js (NextAuth)** — ISC, verified 28,332 stars, pushed 2026-07-22. The longer-established TS-native auth library; broad OAuth-provider adapter ecosystem. Better Auth has overtaken it in growth momentum and is generally the newer default recommendation as of this snapshot, but Auth.js remains a safe, mature choice with a larger existing body of integration guides.

**Decision rule to carry into the skill**: if the product sells to businesses (not just consumers) and enterprise SSO/SCIM is plausible within 12-18 months, default to WorkOS. If the product is consumer/SMB-facing and developer velocity matters most, default to Clerk. If data residency/compliance/cost-at-scale rules out per-user metering entirely, default to self-hosted — Better Auth for a TS app willing to own its own auth server code, Keycloak/Ory when a dedicated identity-server process is acceptable or preferred.

### Authorization / policy libraries (RBAC → ABAC layering) — impact: med-high — depth: table

| Tool | For | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **Casbin** | Policy-based authorization supporting ACL, RBAC, ABAC models, multi-language (Go core + Node/Python/Java/.NET ports) | Apache-2.0 | 2026-08-13 | 20,330 | The concrete tool for the stack.md "layer ABAC rules onto RBAC incrementally" decision rule — model-agnostic, so a project can start RBAC and add attribute-based policies to specific resource types without switching libraries. |
| ~~Oso~~ | (was) policy engine for app authorization | Apache-2.0 | 2025-02-26 | 3,492 | **Excluded from the active recommendation** — verified directly via GitHub API that the `osohq/oso` repo description now reads "Deprecated: See README" and the last push predates this snapshot by 18 months. Oso pivoted to a hosted product (Oso Cloud); the open-source library line is no longer the vendor's focus. Included here only as a documented exclusion so it isn't independently rediscovered and recommended without this context. |

### Admin panel / back-office generators — impact: med — depth: table

| Tool | Ecosystem | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **Django Admin** | Django (Python) | BSD-3-Clause (bundled with Django) | — | — | First-party, ships with the framework. Auto-generates CRUD screens from models with auth already wired. Default choice whenever the backend is already Django. |
| **Filament** | Laravel (PHP) | MIT | 2026-08-18 | 31,840 | The Laravel-ecosystem equivalent of Django Admin's build-in-minutes pitch, built on Livewire. Fastest admin story of any stack surveyed here for PHP teams. |
| **Avo** | Ruby on Rails | Open-core, verified by reading `LICENSE.md` directly (GitHub's detector had returned NOASSERTION): the open-source edition is **LGPLv3**; Avo Pro and Avo Advanced are separately licensed under a commercial-friendly license (terms at avohq.io) — confirm which tier applies before adopting, since LGPLv3's copyleft terms are more restrictive than Filament/ActiveAdmin's MIT | 2026-08-19 | 1,797 | Named in current comparisons as the more actively promoted modern Rails admin option, but its LGPLv3 open-source tier is a real license difference from the MIT alternatives in this table — worth weighing against ActiveAdmin (below) specifically on license terms, not just feature set. |
| **ActiveAdmin** | Ruby on Rails | MIT | 2026-08-19 | 9,704 | The older, unambiguously-MIT Rails admin framework — higher star count and more active push cadence than Avo in this snapshot. Prefer this over Avo when a permissive license matters more than Avo's newer feature set; prefer Avo when its Pro/Advanced commercial features are worth the LGPLv3 open-source-tier trade-off. |
| **Refine** | React (headless, framework-agnostic backend) | MIT | 2026-06-05 (roughly 2.5 months before this snapshot — worth a freshness re-check at authoring time, though not stale enough on its own to disqualify given 35k+ stars and a large existing plugin ecosystem) | 35,533 | Best fit for JS/TS stacks (Next.js, React Router) with no first-party admin: generates CRUD scaffolding while leaving full code ownership, rather than a black-box auto-admin. Highest star count of the JS-ecosystem options surveyed. |
| **AdminJS** | Node.js (auto-generated from DB/ORM models) | MIT | 2025-07-15 | 8,979 | Closer to Django Admin's "auto-generate from the data model" model than Refine's scaffold-and-own approach — pick this when the goal is the fastest possible internal CRUD UI and full code ownership isn't a priority. Last push over a year before this snapshot — worth a freshness check at authoring time given the category's fast-moving JS ecosystem. |
| **React Admin** | React (SPA against REST/GraphQL) | MIT | 2026-08-09 | 26,897 | The older, still-actively-maintained option for hand-building a fully custom admin SPA against an existing API — pick over Refine/AdminJS when the admin needs bespoke UX beyond CRUD scaffolding and the team wants to build the whole thing in React directly. |

### Background job / async-task libraries — impact: high — depth: table

| Tool | Ecosystem | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **BullMQ** | Node/TypeScript, Redis-backed | MIT | 2026-08-19 | 9,305 | The standard self-run Node queue library — you own Redis and worker processes. Right default when the team wants full control/no vendor and is comfortable operating Redis. |
| **Celery** | Python, multi-broker (Redis/RabbitMQ) | BSD-3-Clause (verified via PyPI JSON metadata, not just GitHub's license detector which returned NOASSERTION for the repo) | 2026-08-18 | 28,795 | The long-standing Python default, especially paired with Django/Flask. Mature but heavier operationally (broker + worker + beat scheduler for cron-style jobs) than newer managed alternatives. |
| **Sidekiq** | Ruby, Redis-backed | LGPL-3.0 for the open-source core (verified by reading the repo's `LICENSE.txt` directly — GitHub's own license-detection field returned NOASSERTION, so this required a direct file check); Sidekiq Pro/Enterprise are separately licensed commercial add-ons | 2026-08-17 | 13,553 | The Rails-ecosystem default; open-core model means the free tier is a real, unencumbered LGPL library, with paid tiers only adding reliability/observability features, not gating core functionality. |
| **Inngest** | Node/TypeScript, managed durable-execution platform | **Server Side Public License (SSPL) v1** for the open-source repo, verified by reading `LICENSE.md` directly (GitHub's detector returned NOASSERTION, which undersold how non-permissive this actually is) — SSPL is not OSI-approved open source; it carries the same MongoDB-style copyleft-on-service-operators terms, with a provision that the code relicenses to Apache-2.0 three years after each version's release date | 2026-08-19 | 5,740 | Represents the "durable execution" architectural shift named in stack.md: steps are individually retriable and resumable without the team running Redis/workers themselves. **License caveat matters concretely here**: SSPL is fine for using Inngest as a managed cloud service (the normal usage mode) but is a real constraint if the plan is to self-host the Inngest server as part of a competing offering — read the SSPL terms directly before that decision, don't assume it behaves like a normal permissive license. |
| **Trigger.dev** | Node/TypeScript, managed durable-execution platform (v4 GA Aug 2025 per vendor sources) | Apache-2.0 (genuinely permissive, unlike Inngest's SSPL) | 2026-08-19 | 16,064 | Same architectural category as Inngest (managed durable execution) — Apache-2.0 makes this the clearer license choice of the two if self-hosting or license simplicity matters; Inngest's SSPL is the more meaningful differentiator here than star count. |

**Decision rule to carry into the skill**: default to the ecosystem-native self-run library (BullMQ/Celery/Sidekiq) when the team already operates Redis and wants no new vendor dependency. Default to a managed durable-execution platform when the jobs in question are genuinely multi-step business workflows that benefit from step-level durability and the team would rather not operate queue infrastructure — prefer Trigger.dev over Inngest specifically on license grounds (Apache-2.0 vs. Inngest's SSPL, verified directly above), not just feature parity.

### Multi-tenancy libraries/tooling — impact: med — depth: table

Per stack.md, multi-tenancy is primarily an architecture decision, but concrete tooling exists for a subset of stacks:

| Tool | Ecosystem | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **django-tenants** | Django/PostgreSQL | MIT | 2026-08-10 | 1,881 | Concrete schema-per-tenant implementation for Django/Postgres — routes queries by Postgres schema per tenant. The go-to library when stack.md's schema-per-tenant pattern is the right fit and the stack is Django. |
| **acts_as_tenant** | Ruby on Rails, shared-schema (row-level, app-scoped) | MIT | 2025-04-16 | 1,700 | The actively-maintained Rails shared-schema multi-tenancy gem; scopes Active Record queries automatically by a current-tenant context. Prefer this over `apartment` (below) for new Rails projects. |
| ~~apartment~~ | Ruby on Rails, schema-per-tenant | License field empty/unset on GitHub — could not verify a license directly, which is itself a reason for caution | 2024-06-12 | 2,684 | **Flagged, not recommended as the default** — higher star count than acts_as_tenant but last pushed over two years before this snapshot (as of 2026-08-19) with no confirmed license. Include only as a documented "was popular, appears stale now" note, not as an active recommendation. |
| **Postgres Row-Level Security** (native DB feature, not a library) | Any stack on Postgres | N/A — Postgres core feature (PostgreSQL License) | — | — | The cross-ecosystem, framework-agnostic enforcement mechanism referenced in stack.md's shared-schema default. Not tied to any ORM, though Prisma/Drizzle/SQLAlchemy/Active Record all have documented patterns for setting the session-level tenant context RLS policies read. |
| *(none — documented gap)* | Node/TypeScript (Prisma/Drizzle) | — | — | — | **Explicit finding, not an omission**: unlike Django (django-tenants) and Rails (acts_as_tenant), there is no dominant standalone multi-tenancy library in the Node/TS ecosystem despite Next.js/React Router being this baseline's most-recommended frameworks. The consistent pattern found across current sources is hand-rolled: an ORM client-extension or middleware (e.g., Prisma Client Extensions, or `nestjs-cls`-style `AsyncLocalStorage` context in Nest apps) that calls `set_config('app.tenant_id', ...)` per request/transaction, paired with Postgres RLS policies (row above) as the actual enforcement layer. Worth stating this gap plainly in the authored skill rather than implying a library exists. |

### Billing / subscription / metering platforms — impact: high — depth: table

| Tool | For | License | Last verified push | Stars (verified) | Why recommended |
|---|---|---|---|---|---|
| **Stripe Billing + Metronome** | Managed billing: subscriptions, invoicing, usage-based/metered pricing | Proprietary hosted service (Metronome is now a Stripe product) | — | — | Verified directly against Stripe's own docs (`docs.stripe.com/billing/usage-based`, `.../recording-usage`, 2026-08-19): Stripe completed its acquisition of Metronome on **January 14, 2026**, and Stripe's usage-based billing docs now lead with Metronome, stating the legacy Billing Meters/meter-events API "is appropriate only if you are already billing customers via Billing Meters today" — new integrations, including adding usage pricing to an existing flat-rate Stripe Billing subscription, are directed to Metronome instead. Practical effect: recommending "Stripe Billing" for a new usage-metered integration now means routing through Metronome's ingest/rating engine, not the older self-service Meters API. Best fit: teams that want a managed, non-self-hosted billing engine and are already on or open to Stripe for payments. |
| **Lago** | Open-source metering, rating, invoicing, subscription management; self-hosted or Lago Cloud | AGPL-3.0 (verified by reading `LICENSE` directly on the actual backend repo, `getlago/lago-api` — GitHub's detector agreed here, unlike several prior findings in this file) | 2026-08-19 | 431 (`lago-api`, the actual engine); the umbrella repo `getlago/lago` shows 10,369 stars — star count concentrates on the umbrella/marketing repo, not the code, the same split pattern already documented for Laravel (`laravel/laravel` skeleton vs. `laravel/framework`) in this file | The clearest open-source Stripe-Billing-alternative for teams wanting to self-host the billing engine itself. **License caveat, real and load-bearing**: AGPL-3.0 (not the more permissive MIT/Apache-2.0 seen elsewhere in this file) triggers copyleft on network use, not just distribution — modifying Lago and offering the modified version as a network-accessible service obligates releasing those modifications' source. Fine for internal self-hosting as-is; a real constraint if the plan is to fork/modify Lago and resell it as a competing hosted billing product. Confirm this is acceptable before adopting, the same way this file already flags Avo's LGPLv3 and Sidekiq's LGPLv3 tiers. Independence note: unlike Metronome (now Stripe) and Orb (Adyen announced acquiring it ~June 2026 per Lago's own competitor-authored blog post, not independently verified here), Lago integrates with multiple payment processors (Stripe, Adyen, GoCardless) without being owned by one — a real differentiator if payment-processor neutrality matters. |
| **OpenMeter** | Open-source real-time usage metering and billing, focused on high-volume event ingestion (APIs, AI token usage) | Apache-2.0 (verified via direct GitHub API fetch and corroborated by OpenMeter's own acquisition announcement, which states the project is "built as a true open-source project under Apache 2.0" and "will remain open source with ongoing development") | 2026-08-19 | 2,213 | Kong acquired OpenMeter (announced 2025-09-03, full Kong Konnect integration targeted early 2026, customer migration mid-2026) — verified directly via OpenMeter's own blog post, not a secondary source. Unlike the Stripe/Metronome and Adyen/Orb consolidations, this is a smaller, still-independently-licensed project being absorbed into an API-infrastructure vendor (Kong) rather than a payments processor, and Kong's own core products share the same Apache-2.0 license — a materially lower lock-in risk than Lago's AGPL-3.0 or a closed-source managed vendor. Best fit: metering-heavy, high-event-volume use cases (API/AI usage billing) specifically, per the project's own stated focus, rather than full subscription/invoicing lifecycle management. |
| **Kill Bill** | Open-source subscription billing and payments platform (JVM/Java) | Apache-2.0 | 2026-08-19 (active) | 5,694 | Verified via direct GitHub API fetch. The older, more mature open-source option in this table (predates Lago and OpenMeter by years) with a genuinely permissive license (no AGPL/LGPL caveat) — worth naming as the alternative when a team wants self-hosted billing without Lago's copyleft terms and is comfortable with a JVM-based stack. Smaller community/momentum than Lago by star count and less focused on modern usage-metering/AI-token use cases than OpenMeter, but a legitimate, actively-maintained third option, not a stale relic. |

**Decision rule to carry into the skill**: default to Stripe Billing/Metronome for teams already on Stripe or without a specific reason to self-host — it is the managed, lowest-operational-burden path and is now the vendor's own recommended integration point for usage-based pricing (verified directly, not assumed from the "call Stripe" folk pattern). Reach for a self-hosted open-source platform (Lago, OpenMeter, or Kill Bill) when data residency/compliance rules out sending usage or customer billing data to a US-based managed vendor, when billing/rating logic is a genuine product differentiator worth owning, or when payment-processor neutrality specifically matters (Lago's pitch, given Metronome's and Orb's 2026 acquisitions by Stripe and Adyen respectively). Among the self-hosted options: Lago for the broadest current feature set (metering + rating + invoicing + entitlements + wallets) if the AGPL-3.0 network-copyleft term is acceptable; OpenMeter specifically for high-volume real-time metering (API/AI usage) under a more permissive Apache-2.0 license; Kill Bill for teams wanting a longer-established, JVM-based, unambiguously permissive-licensed option. Never hand-roll usage rating/proration/invoicing logic from scratch — see stack.md's billing sub-topic for why.

## Explicitly out of scope

- **No-code/low-code platforms (Retool, Appsmith, Budibase)** — why excluded: matches stack.md's exclusion — these are whole-product procurement decisions, not libraries to add to a codebase.
- **Frontend UI component libraries (MUI, shadcn/ui, Ant Design, etc.)** — why excluded: this is a general frontend concern, not specific to the business-applications category; likely belongs in a cross-cutting frontend baseline rather than duplicated here.
- **Email-sending/transactional-email providers (Resend, Postmark, SendGrid)** — why excluded: background-job architecture (in scope) is the category-specific concern; the choice of email provider itself is a vendor-comparison task orthogonal to architecture/library curation and wasn't in the explicit ask.
- **Full event-sourcing frameworks (EventStoreDB, Axon, etc.)** — why excluded: stack.md scopes event sourcing as a targeted technique, not a primary architecture for this category; naming specific event-sourcing framework libraries would overstate how often this category needs them.

## Sources

All GitHub `stargazers_count`/`license.spdx_id`/`pushed_at` values below were fetched directly from `api.github.com/repos/{org}/{repo}` on 2026-08-19 — listed once here rather than per-row for brevity; repo paths are given.
- https://api.github.com/repos/vercel/next.js — Next.js: 141,863 stars, MIT, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/remix-run/react-router — React Router: 56,557 stars, MIT, pushed 2026-08-18 — retrieved 2026-08-19
- https://api.github.com/repos/django/django — Django: 88,474 stars, BSD-3-Clause, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/rails/rails — Rails: 58,695 stars, MIT, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/laravel/laravel — Laravel skeleton repo (not the framework itself): 84,825 stars, license field unset, pushed 2026-08-18 — retrieved 2026-08-19
- https://api.github.com/repos/laravel/framework — the actual Laravel framework library: 34,874 stars, MIT, pushed 2026-08-18 — retrieved 2026-08-19
- https://api.github.com/repos/prisma/prisma — Prisma: 47,569 stars, Apache-2.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/drizzle-team/drizzle-orm — Drizzle ORM: 35,519 stars, Apache-2.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/sqlalchemy/sqlalchemy — SQLAlchemy: 12,093 stars, MIT, pushed 2026-08-18 — retrieved 2026-08-19
- https://api.github.com/repos/keycloak/keycloak — Keycloak: 36,277 stars, Apache-2.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/ory/kratos — Ory Kratos: 13,833 stars, Apache-2.0, pushed 2026-07-29 — retrieved 2026-08-19
- https://api.github.com/repos/better-auth/better-auth — Better Auth: 29,592 stars, MIT, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/nextauthjs/next-auth — Auth.js/NextAuth: 28,332 stars, ISC, pushed 2026-07-22 — retrieved 2026-08-19
- https://api.github.com/repos/casbin/casbin — Casbin: 20,330 stars, Apache-2.0, pushed 2026-08-13 — retrieved 2026-08-19
- https://api.github.com/repos/osohq/oso — Oso: 3,492 stars, Apache-2.0, pushed 2025-02-26, description reads "Deprecated: See README" — retrieved 2026-08-19
- https://api.github.com/repos/filamentphp/filament — Filament: 31,840 stars, MIT, pushed 2026-08-18 — retrieved 2026-08-19
- https://api.github.com/repos/avo-hq/avo — Avo: 1,797 stars, GitHub license detector returned NOASSERTION, pushed 2026-08-19 — retrieved 2026-08-19
- https://raw.githubusercontent.com/avo-hq/avo/main/LICENSE.md — Avo open-source tier confirmed LGPLv3 by reading the license file directly; Avo Pro/Advanced are a separate commercial license — retrieved 2026-08-19
- https://api.github.com/repos/activeadmin/activeadmin — ActiveAdmin: 9,704 stars, MIT, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/refinedev/refine — Refine: 35,533 stars, MIT, pushed 2026-06-05 — retrieved 2026-08-19
- https://api.github.com/repos/SoftwareBrothers/adminjs — AdminJS: 8,979 stars, MIT, pushed 2025-07-15 — retrieved 2026-08-19
- https://api.github.com/repos/marmelab/react-admin — React Admin: 26,897 stars, MIT, pushed 2026-08-09 — retrieved 2026-08-19
- https://api.github.com/repos/taskforcesh/bullmq — BullMQ: 9,305 stars, MIT, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/celery/celery — Celery: 28,795 stars, GitHub license detector returned NOASSERTION, pushed 2026-08-18 — retrieved 2026-08-19
- https://pypi.org/pypi/celery/json — Celery license confirmed via PyPI package metadata as BSD-3-Clause ("New BSD License"), latest version 5.6.3 — retrieved 2026-08-19
- https://api.github.com/repos/sidekiq/sidekiq — Sidekiq: 13,553 stars, GitHub license detector returned NOASSERTION, pushed 2026-08-17 — retrieved 2026-08-19
- https://raw.githubusercontent.com/sidekiq/sidekiq/main/LICENSE.txt — Sidekiq open-source core confirmed LGPLv3 by reading the license file directly; Pro/Enterprise are separate commercial licenses — retrieved 2026-08-19
- https://api.github.com/repos/inngest/inngest — Inngest: 5,740 stars, GitHub license detector returned NOASSERTION, pushed 2026-08-19 — retrieved 2026-08-19
- https://raw.githubusercontent.com/inngest/inngest/main/LICENSE.md — Inngest license confirmed by reading the file directly as Server Side Public License (SSPL) v1.0 with an Apache-2.0 future-license grant after 3 years per version — not OSI-approved open source, materially different from the "source-available, assume permissive" framing a star-count-only check would suggest — retrieved 2026-08-19
- https://api.github.com/repos/triggerdotdev/trigger.dev — Trigger.dev: 16,064 stars, Apache-2.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/sqlalchemy/alembic — Alembic: 4,329 stars, MIT, pushed 2026-08-14 — retrieved 2026-08-19
- https://api.github.com/repos/django-tenants/django-tenants — django-tenants: 1,881 stars, MIT, pushed 2026-08-10 — retrieved 2026-08-19
- https://api.github.com/repos/ErwinM/acts_as_tenant — acts_as_tenant: 1,700 stars, MIT, pushed 2025-04-16 — retrieved 2026-08-19
- https://api.github.com/repos/influitive/apartment — apartment: 2,684 stars, license field empty/unset, pushed 2024-06-12 (stale) — retrieved 2026-08-19
- https://workos.com/blog/workos-vs-auth0-vs-clerk-the-best-auth-platform-for-b2b-saas-in-2026 — vendor-authored comparison; used only for pricing-model *shape* (metering unit, free-tier structure) and read with the caveat that WorkOS is a party to the comparison, not neutral — retrieved 2026-08-19
- https://theroadtoenterprise.com/blog/postgres-rls-multi-tenant-saas — cross-referenced with stack.md; concrete pattern for RLS + Prisma/any ORM via `set_config` session variables — retrieved 2026-08-19
- https://dev.to/moofoo/nestjspostgresprisma-multi-tenancy-using-nestjs-prisma-nestjs-cls-and-prisma-client-extensions-ok7 and related search results for "Node.js TypeScript multi-tenancy library Prisma Drizzle row-level security tenant middleware npm" — corroborates the finding that the Node/TS ecosystem has no dominant standalone multi-tenancy library, relying instead on ORM client-extensions/middleware + Postgres RLS — retrieved 2026-08-19
- https://docs.stripe.com/billing/usage-based — direct fetch: Stripe's current usage-based billing landing page leads with Metronome as the recommended path for new integrations — retrieved 2026-08-19
- https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage — direct fetch: explicit statement that the legacy Billing Meters API "is appropriate only if you are already billing customers via Billing Meters today" and new integrations should use Metronome — retrieved 2026-08-19
- https://stripe.com/newsroom/news/stripe-completes-metronome-acquisition — direct fetch: Stripe completed the Metronome acquisition January 14, 2026 — retrieved 2026-08-19
- https://api.github.com/repos/getlago/lago — Lago umbrella repo: 10,369 stars, AGPL-3.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://api.github.com/repos/getlago/lago-api — Lago's actual backend engine repo (distinct from the umbrella repo above, same split pattern as Laravel's skeleton-vs-framework repos): 431 stars, AGPL-3.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://raw.githubusercontent.com/getlago/lago-api/main/LICENSE — Lago license confirmed by reading the file directly: "GNU AFFERO GENERAL PUBLIC LICENSE Version 3" — retrieved 2026-08-19
- https://api.github.com/repos/openmeterio/openmeter — OpenMeter: 2,213 stars, Apache-2.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://openmeter.io/blog/openmeter-is-joining-kong — direct fetch: Kong's acquisition of OpenMeter announced 2025-09-03; direct quote confirms the project "will remain open source" under Apache-2.0 — retrieved 2026-08-19
- https://api.github.com/repos/killbill/killbill — Kill Bill: 5,694 stars, Apache-2.0, pushed 2026-08-19 — retrieved 2026-08-19
- https://getlago.com/blog/orb-adyen-acquisition-lago-alternative — competitor-authored (Lago vs. Orb); used only as a directional signal for the Adyen/Orb acquisition (announced ~June 11 2026 per this source) since no primary Adyen/Orb source could be reached in this pass — read with the same "vendor is a party to the comparison" caveat already applied to the WorkOS source above — retrieved 2026-08-19

## Open questions for the user

1. The Adyen/Orb acquisition date (~June 2026) could not be confirmed against a primary Adyen or Orb source in this pass (both `adyen.com/press-and-media/...` and `orb.com/blog` guesses 404'd) — carried only on Lago's competitor-authored blog post. Does not affect the independently-verified Stripe/Metronome finding.

## Resolutions (Checkpoint D review, 2026-08-19)

- **Python billing/job managed-alternative gap**: acceptable to leave
  unfilled — Celery remains the documented, well-established Python
  option; no strong Python-ecosystem Inngest/Trigger.dev equivalent exists
  to recommend instead.
- **"Last reviewed" refresh cadence**: resolved by the new repo-wide
  policy (6-month staleness threshold for audit-mode flagging) — see
  `research/skill-flow-decisions.md`. No longer an open question specific
  to this file.
- **ActiveAdmin vs. Avo**: keep ActiveAdmin as the named default (MIT,
  unambiguous permissive license) with Avo as the documented LGPLv3
  alternative — matches this repo's established license-first,
  name-one-opinionated-default convention (the same pattern already
  applied to Trigger.dev over Inngest, GraphQL Yoga over the Apollo stack,
  and Envoy Gateway over Kong).
- **Adyen/Orb acquisition date**: kept flagged above pending a follow-up
  direct-source check at Phase 2 authoring, per the standing
  verify-before-publish policy.

## Target file(s) + estimated length
- skills/project-incubation/references/preferred-libraries/business-applications.md — est. 300-320 lines (revised up from the original 260-line estimate to account for the added billing sub-topic)
