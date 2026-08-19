# Baseline: Backend & API Services — Architecture & Stack
Status: user-approved      Date: 2026-08-19

## Local precedent — none found, confirmed by search

Unlike Agentic & MCP Platforms (which had MCPg as a real production worked
example), no local repo exposes a general REST/GraphQL/gRPC service. Checked
directly this pass: `C:\Users\devop\GitHub\MCPg` (MCP-shaped, already the
subject of the other baseline), `C:\Users\devop\GitHub\docker-mcp-registry`,
`C:\Users\devop\GitHub\MEDGraph`, `C:\Users\devop\LitBot` (a CLI chatbot —
`main.py`/`chatbot.py`, no FastAPI/Flask import, no route decorators, no
`uvicorn`), `C:\Users\devop\ucum_check` (a CLI unit-conversion tool, no web
framework), and `C:\Users\devop\src` (two small imaging libraries, not
services). None expose an HTTP API surface. This confirms the task's framing
that this category is closer to greenfield than Agentic & MCP Platforms —
every recommendation below is backed by external primary sources with direct
fetches, not a local worked example, and the doc says so rather than forcing
a weak analogy.

## In scope

- **How this category specializes the cross-cutting architecture-templates.md
  pattern catalog** — impact: high — depth: section. A backend/API service is
  the clearest home for **hexagonal (ports & adapters)** among the 7
  cross-cutting patterns: the inbound port is the HTTP/gRPC/GraphQL handler,
  the outbound adapters are the database/cache/downstream-API clients, and
  domain logic in between should not know which protocol served the request
  — this is the same reasoning the Agentic & MCP Platforms baseline used for
  MCP servers, and it applies more broadly to any "service that other things
  call." **Modular monolith is the honest default starting point** for a new
  API service (per the cross-cutting doc's monolith-first heuristic) — one
  deployable, internally separated by domain module, each module already
  hexagonal-shaped internally so a future extraction is a deployment change,
  not a redesign. **Microservices** are justified only once independent
  team ownership or independent scaling/deployment cadence is a real,
  present constraint — not a default for "an API service" as a category.
  **CQRS/event sourcing** stays rarely-justified per the cross-cutting doc's
  caution, with one narrower exception worth naming here: an API service
  whose read traffic and write traffic have genuinely disparate shape
  (high-fanout reads, rare complex writes) is the one scenario Fowler
  himself calls out as legitimate. **Event-driven** is an overlay, not a
  replacement, for the request/response API surface — webhooks (outbound),
  async job kickoff (a mutating endpoint enqueues work and returns 202 +
  a status URL rather than blocking), and integration fan-out are the
  concrete places it attaches to an API service; full coverage of
  event-driven architecture itself belongs to the separate Integration &
  Event-Driven Systems baseline. **Serverless** is a deployment-axis fit
  for API services with spiky/low/unpredictable traffic and mostly-stateless
  handlers (the 2026-07-28 MCP statelessness shift the sibling baseline
  covers is one instance of a broader "stateless HTTP handlers deploy
  cleanly to serverless" pattern); it's a poor fit once handlers need
  long-lived connections (WebSocket/gRPC streaming) or consistent low-latency
  warm state.

- **REST vs. GraphQL vs. gRPC — selection by hard constraint, not borrowed
  benchmark** — impact: high — depth: table. Vendor/aggregator "40-45% of
  teams," "4-10x faster," "pays off at 5+ services" style figures turned up
  repeatedly in this category's search results (apiscout.dev,
  digitalapplied.com, and similar SEO-aggregator sites) with no primary
  source behind them — excluded from this baseline as unverifiable
  fake-precision. The durable, checkable discriminators instead:
  | Signal | REST | GraphQL | gRPC |
  |---|---|---|---|
  | Browser-callable directly | Yes | Yes (over HTTP POST) | **No** — confirmed by direct fetch of the official `grpc/grpc-web` repo: "gRPC-Web clients connect to gRPC services via a special proxy; by default, gRPC-Web uses Envoy" as the bridge, with Nginx and a dedicated Go proxy as alternatives; the repo's own docs stop short of spelling out *why* (browsers' fetch/XHR stack doesn't support the HTTP/2-trailers mechanism gRPC's wire format depends on), but the practical fact — no direct browser-to-gRPC-server call, a translating proxy is required — is confirmed from the primary source, not assumed |
  | HTTP-layer cacheability | Yes — GET is cacheable by CDNs/proxies by default | **No** — queries are POST-based by default, defeating standard HTTP caching; needs persisted-queries/APQ workarounds | N/A — not HTTP-cache-shaped traffic |
  | Client population | Best fit for public/third-party APIs — universal tooling, curl-able, self-documenting via OpenAPI | Best fit when many heterogeneous clients (web, mobile, partner) need to shape their own response and over/under-fetching from a fixed REST shape is a real, measured pain point | Best fit for internal service-to-service calls where both ends are code you control and can regenerate from a shared `.proto` |
  | Known operational cost | Versioning discipline (see below) | N+1 query risk requires DataLoader/batching; unbounded query depth/complexity requires cost limits before public exposure | Proto schema evolution discipline; no ad-hoc browser debugging |
  | Streaming | Polling or SSE bolted on | Subscriptions (typically over SSE or WebSocket) | **Native** bidirectional streaming is a first-class gRPC feature — the strongest gRPC-specific pull for real-time/high-throughput internal pipelines |
  These are not mutually exclusive: the recurring 2026 shape in practitioner
  writeups (surfaced across multiple, independent sources, though this
  particular aggregate framing is not itself a primary source) is a
  **Backend-for-Frontend layer aggregating over internal REST or gRPC
  services** — GraphQL/REST at the edge for client-shaping, gRPC internally
  for service-to-service. Default recommendation for a new project without
  a specific driving signal from the table above: **REST**, because it is
  the only one of the three with no added client-tooling requirement and no
  N+1/depth-limiting/proxy-translation cost to get right before shipping.

