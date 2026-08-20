# Backend & API Services — Preferred Libraries

Companion to [stacks/backend-api-services.md](../stacks/backend-api-services.md),
which covers architecture and selection criteria; this doc names the actual
libraries, their licenses, and honest maintenance/adoption signal. Every
entry below is externally sourced with a direct fetch of the repo, package
registry, or vendor page where practical, rather than drawn from a local
production choice — recommendations here are externally sourced rather than
verified against a worked in-repo example.

## Table of contents

- [Ecosystem choice](#ecosystem-choice)
- [Web/API frameworks](#webapi-frameworks)
- [Schema validation](#schema-validation)
- [API documentation and schema tooling](#api-documentation-and-schema-tooling)
- [gRPC and protobuf tooling](#grpc-and-protobuf-tooling)
- [GraphQL server tooling](#graphql-server-tooling)
- [Gateway / proxy](#gateway--proxy)
- [Rate-limiting libraries](#rate-limiting-libraries)
- [Contract testing](#contract-testing)
- [API testing and mocking tools](#api-testing-and-mocking-tools)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## Ecosystem choice

**Python and TypeScript/Node** are the two ecosystems covered here — both
remain the dominant choice for service-oriented backends. **Go is explicitly
out of scope as a third ecosystem**, despite showing up below as a
code-generation target for gRPC tooling (`connect-go`, `buf generate`
output): a Go-specific pass covering Gin/Echo/Chi/`connect-go` as primary
frameworks would need its own dedicated research, not attempted here.

## Web/API frameworks

**Python:**

| Library | For | License | Why recommended |
|---|---|---|---|
| **FastAPI** (`tiangolo/fastapi`) — default | Async-first REST API framework, Pydantic-native, auto-generates OpenAPI | MIT | The 2026 greenfield default: async by design, built-in OpenAPI/JSON-Schema generation from type hints, and the largest ecosystem of the three Python options here. Direct GitHub fetch: 101.7k stars, 9.8k forks, 7,691 commits on master, active CI |
| Litestar (`litestar-org/litestar`) | More opinionated, batteries-included ASGI framework — DI, built-in caching, less boilerplate than FastAPI for larger apps | MIT | Named, per comparison sources (not independently verified), as a fast-growing ASGI alternative; reach for it once FastAPI's relative unopinionated-ness has started costing more boilerplate than it saves. Direct GitHub fetch: 8.4k stars, 609 forks, latest release `v2.24.0` — a meaningfully smaller community than FastAPI, a real hiring/ecosystem trade-off worth stating rather than glossing over |
| Django + Django REST Framework | Admin-heavy, relational, CRUD-dominant business applications where the ORM/migrations/admin-panel bundle is itself the value | BSD-3-Clause (Django), BSD (DRF) | The wrong tool for a lean API-only service, the right tool when the project genuinely needs Django's batteries (admin UI, auth scaffolding, ORM migrations) alongside the API surface |

**TypeScript/Node — the genuinely contested pick.** Don't name a single
universal winner; ask "will this ever need to run on an edge/isolate
runtime, or across more than one JS runtime?"

| Library | For | License | Decision signal |
|---|---|---|---|
| **Hono** | Edge/multi-runtime services (Cloudflare Workers, Deno, Bun, Node) | MIT | Choose when the deployment target plausibly includes an edge/V8-isolate runtime, or multi-runtime portability matters — ultra-lightweight, the fastest-growing of the three by weekly-download trend. Direct GitHub fetch: 31.7k stars, 1.2k forks, 2,780 commits; direct npm-registry fetch: 49.3M weekly downloads |
| **Fastify** | Node-only services needing a mature plugin ecosystem and schema-based validation baked in | MIT | Choose when the target is Node-only (no edge-runtime requirement) and the project wants a large first-party plugin ecosystem (`@fastify/rate-limit`, `@fastify/cors`, etc.) with native TypeScript support. Direct GitHub fetch: 37k stars, 3k forks, 4,855 commits, 51 open issues; direct npm-registry fetch: 10.0M weekly downloads; current major v5 (v5.8.1 at time of this pass, actively patched — a CVE-2026-3419 fix shipped within the v5 line) |
| Express | Maintaining existing Express codebases; broad tutorial/Stack-Overflow coverage | MIT | Not the default for a **new** service in 2026 — no native TypeScript, no edge-runtime support, and both alternatives above outperform it — but by a wide margin still the most-downloaded Node HTTP framework, and many real codebases still run it. Direct npm-registry fetch: 109.9M weekly downloads |

**Decision rule**: edge/isolate or multi-runtime target → Hono. Node-only
with a plugin-ecosystem need → Fastify. Maintaining pre-existing code →
Express, not a choice for new work.

## Schema validation

| Library | For | License | Why recommended |
|---|---|---|---|
| **Pydantic v2** (`pydantic/pydantic`) | Python request/response model validation, native to FastAPI | MIT | Core rewritten in Rust for v2 — among the fastest validation libraries in any language per multiple sources — and the validation layer FastAPI is built on, not an optional add-on. Direct GitHub fetch: 28.6k stars, 2.9k forks, 5,684 commits, active CI; supports Python 3.9–3.13 |
| **Zod** (`colinhacks/zod`) | TypeScript-first runtime schema validation and static type inference | MIT | The de facto TypeScript validation standard — 2kb gzipped core, zero dependencies, used across API request validation and form validation alike. Direct GitHub fetch: 43.5k stars, 2.1k forks, 3,029 commits; direct npm-registry fetch: 224.1M weekly downloads, reflecting use far beyond API services |

## API documentation and schema tooling

| Library | For | License | Why recommended |
|---|---|---|---|
| Built-in FastAPI OpenAPI generation | Auto-generated OpenAPI doc plus interactive Swagger UI/ReDoc from Python type hints | MIT (part of FastAPI) | Zero extra dependency for a FastAPI project — the framework's own default, and the first thing to reach for since it needs no separate selection |
| **Scalar** (`scalar/scalar`) | Modern interactive API reference UI plus REST client, OpenAPI/Swagger-driven | MIT | Combines Redoc-quality docs with Swagger-UI-style interactive testing in one tool; 40+ framework integrations including FastAPI/Django/Laravel/Spring Boot. Direct GitHub fetch: 15.9k stars, 923 forks, 7,311 commits, active CI |
| **Redocly CLI** (`Redocly/redocly-cli`) | Lint/validate OpenAPI (3.2/3.1/3.0/2.0) and AsyncAPI specs, bundle multi-file specs, generate docs from the terminal/CI | MIT | The strongest CLI-first option for enforcing API governance/linting in CI rather than only rendering docs; supports the current OpenAPI 3.2 spec. Direct GitHub fetch: 1.5k stars, 228 forks, active |
| **OpenAPI Generator** (`OpenAPITools/openapi-generator`) | Generates client SDKs, server stubs, and docs in 30+ languages from an OpenAPI 2/3 spec | Apache-2.0 | The free, self-hosted default for client-SDK generation — no licensing cost, the broadest language coverage of any option researched. Honest trade-off: output quality/idiomaticity is inconsistent across the 30+ generator targets — a 2026 vendor-authored comparison (Speakeasy's own) put it at 4,500+ open issues and generic-feeling generated code versus a commercial tool's more idiomatic output, cited with that vendor-interest caveat, not as neutral fact. Direct GitHub fetch: 26.7k stars, 7.7k forks |
| Speakeasy (commercial) | Managed/polished client-SDK generation, positioned against OpenAPI Generator on output idiomaticity and support | Proprietary — not open source | Named for honest comparison against the free default above, not as this doc's recommendation; the right choice only for a team that wants to pay for generation quality and support rather than accept OpenAPI Generator's rougher edges |

## gRPC and protobuf tooling

**Buf** (`bufbuild/buf`) is the current standard toolchain for protobuf and
gRPC: linting, breaking-change detection, and multi-language code generation
(Go, Python, TypeScript, Java, and more via remote plugins) from a single
`.proto` source, plus the Buf Schema Registry for schema publishing and
governance. Apache-2.0. Direct GitHub fetch: 11.4k stars, 366 forks, 2,887
commits, active CI.

**Connect** (`connectrpc.com`; `bufbuild/connect-es` for TypeScript,
`connectrpc/connect-py` for Python) is the companion RPC framework worth
naming alongside plain gRPC: it generates services that work over gRPC,
gRPC-Web, *and* a simpler HTTP-based Connect protocol from the same `.proto`
schema. This is directly relevant to
[the stack doc's finding that browsers can't speak native gRPC](../stacks/backend-api-services.md#rest-vs-graphql-vs-grpc) —
Connect is one of the two standard ways around that constraint, the other
being a dedicated gRPC-Web proxy.

## GraphQL server tooling

**Licensing trap worth a dedicated callout**, directly parallel to the
LangGraph/`langgraph-api` trap in the Agentic & MCP Platforms companion doc:
confirmed by direct fetch of `apollographql.com/trust/licensing` — **Apollo
Server** and **Apollo Client** remain MIT-licensed, and Apollo states it
remains committed to keeping them so. But **Apollo Federation v2.x and
later (both the composition libraries and the gateway), Apollo Router Core
(all versions), and the Rover composition add-on are Elastic License v2
(ELv2)** — not permissive OSS. `@apollo/subgraph` specifically stays MIT
across all Federation versions. A team building a single GraphQL server has
no exposure to this; a team building a **federated** multi-subgraph GraphQL
architecture and assuming "Apollo is MIT" because Apollo Server is MIT will
hit ELv2 the moment Federation 2.x or the Router enters the dependency tree.

Separately: **Apollo Server 4 reached end-of-life on 2026-01-26**, confirmed
by direct fetch of Apollo's own documentation. Adopt whichever major is
current at build time, not version 4 — this doc doesn't name the current
major number, since that wasn't independently verified this pass and
version numbers move faster than a static doc should assert one.

| Library | For | License | Why recommended |
|---|---|---|---|
| Apollo Server | Single-service (non-federated) GraphQL server, largest ecosystem/tooling | MIT | Most widely adopted GraphQL server, safe as long as Federation/Router aren't added. Direct npm-registry fetch: 113.0k weekly downloads (`apollo-server`) — confirm current-major status before adopting, since 4 is EOL |
| **GraphQL Yoga** (`graphql-hive/graphql-yoga`) | Fully MIT, cross-runtime GraphQL server (Node/Deno/Bun/edge) | MIT (no ELv2 component in this project) | The licensing-clean alternative to the Apollo stack when Federation/Router-level features aren't needed; built on the WHATWG Fetch API, so it runs on edge runtimes the same way Hono does. Direct GitHub fetch: 8.5k stars, 595 forks; direct npm-registry fetch: 1.1M weekly downloads |

## Gateway / proxy

**Envoy Gateway** (`envoyproxy/gateway`) is the default: Apache-2.0,
CNCF-affiliated, ships OIDC and rate limiting in the free open-core with no
enterprise upsell gate — the cleanest fully-open-source default of the
options researched. Direct GitHub fetch: 3.0k stars, 842 forks, 4,879
commits, 649 open issues, active bi-weekly contributor meetings.

| Library | For | License | Why recommended (or not) |
|---|---|---|---|
| **Envoy Gateway** — default | Kubernetes-native (Gateway API) or standalone application gateway: routing, OIDC, rate limiting | Apache-2.0 | See above |
| Kong Gateway | API gateway with a large enterprise plugin ecosystem | Apache-2.0 (core license unchanged) | Still legitimately open-source by license, but meaningfully less turnkey to self-host OSS-only than before 2025 — see the distribution-history note below the table. Direct GitHub fetch: 44k stars, 5.2k forks |
| Traefik | Simpler ingress/reverse-proxy with automatic service discovery, common in Docker/Kubernetes setups | MIT (core) | A third option for teams wanting the lightest-weight self-hosted gateway rather than Envoy Gateway's full Gateway-API feature set — not independently deep-researched to the same depth as Envoy Gateway or Kong. Direct GitHub fetch: 64.5k stars, 6.1k forks, latest release `v3.7.11` (2026-08-19) |

**Kong's license and distribution are two separate facts, confirmed as two
separate changes at two separate releases — don't conflate them or reduce
them to one claim.** (1) At **3.10.0** (released 2025-03-27), Kong's own
GitHub discussion thread (`Kong/kong#14405`, on Kong's own org,
direct-fetched) confirms no prebuilt OSS Docker image had been published to
Docker Hub as of the thread's most recent activity, multiple community
members reporting the open-source prebuilt-image release was effectively
discontinued, and no official Kong-maintainer response in-thread despite
direct appeals — primary-adjacent, not an official changelog statement, but
Kong's own channel. (2) At **3.15.0.0** (released 2026-07-02), Kong's own
official changelog (direct-fetched) confirms a genuinely separate, later
change: without a configured license, the Admin API becomes read-only — the
same behavior Kong already applied once a license's grace period expired —
while the proxy data plane keeps serving already-configured traffic, and a
small set of endpoints stays writable for license recovery. Net effect
across both: control-plane write access is now gated on a license as of
mid-2026, on top of the OSS distribution already having gotten harder to
self-host turnkey since early 2025.

## Rate-limiting libraries

| Library | For | License | Why recommended |
|---|---|---|---|
| **slowapi** (PyPI) | Rate limiting for Starlette/FastAPI, ported from Flask-Limiter | MIT | The standard FastAPI-ecosystem rate limiter; supports Redis/Memcached/in-memory backends, sync and async endpoints. Direct PyPI fetch: v0.1.10, released 2026-06-13 |
| **express-rate-limit** | Rate-limiting middleware for Express | MIT | The standard Express-ecosystem rate limiter; pluggable stores (Redis, Memcached) for multi-instance deployments. Direct GitHub fetch: 3.3k stars, 255 forks; direct npm-registry fetch: 39.6M weekly downloads |
| **@fastify/rate-limit** | Official Fastify-ecosystem rate-limiting plugin | MIT | First-party Fastify plugin, consistent with recommending Fastify partly *for* its first-party plugin ecosystem above. Direct npm-registry fetch: 1.6M weekly downloads |

## Contract testing

Two different philosophies, matching the
[stack doc's consumer-driven vs. schema-driven distinction](../stacks/backend-api-services.md#testing-approaches-specific-to-apis).
**Pact is the clear default** — the most established consumer-driven
contract testing (CDC) framework, multi-language (JS/Python/Java/.NET/Go/
Ruby implementations exist under the same Pact Foundation), and the right
choice when consumer expectations, not the OpenAPI doc, should be the source
of truth.

| Library | For | License | Notes |
|---|---|---|---|
| **Pact** (`pact-foundation/pact-js` + language-specific implementations) — default | Consumer-driven contract testing across HTTP and async messaging, polyglot | MIT | Direct GitHub fetch (pact-js specifically): 1.8k stars, 357 forks, 3,431 commits — this undercounts Pact's real ecosystem signal, since adoption is spread across many per-language repos rather than concentrated in one; the multi-language spread itself is the better adoption signal than any single repo's star count |
| **Pact Broker** (self-hosted) vs. **PactFlow** (hosted, commercial) | Contract publish/verify coordination between consumer and provider CI pipelines | Pact Broker: MIT, open source (direct GitHub fetch: 745 stars, 191 forks, latest release `v2.120.0`); PactFlow: commercial SaaS, described by its own vendor as "a managed version of the Open Source Pact Broker" with added SSO/user-management/UI features | Pact requires *some* broker to coordinate publish/verify — decide up front whether self-hosting the OSS broker or paying for PactFlow fits the project's ops capacity, since this is the practical adoption gate more than the testing library choice itself |

**Specmatic** is worth knowing about for a contract-first team specifically —
schema-driven (OpenAPI/AsyncAPI/GraphQL/protobuf-driven) contract testing
and mock generation, MIT-licensed, avoiding Pact's broker/publish-verify
workflow entirely when the OpenAPI/AsyncAPI document is already the
deliberate source of truth. It's not a parallel option to Pact, though: a
direct GitHub fetch shows only 395 stars against Pact's much broader
multi-repo ecosystem, a real adoption gap worth stating plainly rather than
presenting the two as co-equal.

## API testing and mocking tools

| Library | For | License | Why recommended |
|---|---|---|---|
| **Schemathesis** | Property-based/fuzz testing generated directly from an OpenAPI or GraphQL schema; chains operations into stateful sequences | MIT | Catches schema-violation, crash, and validation-bypass bugs that example-based tests don't think to write; complements rather than replaces contract testing. Direct GitHub fetch: 3.5k stars, 224 forks |
| **Prism** (`stoplightio/prism`) | Turns an OpenAPI/Postman spec into a mock server, plus a validation proxy for contract-testing live traffic against a spec | Apache-2.0 | Useful both for local mock-server development against a not-yet-implemented contract and for validating a live API's real responses against its published spec. Direct GitHub fetch: 5.0k stars, 413 forks; still actively released (CLI v5.16.0, repo updated 2026-08-13, search-corroborated) — worth naming explicitly since some sources questioned its post-SmartBear-acquisition maintenance status and this pass found it active |
| **MSW** (Mock Service Worker, `mswjs/msw`) | Network-level API mocking for JS/TS — intercepts requests in-browser (Service Worker) and in Node, usable identically in dev, test, and Storybook | MIT | The de facto standard for client-side/frontend-adjacent API mocking in the TS ecosystem; relevant here specifically for consumer-side contract/integration tests that need to mock an upstream service. Direct GitHub fetch: 18.1k stars, 616 forks |

## Where this doc stops

Go-specific web frameworks (Gin, Echo, Chi, `connect-go` as a primary
framework rather than a gRPC-codegen target), database drivers/ORMs
(SQLAlchemy, Prisma, Drizzle), message-broker client libraries
(kafka-python, amqplib), and full API-management/monetization SaaS
platforms (Apigee, hosted AWS API Gateway, Azure API Management) are all out
of scope for the same reason: each is either a separate ecosystem this pass
didn't research to the same depth, or belongs to a sibling stack doc
(database drivers to a future persistence doc; message brokers to
Integration & Event-Driven Systems). Deep GraphQL federation tooling beyond
the ELv2 licensing callout above (subgraph-composition libraries,
federation-specific testing tools) is deferred as a scale-dependent concern
most early projects won't reach. No pricing was researched for any product
above — license and self-hosting status are the durable signal this repo's
docs use, not a numeric cost comparison.

## Sources

- https://github.com/tiangolo/fastapi — direct fetch: license, star/fork/
  commit counts. Retrieved 2026-08-19.
- https://github.com/fastify/fastify — direct fetch: license, star/fork/
  commit/issue counts, current-major signal. Retrieved 2026-08-19.
- Fastify v5.8.1 / CVE-2026-3419 patch recency — search-corroborated via
  releasebot.io and the GitHub releases listing, not independently
  direct-fetched from the releases page itself. Retrieved 2026-08-19.
- https://github.com/honojs/hono — direct fetch: license, star/fork/commit
  counts. Retrieved 2026-08-19.
- https://api.npmjs.org/downloads/point/last-week/{express,fastify,hono,
  express-rate-limit,zod,@fastify/rate-limit,graphql-yoga,apollo-server} —
  direct npm registry API fetches for weekly download counts, week of
  2026-08-09–2026-08-15. Retrieved 2026-08-19.
- https://github.com/litestar-org/litestar — direct fetch: license (MIT),
  8.4k stars, 609 forks, latest release `v2.24.0`. Retrieved 2026-08-20.
- https://github.com/pydantic/pydantic — direct fetch: license, star/fork/
  commit counts, Python version support. Retrieved 2026-08-19.
- https://github.com/colinhacks/zod — direct fetch: license, star/fork/
  commit counts. Retrieved 2026-08-19.
- https://github.com/scalar/scalar — direct fetch: license, star/fork/
  commit counts. Retrieved 2026-08-19.
- https://github.com/Redocly/redocly-cli — direct fetch: license, star/
  fork counts, OpenAPI 3.2 support confirmation. Retrieved 2026-08-19.
- https://github.com/bufbuild/buf — direct fetch: license, star/fork/commit
  counts. Retrieved 2026-08-19.
- https://connectrpc.com/ and https://github.com/connectrpc/connect-py —
  Connect protocol positioning (gRPC/gRPC-Web/Connect from one schema).
  Retrieved 2026-08-19.
- https://www.apollographql.com/trust/licensing — direct fetch: exact
  per-package MIT vs. Elastic License v2 split (Apollo Server/Client/
  `@apollo/subgraph` = MIT; Federation v2.x+, Router Core, Rover composition
  add-on = ELv2). Retrieved 2026-08-19.
- https://www.apollographql.com/docs/apollo-server/previous-versions —
  direct fetch: confirms Apollo Server 4 has been end-of-life since
  2026-01-26. Retrieved 2026-08-20.
- https://github.com/graphql-hive/graphql-yoga — direct fetch: license,
  star/fork counts. Retrieved 2026-08-19.
- https://github.com/envoyproxy/gateway — direct fetch: license, CNCF
  affiliation signal, star/fork/commit/issue counts, contributor-meeting
  cadence. Retrieved 2026-08-19.
- https://github.com/Kong/kong — direct fetch: license (Apache-2.0), star/
  fork counts; README does not itself mention the 3.10 distribution
  change. Retrieved 2026-08-19.
- https://github.com/Kong/kong/discussions/14405 — direct fetch, on Kong's
  own GitHub org ("Kong OSS container/docker image release for 3.10.0"):
  confirms Kong Gateway 3.10.0 was officially released 2025-03-27 but, as of
  the thread's most recent visible activity, no corresponding OSS Docker
  image had been published to Docker Hub; multiple community members report
  Kong no longer releasing the open-source version as prebuilt images; the
  thread shows no official Kong-maintainer response despite direct appeals.
  Retrieved 2026-08-19.
- https://developer.konghq.com/gateway/changelog/ — direct fetch of Kong's
  own official changelog: confirms that at **3.15.0.0** (released
  2026-07-02), the Admin API becomes read-only without a configured
  license — a separate, later, and more precisely scoped change than the
  3.10 Docker-image finding above, and one this pass could confirm from
  Kong's own primary source rather than secondary-only corroboration.
  Retrieved 2026-08-20.
- https://github.com/traefik/traefik — direct fetch: license (MIT), 64.5k
  stars, 6.1k forks, latest release `v3.7.11` (2026-08-19). Retrieved
  2026-08-20.
- https://pypi.org/project/slowapi/ — direct fetch: license, version
  0.1.10, release date 2026-06-13, description. Retrieved 2026-08-19.
- https://github.com/express-rate-limit/express-rate-limit — direct fetch:
  license, star/fork counts. Retrieved 2026-08-19.
- https://github.com/pact-foundation/pact-js — direct fetch: license, star/
  fork/commit counts. Retrieved 2026-08-19.
- https://github.com/pact-foundation/pact_broker — direct fetch: license
  (MIT), 745 stars, 191 forks, latest release `v2.120.0`. Retrieved
  2026-08-20.
- https://pactflow.io/oss/ and https://stackshare.io/stackups/pact-vs-pactflow —
  Pact Broker (OSS) vs. PactFlow (commercial, vendor-described as "a
  managed version of the Open Source Pact Broker") distinction. Retrieved
  2026-08-19.
- https://github.com/specmatic/specmatic — direct fetch: license, star
  count (395). Retrieved 2026-08-19.
- https://github.com/schemathesis/schemathesis — direct fetch: license,
  star/fork counts, description. Retrieved 2026-08-19.
- https://github.com/stoplightio/prism — direct fetch: license, star/fork
  counts; https://www.npmjs.com/package/@stoplight/prism-cli —
  search-corroborated recent release (v5.16.0) and repo-update recency
  confirming active maintenance despite some sources questioning
  post-acquisition status. Retrieved 2026-08-19.
- https://github.com/mswjs/msw — direct fetch: license, star/fork counts,
  description. Retrieved 2026-08-19.
- https://github.com/OpenAPITools/openapi-generator — direct fetch:
  license (Apache-2.0), star/fork counts, 30+ language coverage. Retrieved
  2026-08-19.
- https://www.speakeasy.com/blog/comparison-sdk-generators-openapi and
  https://www.speakeasy.com/blog/speakeasy-vs-openapi-generator —
  vendor-authored (Speakeasy sells the commercial alternative) comparison
  citing OpenAPI Generator's 4,500+ open issues and generic-output
  critique; flagged explicitly as vendor-interested content, not neutral.
  Retrieved 2026-08-19.
