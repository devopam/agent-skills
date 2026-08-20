# Backend & API Services — Architecture & Stack

This category covers services whose primary interface is an API surface —
REST, GraphQL, or gRPC — consumed by another conventional client or service,
not by an LLM agent (see [Agentic & MCP Platforms](agentic-mcp-platforms.md)
for that adjacent case) and not primarily a data-pipeline or event-broker
system (see [Data & Analytics Platforms](data-analytics-platforms.md) and
[Integration & Event-Driven Systems](integration-event-driven-systems.md)).
Recommendations below are externally sourced against each platform's or
project's own documentation rather than drawn from a worked in-repo
example — this category is closer to greenfield than most.

One convention carried through every section: numeric claims (adoption
percentages, throughput multipliers, benchmark comparisons) are omitted
wherever the only source traced back to an SEO-aggregator or vendor-marketing
page rather than a primary source. Where a comparison matters and no
trustworthy number exists, the section says so and gives the qualitative
signal instead.

## Table of contents

- [Architecture patterns for an API service](#architecture-patterns-for-an-api-service)
- [REST vs. GraphQL vs. gRPC](#rest-vs-graphql-vs-grpc)
- [Contract-first design](#contract-first-design)
- [API versioning strategy](#api-versioning-strategy)
- [Authentication and authorization patterns](#authentication-and-authorization-patterns)
- [Rate limiting and throttling](#rate-limiting-and-throttling)
- [API gateway vs. Backend-for-Frontend](#api-gateway-vs-backend-for-frontend)
- [Idempotency for mutating endpoints](#idempotency-for-mutating-endpoints)
- [Error-response design](#error-response-design)
- [Pagination patterns](#pagination-patterns)
- [Testing approaches specific to APIs](#testing-approaches-specific-to-apis)
- [Security concerns specific to this category](#security-concerns-specific-to-this-category)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Architecture patterns for an API service

A backend/API service is the clearest home, among
[architecture-templates.md](../architecture-templates.md)'s seven
cross-cutting patterns, for **hexagonal (ports & adapters)**: the inbound
port is the HTTP/gRPC/GraphQL handler, the outbound adapters are the
database/cache/downstream-API clients, and the domain logic in between
shouldn't know or care which protocol served the request. **Modular
monolith is the honest default starting point** for a new API service — one
deployable, internally separated by domain module, each module already
hexagonal-shaped internally so a future extraction is a deployment change,
not a redesign. **Microservices** are justified only once independent team
ownership or an independent scaling/deployment cadence is a real, present
constraint — not a default posture for "an API service" as a category.

**CQRS/event sourcing** stays rarely justified, with one narrower exception
worth naming here specifically: an API service whose read traffic and write
traffic have genuinely disparate shape (high-fanout reads, rare complex
writes) is the one scenario Fowler himself calls legitimate.

**Event-driven is an overlay, not a replacement**, for the request/response
API surface. Three concrete places it attaches to an API service: webhooks
(outbound event delivery to a caller-supplied URL), async job kickoff (a
mutating endpoint enqueues work and returns `202 Accepted` plus a status URL
rather than blocking the caller), and integration fan-out. Full event-driven
architecture — brokers, delivery guarantees, event schema evolution — is the
Integration & Event-Driven Systems baseline's job; this doc stops at the
point where an API surface touches that world.

**Serverless** is a deployment-axis fit for API services with spiky, low, or
unpredictable traffic and mostly-stateless handlers — a special case of the
general "stateless HTTP handlers deploy cleanly to serverless" pattern. It's
a poor fit once handlers need long-lived connections (WebSocket or gRPC
streaming) or consistent low-latency warm state.

## REST vs. GraphQL vs. gRPC

Vendor and SEO-aggregator "40–45% of teams," "4–10x faster," "pays off at
5+ services" figures turn up repeatedly for this comparison with no primary
source behind them — excluded here as unverifiable fake precision. The
durable, checkable discriminators instead:

| Signal | REST | GraphQL | gRPC |
|---|---|---|---|
| Browser-callable directly | Yes | Yes (over HTTP POST) | **No** — the official `grpc/grpc-web` repo states plainly that gRPC-Web clients reach a gRPC service only via a translating proxy (Envoy by default, with Nginx and a dedicated Go proxy as alternatives). Browsers' fetch/XHR stack doesn't support the HTTP/2-trailers mechanism gRPC's wire format depends on — the repo doesn't spell out the mechanism, only the practical requirement, which is what this row relies on |
| HTTP-layer cacheability | Yes — GET is cacheable by CDNs/proxies by default | **No** — queries are POST-based by default, defeating standard HTTP caching; needs persisted-queries/APQ workarounds | N/A — not HTTP-cache-shaped traffic |
| Best-fit client population | Public/third-party APIs — universal tooling, curl-able, self-documenting via OpenAPI | Many heterogeneous clients (web, mobile, partner) that each need to shape their own response, where over/under-fetching from a fixed REST shape is a real, measured pain | Internal service-to-service calls where both ends are code you control and can regenerate from a shared `.proto` |
| Known operational cost | Versioning discipline (see below) | N+1 query risk requires DataLoader/batching; unbounded query depth/complexity requires cost limits before public exposure | Proto schema evolution discipline; no ad-hoc browser debugging |
| Streaming | Polling or SSE bolted on | Subscriptions, typically over SSE or WebSocket | **Native** bidirectional streaming is a first-class gRPC feature — the strongest gRPC-specific pull for real-time or high-throughput internal pipelines |

These aren't mutually exclusive. The recurring shape across independent
practitioner writeups (not itself a primary-sourced claim, but a converging
pattern) is a **Backend-for-Frontend layer aggregating over internal REST or
gRPC services**: GraphQL or REST at the edge for client-shaping, gRPC
internally for service-to-service calls. See
[API gateway vs. Backend-for-Frontend](#api-gateway-vs-backend-for-frontend)
below for how a BFF composes with a gateway.

**Default for a new project with no specific driving signal from the table
above: REST.** It's the only one of the three with no added client-tooling
requirement and no N+1/depth-limiting/proxy-translation cost to get right
before shipping.

## Contract-first design

The contract — written by hand, or for a code-first team generated once and
then treated as source of truth going forward — exists *before*
implementation and becomes the shared artifact both server code and
client-generation tooling build from. This is what enables parallel
frontend/backend work against a mock server and automated contract-drift
detection in CI.

**OpenAPI 3.2.0** is the current REST-contract spec. The spec document
itself is dated 19 September 2025 (confirmed by direct fetch of
`spec.openapis.org/oas/v3.2.0.html` — an initial pass surfaced 2025-09-23,
which is the OpenAPI Initiative's own blog *announcement* date, not the spec
document's own date). It's a minor release with an explicitly zero-breaking
migration path from 3.1, adding a richer Tag object (summary/parent/kind,
enabling tag taxonomies), additional supported HTTP methods, and
streaming-media-type support. Most major tooling — see
[preferred-libraries/backend-api-services.md](../preferred-libraries/backend-api-services.md) —
added 3.2 support within two quarters of release.

**AsyncAPI** is the equivalent contract format for event-driven/streaming
surfaces (Kafka, WebSocket, SSE, webhook payload schemas). Current spec
version is **3.1.0**, confirmed by direct fetch of AsyncAPI's own
specification reference page. OpenAPI and AsyncAPI are complementary, not
competing: a service with both a REST surface and a Kafka-consuming pipeline
reasonably maintains one document of each kind.

**protobuf** (`.proto` files) is the contract format for gRPC — Buf is the
current toolchain; see the companion libraries doc.

**Practical default**: generate the OpenAPI/AsyncAPI document from
code-level annotations (FastAPI and NestJS-style frameworks do this
automatically) rather than hand-authoring YAML for a small team — but once
published, treat the generated document as the contract, and validate it in
CI against consumer expectations rather than letting it silently drift.

## API versioning strategy

Three major platforms' own versioning guidance, fetched directly rather than
taken from secondary "URI vs. header" listicles — they genuinely disagree
because they're solving for different consumer populations, not because one
is right and the others are wrong.

| Platform | Strategy (confirmed by direct fetch) | Why it fits their consumer population |
|---|---|---|
| **Google Cloud APIs** (AIP-185) | Major version **only**, in the URL path (`v1`, `v2` — never `v1.4.2`); the stable channel is updated **in place** with backward-compatible changes; alpha/beta channels iterate faster | Google controls or heavily influences most client SDKs it ships alongside the API — in-place evolution is viable because there's no large, uncoordinated third-party client population to break |
| **Stripe** | **Date-named** versions (e.g. `2026-07-29.dahlia`), pinned **per account**; monthly releases within a major name are backward-compatible only; roughly twice a year a new major name starts with breaking changes | Stripe has a massive population of third-party integrators it cannot force to upgrade in lockstep — per-account pinning lets each integrator upgrade on its own schedule while Stripe keeps shipping |
| **Microsoft Azure REST API Guidelines** | Mandatory **`api-version` query parameter**, `YYYY-MM-DD` format, `-preview` suffix for preview releases, required on **every** operation | Enterprise/multi-tenant cloud control-plane APIs need an explicit, machine-checkable version on every single call for auditability and staged rollout — not just a documented default |

Stripe's model is also the clearest real-world example of a **fourth,
separate versioning axis: the header**. Mechanically, Stripe's version rides
in a custom `Stripe-Version` *request header* (with the account's
dashboard-configured default used when the header is omitted) — so Stripe is
simultaneously the date-naming model *and*, underneath that naming scheme,
the header-versioning mechanism. That's worth pulling apart from
URI-path (Google) and query-param (Azure) versioning as its own choice:
header versioning keeps the resource URI clean (arguably the more RESTfully
"pure" option, since the version isn't part of the resource identifier) and
can improve CDN cache-key efficiency versus baking the version into the
cached URL — but it isn't testable directly in a browser address bar,
requires strict gateway/proxy enforcement since intermediate network proxies
have been reported to strip nonstandard custom headers, and is less
discoverable to a developer reading raw request logs than a version sitting
in the URL.

**Decision rule for a new project**, by consumer population:

- **Small number of first-party clients you build and deploy together**
  (mobile app + its own backend, internal services) → evolve in place with
  additive, backward-compatible changes and skip explicit versioning until a
  real breaking change is unavoidable. Google's model, minus the
  multi-channel ceremony most projects don't need.
- **Broad third-party/partner integrator population** you cannot force to
  migrate on your schedule → per-client version pinning. Stripe's model is
  the most battle-tested reference implementation of this.
- **Enterprise/regulated/multi-tenant surface** needing per-call
  auditability → an explicit dated version parameter on every request.
  Azure's model.
- **No-versioning/evolution-only** (additive-only changes, never break a
  field) is a fourth, simpler option worth naming explicitly for
  internal-only APIs with a single consumer. Zero versioning-machinery cost,
  but one hard requirement: it stays viable only as long as every change
  really is additive, which needs the same API-review discipline as any
  versioning scheme — just enforced at design-review time instead of via a
  mechanism.

## Authentication and authorization patterns

This overlaps [architecture-templates.md](../architecture-templates.md)'s
security-touchpoints table (user-facing → OAuth2/OIDC; service-to-service →
mTLS or client-credentials; simple partner integration → API keys). The
API-specific mechanics worth adding:

| Pattern | Fits | Mechanics worth naming |
|---|---|---|
| API keys | Simple partner/internal integrations, low-sensitivity data | A bearer secret, not an identity proof — never the sole factor for anything sensitive; rotate-able, revocable, scoped per key if the platform supports it |
| OAuth 2.0 + OIDC | User-facing apps needing delegated access and identity; the standard when a human is in the loop | OAuth2 is authorization (scopes/delegation); OIDC adds identity (ID tokens) on top of it. Conflating the two is a common design error worth calling out explicitly |
| Client-credentials grant (OAuth2 flow) | Service-to-service where both sides support OAuth infrastructure | No user in the loop; the client authenticates as itself, not on behalf of anyone |
| mTLS | High-trust service-to-service inside a mesh/VPC, financial/zero-trust environments | Verifies identity at the transport layer via certificates on both sides — the strongest machine-identity guarantee of the four, at the operational cost of certificate issuance/rotation infrastructure |

Combined patterns are normal, not exceptional: API key for coarse
application identification plus OAuth for the actual user-authorization
decision; mTLS for service identity plus a JWT carrying user context riding
on top of the mTLS-authenticated channel.

## Rate limiting and throttling

**Algorithm choice**: **token bucket** is the standard choice when
controlled bursts should be allowed — idle capacity accumulates, then a
burst is fine. This is what most production API-gateway rate limiters
implement by default. **Sliding-window counters** are the better fit for the
boundary-burst problem a naive fixed window has (a client sending its full
quota at 11:59:59 and again at 12:00:00 gets 2x its intended rate under a
fixed window) — named here as a fit distinction, not a benchmarked winner,
since the specific comparative numbers found for this pass traced only to
content-aggregator sites without a primary source.

**Response contract**: on a `429`, return `Retry-After` — a real,
long-standing HTTP standard header (RFC 9110 §10.2.3, "Response Context
Fields," confirmed by direct fetch) — telling the client when to retry. The
newer `RateLimit`/`RateLimit-Policy` headers that would standardize exposing
quota/remaining/reset (`draft-ietf-httpapi-ratelimit-headers`) are, per the
IETF datatracker's own page, still an **active Internet-Draft, not yet a
published RFC** (draft -11, dated May 2026, HTTPAPI working group). Many
gateways and frameworks ship their own `X-RateLimit-*` headers in the
meantime; treat the future `RateLimit` header as the direction, not yet a
settled requirement to build against.

**Where to enforce**: at the gateway/edge for coarse per-client/per-IP
protection (cheap, stops abuse before it reaches application code) and
per-route in the application layer for finer business-logic-aware limits
(e.g. "5 password resets per hour per account" isn't expressible as a
generic IP-based gateway rule). These are complementary layers, not a
choice between them.

## API gateway vs. Backend-for-Frontend

[architecture-templates.md](../architecture-templates.md#cross-cutting-network-topology)
covers the base gateway-vs-mesh framing: a north-south gateway is justified
past one externally-facing service; a mesh only past a service-count/
maturity threshold most early projects don't cross. This category adds one
distinction the cross-cutting doc doesn't need: an API **gateway** is one
shared, protocol-level front door (auth, rate limiting, routing) serving all
clients uniformly, while a **BFF** is a per-client-experience backend that
reshapes and aggregates data specifically for one consumer — a web app and a
mobile app each get their own BFF.

The two compose rather than compete: a gateway commonly sits in front of one
or more BFFs, with each BFF calling into the internal services. A recurring,
pragmatic framing worth carrying forward: accept some code duplication
across BFFs as the cost of per-client-team autonomy, rather than trying to
eliminate it via a shared abstraction layer that usually just becomes its
own coupling problem. Specific gateway products and their licensing live in
[preferred-libraries/backend-api-services.md](../preferred-libraries/backend-api-services.md#gateway--proxy).

## Idempotency for mutating endpoints

Anchored on Stripe's documented mechanics — the most complete real-world
reference implementation — with rules specific and load-bearing enough to
carry forward close to verbatim:

An **`Idempotency-Key`** header (client-generated — Stripe suggests a v4
UUID, up to 255 characters, no PII) accompanies a mutating (POST) request.
The server saves the **first** response (status code and body) for that
key, including error responses — a retried request with the same key gets
the *same* stored result rather than re-executing, even if the original
response was a 500. Keys are safe to purge after **at least 24 hours**,
after which reuse starts a fresh request. **Reusing a key with different
request parameters is treated as an error**, not silently accepted — this
is the detail that actually prevents accidental misuse. Results are saved
only once request execution actually begins, so a request that fails
validation before execution starts is safe to retry with the same key.

Azure's guidelines independently converge on the same shape via the OASIS
Repeatable Requests pattern (`Repeatability-Request-ID` plus
`Repeatability-First-Sent` headers, with a tracked window that **must be at
least 5 minutes**). Two major platforms landing on
client-generated-key-plus-stored-result as the pattern is a real,
corroborated convergence, not a single-source claim.

**Practical default**: implement this for every mutating endpoint whose
failure mode includes "network error during an otherwise-successful write."
Payments are the obvious case, but any create-with-side-effects endpoint
qualifies.

## Error-response design

**RFC 7807 was obsoleted by RFC 9457 in July 2023** (confirmed by direct
fetch of `rfc-editor.org/rfc/rfc9457.html`) — cite 9457, not 7807, as the
current standard. RFC 9457 defines a JSON (or XML) object with five standard
members — `type` (a URI identifying the problem type, defaults to
`"about:blank"`), `status`, `title`, `detail`, `instance` — served as
`application/problem+json`, and explicitly permits problem-type-specific
**extension members** beyond those five (clients must ignore unrecognized
ones).

**This is not unanimous industry practice**, and it's worth saying so
plainly rather than presenting 9457 as universally adopted: Microsoft's own
Azure REST API Guidelines (confirmed by direct fetch) deliberately use a
*different*, Azure-specific error envelope — a top-level `error` object with
required `code` and `message` plus optional `target`/`details`/
`innererror`, and a matching `x-ms-error-code` response header — not
`application/problem+json` at all.

**Recommendation for a new project with no existing convention to match**:
RFC 9457 as the default, since it's a real, current IETF standard with
growing framework-level support — many current web frameworks ship a
problem-details response helper. But Azure's dissent is real and deliberate,
not an oversight, and is worth naming explicitly as evidence this is "the
best current default," not "the only conformant choice" — particularly for
a team already integrating tightly with Azure-ecosystem conventions.

## Pagination patterns

| Pattern | Mechanics | Trade-off |
|---|---|---|
| **Offset** (`?page=` / `?offset=&limit=`) | Simplest to implement; lets a client jump to an arbitrary page | Degrades under concurrent writes — records inserted or deleted between page fetches cause skips or duplicates — and gets slower at high offsets on most database engines |
| **Cursor** (an opaque, typically base64-encoded token marking "after this point") | Consistent under concurrent writes, stable performance regardless of how deep into the collection a client pages | No arbitrary jump-to-page-N, and a slightly less intuitive client experience |
| **Keyset** (ordering by an indexed column, e.g. `WHERE id > :last_id ORDER BY id LIMIT :n`) | Effectively cursor pagination's underlying database-query implementation | Not a fourth distinct client-facing pattern — this is how cursor pagination is usually built, not an alternative to it |

**Default**: cursor for any collection endpoint expected to grow large or
see concurrent writes. Offset is acceptable for small, rarely mutated,
admin-only listings where jump-to-page is genuinely useful. Regardless of
which pattern is chosen, always enforce a server-side maximum page size — an
unbounded `limit` parameter is a resource-exhaustion vector.

## Testing approaches specific to APIs

Two philosophically different approaches to contract testing exist, and the
choice depends on what's treated as the source of truth.

**Consumer-driven contract testing** (Pact-style): consumer-side tests
generate a contract from what the consumer actually calls and expects; the
provider verifies against it in CI; a broker mediates publish/verify. This
catches drift between what a consumer *actually needs* and what a provider
*actually returns*, independent of what the OpenAPI doc claims.

**Schema-based / spec-driven contract testing**: the OpenAPI/AsyncAPI
document itself is the contract; tooling checks the live API against the
published spec, and can generate a mock server from the same spec. This
fits a contract-first team whose OpenAPI document is already the deliberate
source of truth, and avoids CDC's broker/publish-verify workflow overhead.

**Property-based/fuzz testing from a schema** (Schemathesis-style —
generates adversarial inputs from the OpenAPI/GraphQL schema itself, and can
chain operations into stateful sequences) is a complementary third layer,
catching schema-violation and crash/500 bugs that example-based tests don't
think to write.

Library names, licenses, and the open-source-broker-vs-commercial-hosting
distinction live in
[preferred-libraries/backend-api-services.md](../preferred-libraries/backend-api-services.md#contract-testing).

## Security concerns specific to this category

The **OWASP API Security Top 10 (2023 edition)** remains the current
authoritative list — confirmed by direct fetch of OWASP's own page, no 2026
revision published — and is API-specific in a way the general OWASP Top 10
isn't:

1. Broken Object Level Authorization (BOLA)
2. Broken Authentication
3. Broken Object Property Level Authorization
4. Unrestricted Resource Consumption
5. Broken Function Level Authorization (BFLA)
6. Unrestricted Access to Sensitive Business Flows
7. Server Side Request Forgery (SSRF)
8. Security Misconfiguration
9. Improper Inventory Management
10. Unsafe Consumption of APIs

**BOLA and BFLA** are the two risks most distinctive to APIs specifically —
an endpoint that correctly authenticates a caller but doesn't check *which*
objects or functions that caller is allowed to touch — and consistently rank
as the most-exploited category across API-security vendor reports. That's
cited here as a directional signal only: specific prevalence percentages
circulating for this claim (e.g. a widely repeated "681% increase in API
attacks" figure) trace to a single security vendor's marketing material and
are excluded rather than repeated as fact.

Other 2023-list items most relevant to a service-oriented backend
specifically: **Unrestricted Resource Consumption** — the
[rate limiting](#rate-limiting-and-throttling) section above is the direct
mitigation; **Improper Inventory Management** — a real risk once an org
accumulates undocumented internal/legacy API versions, and the
[versioning](#api-versioning-strategy) section above is the preventive
practice; and **SSRF** — relevant to any endpoint that fetches a
caller-supplied URL server-side, e.g. webhook registration.

## Where this doc stops

Specific library/framework/gateway/vendor names and their license and
maintenance detail belong entirely to the companion
[preferred-libraries/backend-api-services.md](../preferred-libraries/backend-api-services.md) —
this doc names categories and selection criteria only. Full event-driven/
message-broker architecture (Kafka, RabbitMQ, event-sourcing internals)
belongs to [Integration & Event-Driven Systems](integration-event-driven-systems.md);
this doc only names where an API service's request/response surface
*touches* async patterns. Data-pipeline/analytics-specific API concerns
(bulk export endpoints, streaming-query APIs) belong to
[Data & Analytics Platforms](data-analytics-platforms.md). AI-specific API
concerns (MCP tool schemas, agent-facing endpoint design) belong to
[Agentic & MCP Platforms](agentic-mcp-platforms.md) — that doc covers "an
API an LLM agent calls," this one covers "an API a human-built client or
another conventional service calls." Service-mesh internals and deep
GraphQL federation architecture are named only where they surface a real
trap (see the gateway and licensing sections of the companion libraries
doc) — both are scale-dependent concerns most early projects won't reach.

## Sources

- https://google.aip.dev/185 (AIP-185) — direct fetch: major-version-only-
  in-path rule, explicit "MUST NOT expose minor or patch version numbers,"
  channel-based (alpha/beta/stable) in-place evolution model. Retrieved
  2026-08-19.
- https://google.aip.dev/121 (AIP-121) — resource-oriented design
  (resources as nouns, standard methods as verbs). Retrieved 2026-08-19.
- https://docs.stripe.com/api/versioning — direct fetch: date-named
  versions (current at time of this pass: `2026-07-29.dahlia`), per-account
  pinning, monthly backward-compatible releases vs. roughly semi-annual
  named breaking releases, `Stripe-Version` header mechanism. Retrieved
  2026-08-19.
- https://docs.stripe.com/api/idempotent_requests — direct fetch: full
  idempotency-key mechanics (≥24h retention, same-key-different-params
  error, results saved only after execution begins, POST-only, up to
  255-character keys, no PII). Retrieved 2026-08-19.
- https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md —
  direct fetch: mandatory `api-version` query param (`YYYY-MM-DD` format),
  POST idempotency via OASIS Repeatable Requests
  (`Repeatability-Request-ID`/`Repeatability-First-Sent`, ≥5-minute tracked
  window), `nextLink`-based pagination, Azure-specific (non-RFC-9457) error
  envelope with `x-ms-error-code` header. Retrieved 2026-08-19.
- https://www.rfc-editor.org/rfc/rfc9457.html — direct fetch: confirms RFC
  9457 obsoletes RFC 7807 (July 2023), the five standard problem-details
  members, `application/problem+json`/`+xml` media types, permitted
  extension members. Retrieved 2026-08-19.
- https://spec.openapis.org/oas/v3.2.0.html — direct fetch: confirms the
  spec document itself is dated 19 September 2025, Apache-2.0, OpenAPI
  Initiative. Retrieved 2026-08-19.
- https://www.asyncapi.com/docs/reference/specification/latest — direct
  fetch: confirms the current AsyncAPI specification version is **3.1.0**.
  Retrieved 2026-08-20.
- https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/ —
  direct fetch: confirms `RateLimit`/`RateLimit-Policy` header fields are
  still an active Internet-Draft (version -11, dated May 2026, HTTPAPI
  working group), not yet a published RFC. Retrieved 2026-08-19.
- https://www.rfc-editor.org/rfc/rfc9110.html#name-retry-after — direct
  fetch: confirms `Retry-After` is defined at RFC 9110 §10.2.3 under
  "Response Context Fields." Retrieved 2026-08-19.
- https://github.com/grpc/grpc-web — direct fetch of the official README:
  confirms browsers cannot call a gRPC service directly and require a
  translating proxy (Envoy by default, with Nginx and a dedicated Go proxy
  as alternatives). Also fetched https://grpc.io/docs/platforms/web/basics/
  directly, which documents the same solution without stating the
  underlying browser constraint explicitly. Retrieved 2026-08-19.
- https://medium.com/code-beyond/api-gateway-vs-bff-two-patterns-everyone-confuses-7044f3f32c37
  and https://wundergraph.com/blog/7-key-lessons-i-learned-while-building-bffs —
  API gateway vs. BFF distinction and the "accept BFF duplication as the
  cost of team autonomy" framing. Practitioner sources, corroborating a
  well-established pattern distinction rather than sole basis for it.
  Retrieved 2026-08-19.
- https://konghq.com/blog/enterprise/the-difference-between-api-gateways-and-service-mesh —
  vendor-authored; carried forward for the north-south/east-west framing
  this doc references rather than restates. Retrieved 2026-08-19.
- https://owasp.org/API-Security/editions/2023/en/0x00-header/ — direct
  fetch of OWASP's own page: confirms the 2023 edition and its ten
  categories, no note of a superseding edition. Retrieved 2026-08-20.