- **Contract-first design (OpenAPI / AsyncAPI / protobuf-driven
  development)** — impact: high — depth: section. The contract is written
  (or, for a code-first team, generated and then treated as source of truth
  going forward) *before* implementation and becomes the shared artifact
  both server and client-generation tooling build from — this is what
  enables parallel frontend/backend work against a mock server and
  automated contract-drift detection in CI. **OpenAPI 3.2.0** — the spec
  document itself is dated **19 September 2025** (confirmed by direct fetch
  of `spec.openapis.org/oas/v3.2.0.html`; an initial search pass had also
  surfaced 2025-09-23, which belongs to the OpenAPI Initiative's own blog
  *announcement* post about the release, not the spec document's own date —
  resolved by going to the primary document rather than leaving the
  discrepancy unaddressed) — is the current REST-contract spec —
  a minor release with an explicitly zero-breaking migration path from 3.1,
  adding a richer Tag object (summary/parent/kind, enabling tag taxonomies),
  additional supported HTTP methods, and streaming-media-type support; most
  major tooling (see libraries.md) added 3.2 support within two quarters of
  release. **AsyncAPI** is the equivalent contract format for event-driven/
  streaming surfaces (Kafka, WebSocket, SSE, webhook payload schemas) —
  the two specs are complementary, not competing: a service with both a
  REST surface and a Kafka-consuming pipeline reasonably maintains one
  document of each kind. **protobuf** (`.proto` files) is the contract
  format for gRPC — see libraries.md for the current toolchain (Buf).
  Practical default: generate the OpenAPI/AsyncAPI document from
  code-level annotations (FastAPI and NestJS-style frameworks do this
  automatically; see libraries.md) rather than hand-authoring YAML for a
  small team, but treat the generated document as the contract once
  published — validate it in CI against consumer expectations rather than
  letting it silently drift.

- **API versioning strategy — three real primary-source answers, chosen by
  consumer population, not one universal rule** — impact: high — depth:
  table + decision rule. This baseline fetched three different major
  platforms' own versioning guidance directly rather than relying on
  secondary "URI vs header" listicles, and they genuinely disagree because
  they're solving for different consumer populations:
  | Platform | Strategy (confirmed by direct fetch) | Why it fits their consumer population |
  |---|---|---|
  | Google Cloud APIs (AIP-185) | Major version **only**, in the URL path (`v1`, `v2` — never `v1.4.2`); stable channel updated **in place** with backward-compatible changes; alpha/beta channels iterate faster | Google controls or heavily influences most client SDKs it ships alongside the API — in-place evolution is viable because there's no large uncoordinated third-party client population to break |
  | Stripe | **Date-named** versions (e.g. `2026-07-29.dahlia`), pinned **per account**; monthly releases within a major name are backward-compatible only; roughly twice a year a new major name starts with breaking changes; client SDKs (`stripe-python`, `stripe-node`, etc.) pin to the version current at their own release | Stripe has a massive population of third-party integrators it cannot force to upgrade in lockstep — per-account pinning lets each integrator upgrade on their own schedule while Stripe keeps shipping |
  | Microsoft Azure REST API Guidelines | Mandatory **`api-version` query parameter**, `YYYY-MM-DD` format, `-preview` suffix for preview releases, required on **every** operation | Enterprise/multi-tenant cloud control-plane APIs need an explicit, machine-checkable version on every single call for auditability and staged rollout, not just a documented default |
  **Header versioning as its own axis, separate from the three real
  platforms above**: Stripe's version is technically carried in a custom
  `Stripe-Version` **request header** (with the account's dashboard-
  configured default used when the header is omitted) — so Stripe is, in
  mechanism, the header-versioning model, layered underneath its
  date-naming/pinning policy. This is worth separating from URI-path
  (Google) and query-param (Azure) versioning as a distinct fourth
  mechanism, since header versioning carries its own independent trade-offs
  regardless of which naming scheme rides on top of it: it keeps the
  resource URI clean (arguably the more RESTfully "pure" choice, since the
  version isn't part of the resource identifier) and can improve CDN
  cache-key efficiency versus baking the version into the cached URL — but
  it isn't testable directly in a browser address bar, requires strict
  gateway/proxy enforcement since intermediate network proxies have been
  reported to strip nonstandard custom headers, and is less discoverable to
  a developer just reading request logs than a version sitting in the URL.
  **Decision rule for a new project**: small number of first-party clients
  you build and deploy together (mobile app + its own backend, internal
  services) → evolve in place with additive, backward-compatible changes
  and skip explicit versioning until a real breaking change is unavoidable
  (Google's model, minus the multi-channel ceremony most projects don't
  need). Broad third-party/partner integrator population you cannot force
  to migrate on your schedule → per-client version pinning, Stripe's model
  is the most battle-tested reference implementation of this. Enterprise/
  regulated/multi-tenant surface needing per-call auditability → explicit
  dated version parameter on every request, Azure's model. **No-versioning/
  evolution-only** (additive-only changes, never break a field) is a fourth,
  simpler option worth naming explicitly for internal-only APIs with a
  single consumer — it has zero versioning machinery cost but a hard
  requirement: it only stays viable as long as every change really is
  additive, which needs the same API-review discipline as any versioning
  scheme, just enforced at design-review time instead of via a mechanism.

- **Authentication/authorization patterns for APIs** — impact: high — depth:
  table. This overlaps the cross-cutting architecture-templates.md security
  touchpoint (user-facing → OAuth2/OIDC; service-to-service → mTLS or
  client-credentials; simple partner integration → API keys) — this section
  adds the API-specific mechanics:
  | Pattern | Fits | Mechanics worth naming |
  |---|---|---|
  | API keys | Simple partner/internal integrations, low-sensitivity data | A bearer secret, not an identity proof — never the sole factor for anything sensitive (cross-cutting doc's existing caution); rotate-able, revocable, scoped per key if the platform supports it |
  | OAuth 2.0 + OIDC | User-facing apps needing delegated access and identity; the standard when a human is in the loop | OAuth2 is authorization (scopes/delegation), OIDC adds identity (ID tokens) on top of it — conflating the two is a common design error worth calling out explicitly |
  | Client-credentials grant (OAuth2 flow) | Service-to-service where both sides support OAuth infrastructure | No user in the loop; the client authenticates as itself, not on behalf of anyone |
  | mTLS | High-trust service-to-service inside a mesh/VPC, financial/zero-trust environments | Verifies identity at the transport layer via certificates on both sides — strongest machine-identity guarantee of the four, at the operational cost of certificate issuance/rotation infrastructure |
  Combined patterns are normal, not exceptional: API key for coarse
  application identification + OAuth for the actual user-authorization
  decision; mTLS for service identity + a JWT carrying user context riding
  on top of the mTLS-authenticated channel.

- **Rate limiting / throttling** — impact: high — depth: section. Algorithm
  choice: **token bucket** is the standard choice when controlled bursts
  should be allowed (idle accumulates capacity, then a burst is fine) —
  this is what most production API-gateway rate limiters implement by
  default. **Sliding-window counters** are the better fit for smoothing the
  boundary-burst problem fixed windows have (a client sending its full quota
  at 11:59:59 and again at 12:00:00 gets 2x its intended rate under a naive
  fixed window) — named as a fit distinction, not a benchmarked winner,
  since the specific comparative numbers found in search results this pass
  traced to content-aggregator sites without a primary source and are
  excluded per this baseline's own no-unverified-numbers standard.
  **Response contract**: on a 429, return `Retry-After` (a long-standing,
  actual HTTP standard header — confirmed by direct fetch of
  `rfc-editor.org/rfc/rfc9110.html`, RFC 9110 §10.2.3, "Response Context
  Fields") telling the client when to retry. The newer `RateLimit`/
  `RateLimit-Policy` headers
  (`draft-ietf-httpapi-ratelimit-headers`) that would standardize exposing
  quota/remaining/reset — confirmed by direct fetch of the IETF datatracker
  — are **still an active Internet-Draft, not yet a published RFC**, as of
  this pass (draft -11, dated May 2026, HTTPAPI working group); many
  gateways/frameworks ship their own `X-RateLimit-*` headers in the
  meantime, and the authored doc should present the future `RateLimit`
  header as the direction, not yet a settled requirement to build against.
  **Where to enforce**: at the gateway/edge for coarse per-client/per-IP
  protection (cheap, stops abuse before it reaches application code) and
  per-route in the application layer for finer business-logic-aware limits
  (e.g. "5 password resets per hour per account" isn't expressible as a
  generic IP-based gateway rule) — these are complementary layers, not a
  choice between them.

- **API gateway architecture — and how it differs from a Backend-for-
  Frontend** — impact: high — depth: paragraph, pointing to the
  cross-cutting doc for the base gateway-vs-mesh framing (north-south
  gateway justified past 1 externally-facing service; mesh only past a
  service-count/maturity threshold most early projects don't cross). This
  category adds one distinction the cross-cutting doc doesn't cover: an API
  **gateway** is one shared, protocol-level front door (auth, rate limiting,
  routing) serving all clients uniformly, while a **BFF** is a
  per-client-experience backend that reshapes/aggregates data specifically
  for one consumer (web app vs. mobile app each get their own BFF). The two
  compose rather than compete — a gateway commonly sits in front of one or
  more BFFs, each BFF calling into the internal services. A recurring,
  pragmatic 2026 framing worth carrying into the authored doc: accept some
  code duplication across BFFs as the cost of per-client-team autonomy
  rather than trying to eliminate it via a shared abstraction layer that
  usually just becomes its own coupling problem. Specific gateway
  products/licensing land in libraries.md, not here.

- **Idempotency for mutating endpoints** — impact: high — depth: section,
  anchored on Stripe's documented mechanics (`docs.stripe.com/api/
  idempotent_requests`, direct fetch) as the most complete real-world
  reference implementation. Concrete rules worth carrying into the authored
  doc verbatim, since they're specific and load-bearing: an
  **`Idempotency-Key`** header (client-generated, Stripe suggests a v4 UUID,
  up to 255 characters, no PII) accompanies a mutating (POST) request; the
  server saves the **first** response (status code + body) for that key,
  including error responses — a retried request with the same key gets the
  *same* stored result rather than re-executing, even if the original was a
  500; keys are safe to purge after **at least 24 hours**, after which reuse
  starts a fresh request; **reusing a key with different request parameters
  is treated as an error**, not silently accepted, which is the detail that
  actually prevents accidental misuse; results are saved only once request
  execution actually begins — a request that fails validation before
  execution starts is safe to retry with the same key. Azure's guidelines
  independently converge on the same shape via the OASIS Repeatable
  Requests pattern (`Repeatability-Request-ID` + `Repeatability-First-Sent`
  headers, with a tracked window that **must be at least 5 minutes**) —
  two major platforms landing on client-generated-key-plus-stored-result as
  the pattern is a real, corroborated convergence, not a single-source
  claim. Practical default: implement this for every mutating endpoint
  whose failure mode includes "network error during an otherwise-successful
  write" — payments are the obvious case, but any create-with-side-effects
  endpoint qualifies.

- **Error-response design — a correction to the task's own framing, stated
  explicitly** — impact: high — depth: section. The task prompt names
  "RFC 7807 Problem Details or equivalent" — **RFC 7807 was obsoleted by
  RFC 9457 in July 2023** (confirmed by direct fetch of
  `rfc-editor.org/rfc/rfc9457.html`), so the authored doc should cite 9457,
  not 7807, as the current standard. RFC 9457 defines a JSON (or XML) object
  with five standard members — `type` (a URI identifying the problem type,
  defaults to `"about:blank"`), `status`, `title`, `detail`, `instance` —
  served as `application/problem+json`, and explicitly permits
  problem-type-specific **extension members** beyond those five (clients
  must ignore unrecognized ones). **This is not unanimous industry
  practice, and the authored doc should say so rather than presenting 9457
  as universally adopted**: Microsoft's own Azure REST API Guidelines
  (confirmed by direct fetch) deliberately use a *different*, Azure-specific
  error envelope — a top-level `error` object with required `code` and
  `message` plus optional `target`/`details`/`innererror`, and a matching
  `x-ms-error-code` response header — not `application/problem+json` at
  all. Recommendation for a new project without an existing convention to
  match: RFC 9457 as the default, since it's a real, current IETF standard
  with growing framework-level support (many current web frameworks ship a
  problem-details response helper) — but name Azure's dissent explicitly as
  evidence this is "the best current default," not "the only conformant
  choice," particularly for a team already integrating tightly with
  Azure-ecosystem conventions.

- **Pagination patterns** — impact: med — depth: table. **Offset** (`?page=`
  / `?offset=&limit=`): simplest to implement, lets a client jump to an
  arbitrary page, but degrades under concurrent writes (records inserted/
  deleted between page fetches cause skips or duplicates) and gets slower
  at high offsets on most database engines. **Cursor** (an opaque token,
  typically base64-encoded, marking "after this point"): consistent under
  concurrent writes, stable performance regardless of how deep into the
  collection a client pages, the recommended default for any public or
  high-scale/high-write-concurrency collection endpoint — the trade-off is
  no arbitrary jump-to-page-N and a slightly less intuitive client
  experience. **Keyset** pagination (ordering by an indexed column, e.g.
  `WHERE id > :last_id ORDER BY id LIMIT :n`) is effectively cursor
  pagination's underlying database-query implementation rather than a
  fourth distinct client-facing pattern. Default recommendation: cursor for
  any collection endpoint expected to grow large or see concurrent writes;
  offset is acceptable for small, rarely-mutated, admin-only listings where
  jump-to-page is genuinely useful. Always enforce a server-side maximum
  page size regardless of which pattern is chosen — an unbounded `limit`
  parameter is a resource-exhaustion vector.

- **Testing approaches specific to APIs** — impact: high — depth: table.
  Two philosophically different approaches to contract testing exist, and
  the choice depends on what's treated as the source of truth: **consumer-
  driven contract testing** (Pact-style — consumer-side tests generate a
  contract from what the consumer actually calls and expects, the provider
  verifies against it in CI, a broker mediates publish/verify) catches
  drift between what a consumer *actually needs* and what a provider
  *actually returns*, independent of what the OpenAPI doc claims. **Schema-
  based / spec-driven contract testing** (Specmatic-, Dredd-, Prism-style —
  the OpenAPI/AsyncAPI document itself is the contract; tooling checks the
  live API against the published spec, and can generate a mock server from
  the same spec) fits a contract-first team whose OpenAPI document is
  already the deliberate source of truth, and avoids CDC's broker/
  publish-verify workflow overhead. Property-based/fuzz testing from a
  schema (Schemathesis-style — generates adversarial inputs from the
  OpenAPI/GraphQL schema itself, chains operations into stateful sequences)
  is a complementary third layer catching schema-violation and
  crash/500 bugs that example-based tests don't think to write. Library
  names, licenses, and the Pact-Broker-vs-PactFlow (open vs. commercial)
  distinction live in libraries.md.

- **Security concerns specific to this category** — impact: high — depth:
  list, pointing to the canonical source rather than restating it in full.
  The **OWASP API Security Top 10 (2023 edition)** remains the current
  authoritative list as of this pass (confirmed via search — no 2026
  revision has been published) and is API-specific in a way the general
  OWASP Top 10 isn't: Broken Object Level Authorization (BOLA) and Broken
  Function Level Authorization (BFLA) are the two risks most distinctive to
  APIs specifically (a REST/GraphQL/gRPC endpoint that correctly
  authenticates a caller but doesn't check *which* objects/functions that
  caller is allowed to touch) and consistently rank as the most-exploited
  category across API-security vendor reports — cited here as a directional
  signal only, since the specific prevalence percentages found in search
  results this pass (e.g. a widely-repeated "681% increase in API attacks"
  figure) trace to a single security vendor's marketing material and are
  excluded rather than repeated as fact. Other 2023-list items relevant to
  a service-oriented backend specifically: Unrestricted Resource
  Consumption (the rate-limiting section above is the direct mitigation),
  Improper Inventory Management (a real risk once an org accumulates
  undocumented internal/legacy API versions — the versioning-strategy
  section above is the preventive practice), and SSRF (relevant to any
  endpoint that fetches a caller-supplied URL server-side, e.g. webhook
  registration).

## Explicitly out of scope

- Specific library/framework/gateway/vendor names and their license/
  maintenance detail — belongs entirely to the companion `libraries.md`
  baseline; this doc names categories and selection criteria only.
- Full event-driven/message-broker architecture (Kafka, RabbitMQ, event
  sourcing internals) — belongs to the separate Integration & Event-Driven
  Systems stack baseline; this doc only names where an API service's
  request/response surface *touches* async patterns (webhooks, 202+status
  polling).
- Data-pipeline/analytics-specific API concerns (bulk export endpoints,
  streaming-query APIs) — belongs to Data & Analytics Platforms.
- AI-specific API concerns (MCP tool schemas, agent-facing endpoint design)
  — belongs to Agentic & MCP Platforms; this doc covers "an API a human-built
  client or another conventional service calls," not "an API an LLM agent
  calls," though the two overlap in mechanics (both are HTTP services) more
  than in decision criteria.
- Service mesh internals (mTLS rotation mechanics, traffic-shifting/canary
  routing at the mesh layer) — the cross-cutting doc already places mesh
  adoption behind a maturity threshold most projects don't cross; deep mesh
  configuration is out of scope for the same reason.
- Deep GraphQL federation architecture (subgraph composition, gateway
  routing rules) — named as a licensing trap in libraries.md (Apollo
  Federation 2.x / Router = Elastic License v2) but not researched at
  architectural depth, since it's a scale-dependent concern most early
  projects won't reach.
- Cost modeling / cloud pricing comparisons for gateway or API-management
  SaaS products — same no-pricing convention as the cross-cutting doc and
  the Agentic & MCP Platforms baseline.
- Numeric performance-benchmark claims (throughput multipliers, latency
  percentiles) not traceable to a primary source — several were found in
  search results this pass and deliberately excluded; see the REST/GraphQL/
  gRPC and rate-limiting sections above for the explicit calls-out.

## Sources

- https://docs.cloud.google.com/apis/design/versioning (redirects to
  https://google.aip.dev/185) — AIP-185, direct fetch: major-version-only-
  in-path rule, explicit "MUST NOT expose minor or patch version numbers,"
  channel-based (alpha/beta/stable) in-place evolution model — retrieved
  2026-08-19
- https://github.com/aip-dev/google.aip.dev/blob/master/aip/general/0121.md
  and https://google.aip.dev/121 — AIP-121 resource-oriented design
  (resources as nouns, standard methods as verbs) — retrieved 2026-08-19
- https://docs.stripe.com/api/versioning — direct fetch: date-named
  versions (current at time of this pass: 2026-07-29.dahlia), per-account
  pinning, monthly backward-compatible releases vs. ~semi-annual named
  breaking releases, SDK-pins-to-release-time-version behavior across all
  seven language SDKs — retrieved 2026-08-19
- https://docs.stripe.com/api/idempotent_requests — direct fetch: full
  idempotency-key mechanics (≥24h retention, same-key-different-params
  error, results saved only after execution begins, POST-only, up to
  255-character keys, no PII) — retrieved 2026-08-19
- https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md
  — direct fetch: mandatory `api-version` query param (`YYYY-MM-DD`
  format), POST idempotency via OASIS Repeatable Requests
  (`Repeatability-Request-ID`/`Repeatability-First-Sent`, ≥5-minute tracked
  window), `nextLink`-based pagination, Azure-specific (non-RFC-9457) error
  envelope with `x-ms-error-code` header — retrieved 2026-08-19
- https://www.rfc-editor.org/rfc/rfc9457.html — direct fetch: confirms RFC
  9457 obsoletes RFC 7807 (July 2023), the five standard problem-details
  members, `application/problem+json`/`+xml` media types, permitted
  extension members — retrieved 2026-08-19
- https://spec.openapis.org/oas/v3.2.0.html — direct fetch: confirms the
  spec document itself is dated **19 September 2025**, Apache-2.0, OpenAPI
  Initiative — retrieved 2026-08-19. (The 2025-09-23-dated
  `openapis.org/blog/2025/09/23/announcing-openapi-v3-2` announcement post,
  surfaced via search only, is the source of the alternate date found
  initially — resolved in favor of the direct-fetched spec document's own
  date; the announcement post's zero-breaking-migration/Tag-object/
  streaming-media-type content claims are search-corroborated, not
  independently re-verified against the spec body this pass.)
- https://www.asyncapi.com/blog/openapi-vs-asyncapi-burning-questions and
  https://www.asyncapi.com/docs/tutorials/getting-started/coming-from-openapi
  — AsyncAPI's scope relative to OpenAPI (event-driven/streaming transports:
  Kafka, MQTT, WebSocket, SSE) — retrieved 2026-08-19; **note**: AsyncAPI's
  own current spec-version number was not independently direct-fetched this
  pass, flagged in Open questions
- https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/ —
  direct fetch of the IETF datatracker page: confirms `RateLimit`/
  `RateLimit-Policy` header fields are still an active Internet-Draft
  (version -11, dated May 2026, HTTPAPI working group), not yet a published
  RFC — retrieved 2026-08-19
- https://www.rfc-editor.org/rfc/rfc9110.html#name-retry-after — direct
  fetch: confirms `Retry-After` is defined at RFC 9110 §10.2.3 under
  "Response Context Fields" — retrieved 2026-08-19
- https://github.com/grpc/grpc-web — direct fetch of the official
  `grpc/grpc-web` repo README: confirms browsers cannot call a gRPC service
  directly and require a translating proxy (Envoy by default, with Nginx
  and a dedicated Go proxy as alternatives); the README does not itself
  spell out the underlying HTTP/2-trailers/fetch-API mechanism, only the
  practical proxy requirement, which is the fact this baseline's table
  relies on — retrieved 2026-08-19. Also fetched
  https://grpc.io/docs/platforms/web/basics/ directly, which likewise
  documents the gRPC-Web solution without stating the underlying browser
  constraint explicitly — retrieved 2026-08-19
- https://medium.com/code-beyond/api-gateway-vs-bff-two-patterns-everyone-confuses-7044f3f32c37
  and https://wundergraph.com/blog/7-key-lessons-i-learned-while-building-bffs
  — API gateway vs. BFF distinction and the "accept BFF duplication as the
  cost of team autonomy" framing — retrieved 2026-08-19 (practitioner
  sources, corroborating rather than sole basis for a well-established
  pattern distinction)
- https://konghq.com/blog/enterprise/the-difference-between-api-gateways-and-service-mesh
  — carried forward from the cross-cutting baseline (vendor-authored,
  flagged there) for the north-south/east-west framing this doc references
  rather than restates — retrieved 2026-08-19 (prior pass)
- OWASP API Security Top 10 — search-confirmed that the 2023 edition
  (BOLA/Broken Authentication/BOPLA/Unrestricted Resource Consumption/
  BFLA/Unrestricted Access to Sensitive Business Flows/SSRF/Security
  Misconfiguration/Improper Inventory Management/Unsafe Consumption of
  APIs) remains current as of this pass, no 2026 revision published —
  retrieved 2026-08-19; the OWASP source itself
  (owasp.org/API-Security/editions/2023/en/0x00-header/) was not
  independently direct-fetched this pass, flagged in Open questions
- Local precedent search (not a web source): direct directory/grep search
  across `C:\Users\devop\GitHub\*` and `C:\Users\devop\{LitBot,ucum_check,
  src}` for FastAPI/Flask/Express/APIRouter usage — none found; see "Local
  precedent" section above — searched 2026-08-19

## Open questions for the user

- The REST-vs-GraphQL-vs-gRPC section deliberately excluded several
  specific numeric claims (adoption percentages, performance multipliers)
  found in search results because they traced only to SEO-aggregator sites
  with no identifiable primary source, per the standard this research is
  held to. Confirm that a hard-constraint table (browser-callability,
  cacheability, streaming) without those numbers is the right shape for the
  authored doc, versus finding better-sourced numbers before authoring (a
  gRPC/REST throughput comparison from a primary engineering blog, e.g. a
  named company's own benchmark, may exist but wasn't located this pass).
- AsyncAPI's own current spec-version number wasn't independently direct-
  fetched this pass (only referenced via secondary comparison sources) —
  worth a one-fetch confirmation at authoring time given how load-bearing
  the OpenAPI-version fact-check turned out to be for this doc's other
  corrections.
- The OWASP API Security Top 10 (2023) itself wasn't direct-fetched this
  pass (confirmed current via search corroboration only) — a direct fetch
  of owasp.org's own page would strengthen this section's citation before
  authoring, especially since it's flagged as impact: high.
- The RFC 9457-vs-Azure-error-envelope divergence is presented as "9457 as
  default, Azure as a named dissent" — confirm that's the right
  prescriptiveness level, or whether the authored doc should instead treat
  this as a genuinely open choice with no default (matching how
  architecture-templates.md stayed pattern-neutral on some axes) given that
  a real major platform doesn't follow 9457.
- The versioning section's three-model framing (Google/Stripe/Azure by
  consumer population) is this baseline's strongest synthesis — confirm
  it's the right level of prescriptiveness (naming a decision rule) versus
  presenting the three models side-by-side and leaving the choice fully to
  the project's own Q&A answers.
- Event-driven overlay patterns (webhooks, 202+polling) are named only in
  passing here since full event-driven architecture is the sibling
  Integration & Event-Driven Systems baseline's job — confirm that division
  point is correct, i.e. this doc should describe webhook *design*
  (delivery, retries, signature verification) at all, or defer that
  entirely to the sibling doc too.

## Resolutions (Checkpoint C review, 2026-08-19)

- **Error-response default**: RFC 9457 as the recommended default, with
  Azure's real, deliberate divergence named explicitly rather than
  presenting this as a fully open choice.
- **Versioning prescriptiveness**: keep the consumer-population decision
  rule (few first-party clients → evolve in place; broad third-party →
  per-client pinning like Stripe; regulated/enterprise → explicit dated
  version like Azure) — matches the opinionated-default convention.
- **AsyncAPI spec version / OWASP API Top 10**: direct-fetch verification
  deferred to Phase 2 authoring, per the standing "verify before publish"
  policy established in Checkpoint B — not a decision needed now.
- **Event-driven overlay scope**: keep only the brief webhook/202-polling
  mention here; full webhook delivery/retry/signature-verification
  mechanics belong to the sibling Integration & Event-Driven Systems
  baseline (Checkpoint D) — avoids duplicating content across categories.

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/backend-api-services.md —
  est. 480–560 lines (12 subsections per the In-scope list above, several as
  tables given the versioning/protocol-selection/auth/idempotency sections'
  density; roughly matches the Agentic & MCP Platforms baseline's actual
  length).
