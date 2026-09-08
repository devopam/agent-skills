# Baseline: Backend & API Services — Preferred Libraries
Status: user-approved      Date: 2026-08-19      Snapshot date: 2026-08-19

## Local precedent — none found, confirmed by search

Same conclusion as stack.md: no local repo under `C:\Users\devop\GitHub\*` or
`C:\Users\devop\{LitBot,ucum_check,src}` exposes a REST/GraphQL/gRPC service
(checked directly — no FastAPI/Flask import, no `APIRouter`/route decorator,
no Express `app()` call, no `uvicorn` in any local repo's dependency
manifests or source). Every entry below is externally sourced with a direct
fetch of the repo/package page where practical, not cross-checked against a
local production choice.

## Ecosystem choice

**Python and TypeScript/Node**, per the task's own steer and confirmed still
current rather than assumed: both remain the dominant ecosystems for
service-oriented backends in 2026 search results, and the user's own repos
(MCPg, docker-mcp-registry) are Python/Go-adjacent with no established
non-Python/TS API-service convention to override this default. **Go is
explicitly out of scope as a third ecosystem** despite gRPC tooling below
naming `connect-go`/`buf` generate targets for it — Go shows up only as a
gRPC-codegen target, not as a recommended primary service-framework
ecosystem for this baseline; a Go-specific `libraries.md` pass would need
its own research (Gin/Echo/Chi/connect-go framework comparison) not done
here.

## In scope

### Web/API frameworks — impact: high — depth: table + decision rule

**Python:**

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **FastAPI** (`tiangolo/fastapi`) — **default** | Async-first REST API framework, Pydantic-native, auto-generates OpenAPI | MIT | The 2026 greenfield default: async by design, built-in OpenAPI/JSON-Schema generation from type hints, largest ecosystem of the three Python options here | 2026-08-19 | Direct GitHub fetch: 101.7k stars, 9.8k forks, 7,691 commits on master, active CI |
| Litestar (`litestar-org/litestar`) | More opinionated/batteries-included ASGI framework (DI, built-in caching, less boilerplate than FastAPI for larger apps) | MIT | The fastest-growing ASGI alternative per multiple 2025-2026 comparison sources; reach for it when FastAPI's relative unopinionated-ness has started costing more boilerplate than it saves | 2026-08-19 | Not independently direct-fetched this pass — named via comparison-source corroboration; smaller community than FastAPI, carries real hiring/ecosystem risk worth stating honestly rather than glossing over |
| Django + Django REST Framework | Admin-heavy, relational, CRUD-dominant business applications where the ORM/migrations/admin-panel bundle is itself the value | BSD-3-Clause (Django), BSD (DRF) | Wrong tool for a lean API-only service, right tool when the project genuinely needs Django's batteries (admin UI, auth scaffolding, ORM migrations) alongside the API surface | 2026-08-19 | Not independently direct-fetched this pass; named as the honest "when FastAPI is the wrong choice" answer rather than omitted |

**TypeScript/Node — this is the genuinely contested pick; a decision rule,
not a single winner:**

| Library | For | License | Decision signal | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Hono** | Edge/multi-runtime services (Cloudflare Workers, Deno, Bun, Node) | MIT | Choose when the deployment target plausibly includes an edge/V8-isolate runtime or multi-runtime portability matters — ultra-lightweight, fastest-growing of the three in weekly-download trend | 2026-08-19 | Direct GitHub fetch: 31.7k stars, 1.2k forks, 2,780 commits; direct npm-registry-API fetch: **49.3M weekly downloads** (`hono`, week of 2026-08-09–15) |
| **Fastify** | Node-only services needing a mature plugin ecosystem and schema-based validation baked in | MIT | Choose when the target is Node-only (no edge-runtime requirement) and the project wants a large first-party plugin ecosystem (`@fastify/rate-limit`, `@fastify/cors`, etc.) with native TypeScript support | 2026-08-19 | Direct GitHub fetch: 37k stars, 3k forks, 4,855 commits, 51 open issues; direct npm-registry-API fetch: 10.0M weekly downloads (`fastify`); current major is v5 (v5.8.1 as of this pass, actively patched — a CVE-2026-3419 fix shipped within the v5 line) |
| Express | Maintaining existing Express codebases; broad tutorial/Stack-Overflow-answer coverage | MIT | Not recommended as the default for a **new** service in 2026 — no native TypeScript, no edge-runtime support, and both alternatives above outperform it — named here because it remains, by a wide margin, the most-downloaded Node HTTP framework and many real codebases still run it | 2026-08-19 | Direct npm-registry-API fetch: **109.9M weekly downloads** (`express`) — still the ecosystem's incumbent by raw usage even though it is not the recommendation for new work |

**Decision rule (per this repo's "opinionated default, not a survey"
convention)**: for TypeScript/Node specifically, don't pick one universal
winner — ask "will this ever need to run on an edge/isolate runtime, or
across more than one JS runtime?" Yes → Hono. No, Node-only with a plugin-
ecosystem need → Fastify. Maintaining pre-existing code → Express, not a
choice for new work.

### Schema validation — impact: high — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Pydantic v2** (`pydantic/pydantic`) | Python request/response model validation, native to FastAPI | MIT | Core rewritten in Rust for v2, among the fastest validation libraries in any language per multiple sources; the validation layer FastAPI is built on, not an optional add-on | 2026-08-19 | Direct GitHub fetch: 28.6k stars, 2.9k forks, 5,684 commits, active CI; supports Python 3.9-3.13 |
| **Zod** (`colinhacks/zod`) | TypeScript-first runtime schema validation and static type inference | MIT | The de facto TypeScript validation standard — 2kb gzipped core, zero dependencies, used across API request validation and form validation alike | 2026-08-19 | Direct GitHub fetch: 43.5k stars, 2.1k forks, 3,029 commits; direct npm-registry-API fetch: **224.1M weekly downloads** — reflects Zod's use far beyond API services (forms, config parsing) as well as within them |

### API documentation / schema tooling — impact: med — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| Built-in FastAPI OpenAPI generation | Auto-generated OpenAPI doc (search-corroborated as 3.1.0, not independently direct-fetched from FastAPI's own docs this pass) + interactive Swagger UI/ReDoc from Python type hints | MIT (part of FastAPI) | Zero extra dependency for a FastAPI project — the framework's own default, named first since it needs no separate selection | 2026-08-19 | Covered by FastAPI's own signal above |
| **Scalar** (`scalar/scalar`) | Modern interactive API reference UI + REST client, OpenAPI/Swagger-driven | MIT | Combines Redoc-quality docs with Swagger-UI-style interactive testing in one tool; 40+ framework integrations including FastAPI/Django/Laravel/Spring Boot | 2026-08-19 | Direct GitHub fetch: 15.9k stars, 923 forks, 7,311 commits, active CI |
| **Redocly CLI** (`Redocly/redocly-cli`) | Lint/validate OpenAPI (3.2/3.1/3.0/2.0) and AsyncAPI specs, bundle multi-file specs, generate docs from the terminal/CI; also does TypeScript client generation per its own README | MIT | The strongest CLI-first option for enforcing API governance/linting in CI rather than only rendering docs; supports the current OpenAPI 3.2 spec | 2026-08-19 | Direct GitHub fetch: 1.5k stars, 228 forks, active |
| **OpenAPI Generator** (`OpenAPITools/openapi-generator`) | Generates client SDKs, server stubs, and docs in 30+ languages from an OpenAPI 2/3 spec | Apache-2.0 | The free, self-hosted default for client-SDK generation — no licensing cost, broadest language coverage of any option researched; honest trade-off named explicitly: output quality/idiomaticity is inconsistent across the 30+ generator targets (a 2026 vendor-authored comparison — Speakeasy's own — put it at 4,500+ open issues and generic-feeling generated code versus a commercial tool's more idiomatic output; cited with that vendor-interest caveat, not as neutral fact) | 2026-08-19 | Direct GitHub fetch: 26.7k stars, 7.7k forks |
| Speakeasy (commercial) | Managed/polished client-SDK generation, positioned against OpenAPI Generator on output idiomaticity and support | **Proprietary/commercial** — not open source | Named for completeness and honest comparison against the free default above, not as this baseline's recommendation; the right choice only for a team that wants to pay for generation quality/support rather than accept OpenAPI Generator's rougher edges | 2026-08-19 | Not independently star/adoption-checked this pass — a commercial product without a public repo metric to fetch |

### gRPC / protobuf tooling — impact: med — depth: paragraph

**Buf** (`bufbuild/buf`) is the current standard toolchain for Protobuf and
gRPC: linting, breaking-change detection, and multi-language code
generation (Go, Python, TypeScript, Java, and more via remote plugins) from
a single `.proto` source, plus the Buf Schema Registry for schema publishing
and governance. Apache-2.0. Direct GitHub fetch: 11.4k stars, 366 forks,
2,887 commits, active CI. **Connect** (`connectrpc.com`, `bufbuild/
connect-es` for TypeScript, `connectrpc/connect-py` for Python) is the
companion RPC framework worth naming alongside plain gRPC: it generates
services that work over gRPC, gRPC-Web, *and* a simpler HTTP-based Connect
protocol from the same `.proto` schema — directly relevant to the stack.md
finding that browsers can't speak native gRPC, since Connect is one of the
two standard ways around that constraint (the other being a dedicated
gRPC-Web proxy). Last reviewed 2026-08-19.

### GraphQL server tooling — impact: med — depth: table + licensing trap

**Licensing trap worth a dedicated callout, directly parallel to the
LangGraph/`langgraph-api` trap flagged in the Agentic & MCP Platforms
baseline**: confirmed by direct fetch of `apollographql.com/trust/
licensing` — **Apollo Server** and **Apollo Client** remain MIT-licensed,
and Apollo states it remains committed to keeping them so, but **Apollo
Federation v2.x and later (both the composition libraries and the gateway),
Apollo Router Core (all versions), and the Rover composition add-on are
Elastic License v2 (ELv2)** — not permissive OSS. `@apollo/subgraph`
specifically stays MIT across all Federation versions. A team building a
single GraphQL server has no exposure to this; a team building a
**federated** multi-subgraph GraphQL architecture and assuming "Apollo is
MIT" because Apollo Server is MIT will hit ELv2 the moment Federation 2.x or
the Router enters the dependency tree.

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| Apollo Server | Single-service (non-federated) GraphQL server, largest ecosystem/tooling | MIT | Most widely adopted GraphQL server; safe as long as Federation/Router aren't added | 2026-08-19 | Direct npm-registry-API fetch: 113.0k weekly downloads (`apollo-server`); note Apollo Server 4 reached end-of-life 2026-01-26 per search-corroborated sources — confirm current-major status (Apollo Server 5) before adopting |
| **GraphQL Yoga** (`graphql-hive/graphql-yoga`) | Fully MIT, cross-runtime GraphQL server (Node/Deno/Bun/edge) | MIT (no ELv2 component in this project) | The licensing-clean alternative to the Apollo stack when Federation/Router-level features aren't needed; built on the WHATWG Fetch API so it runs on edge runtimes the same way Hono does | 2026-08-19 | Direct GitHub fetch: 8.5k stars, 595 forks; direct npm-registry-API fetch: 1.1M weekly downloads |

### Gateway / proxy — impact: high — depth: table + licensing/distribution trap

| Library | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Envoy Gateway** (`envoyproxy/gateway`) — **default** | Kubernetes-native (Gateway API) or standalone application gateway: routing, OIDC, rate limiting | Apache-2.0 | CNCF-affiliated (confirmed via repo topics/artwork reference), ships OIDC and rate limiting in the free open-core with no enterprise upsell gate — the cleanest fully-open-source default of the options researched | 2026-08-19 | Direct GitHub fetch: 3.0k stars, 842 forks, 4,879 commits, 649 open issues, active bi-weekly contributor meetings |
| Kong Gateway | API gateway with a large enterprise plugin ecosystem | Apache-2.0 (core license unchanged) | **License and distribution are two separate facts — don't conflate them.** The Apache-2.0 core license itself hasn't changed (confirmed via direct repo fetch). But Kong changed its **distribution/business model** around Gateway 3.10 (officially released 2025-03-27): a direct fetch of Kong's own GitHub discussion thread (`Kong/kong#14405`, on Kong's own org) confirms no prebuilt OSS Docker image for 3.10.0 had been published to Docker Hub as of the thread's most recent activity, multiple community members reporting the open-source prebuilt-image release was effectively discontinued, and **no official Kong-maintainer response** in-thread despite direct appeals — a primary-adjacent confirmation, not just secondary blogs, though still short of an official Kong changelog statement. Secondary sources additionally claim Enterprise's prior no-license "free mode" was removed at the same release — that specific claim remains secondary-sourced only, not found in the Kong-hosted thread itself. The GUI (Kong Manager), advanced analytics, and OIDC plugin remain Enterprise-only per multiple sources. Net effect: still legitimately open-source by license, but meaningfully less turnkey to self-host OSS-only than before 2025 | 2026-08-19 | Direct GitHub fetch: 44k stars, 5.2k forks; distribution-change claim now primary-adjacent-confirmed (Kong's own discussion thread) rather than secondary-only — see Sources |
| Traefik | Simpler ingress/reverse-proxy with automatic service discovery, common in Docker/Kubernetes setups | MIT (core) | Named as a third option for teams wanting the lightest-weight self-hosted gateway rather than Envoy Gateway's full Gateway-API feature set — not independently deep-researched this pass | 2026-08-19 | Not direct-fetched this pass — named via search corroboration only, flagged in Open questions |

### Rate-limiting libraries — impact: med — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **slowapi** (PyPI) | Rate limiting for Starlette/FastAPI, ported from Flask-Limiter | MIT | The standard FastAPI-ecosystem rate-limiter; supports Redis/Memcached/in-memory backends, sync and async endpoints | 2026-08-19 | Direct PyPI fetch: v0.1.10, released 2026-06-13, MIT (OSI-approved), states production use "handling millions of requests monthly" (vendor-stated in own package description, not independently verified) |
| **express-rate-limit** | Rate-limiting middleware for Express | MIT | The standard Express-ecosystem rate limiter; pluggable stores (Redis, Memcached) for multi-instance deployments | 2026-08-19 | Direct GitHub fetch: 3.3k stars, 255 forks; direct npm-registry-API fetch: 39.6M weekly downloads |
| **@fastify/rate-limit** | Official Fastify-ecosystem rate-limiting plugin | MIT | First-party Fastify plugin, consistent with recommending Fastify partly *for* its first-party plugin ecosystem above | 2026-08-19 | Direct npm-registry-API fetch: 1.6M weekly downloads |

### Contract testing — impact: high — depth: table + honest caveat

Two different philosophies, matching the stack.md distinction (consumer-
driven vs. schema-driven):

| Library | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Pact** (`pact-foundation/pact-js` + language-specific implementations) | Consumer-driven contract testing across HTTP and async messaging, polyglot | MIT | The most established CDC framework, multi-language (JS/Python/Java/.NET/Go/Ruby implementations exist under the same Pact Foundation); the right choice when consumer expectations, not the OpenAPI doc, should be the source of truth | 2026-08-19 | Direct GitHub fetch (pact-js specifically): 1.8k stars, 357 forks, 3,431 commits — note this undercounts Pact's real ecosystem signal since adoption is spread across many per-language repos, not concentrated in one; the multi-language spread itself is the better adoption signal than any single repo's star count |
| **Pact Broker** (self-hosted, open source) vs. **PactFlow** (hosted, commercial) | Contract publish/verify coordination between consumer and provider CI pipelines | Pact Broker: open source; PactFlow: commercial SaaS, described by its own vendor as "a managed version of the Open Source Pact Broker" with added SSO/user-management/UI features | Pact requires *some* broker to coordinate publish/verify — a team adopting Pact should decide up front whether self-hosting the OSS broker or paying for PactFlow fits its ops capacity, since this is the practical adoption gate more than the testing library choice itself | 2026-08-19 | Not independently version/star-checked this pass beyond the license/commercial-split confirmation above |
| Specmatic | OpenAPI/AsyncAPI/GraphQL/protobuf-schema-driven contract testing and mock generation — the schema-based alternative to Pact's CDC approach | MIT | Fits a contract-first team whose OpenAPI/AsyncAPI document is already the deliberate source of truth, avoiding Pact's broker/publish-verify workflow entirely | 2026-08-19 | Direct GitHub fetch: only 395 stars — meaningfully smaller adoption footprint than Pact; named as the schema-first alternative on its technical merits, not on adoption evidence, and that gap should be stated plainly rather than glossed over |

### API testing / mocking tools — impact: med — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal (direct-fetch verified) |
|---|---|---|---|---|---|
| **Schemathesis** | Property-based/fuzz testing generated directly from an OpenAPI or GraphQL schema; chains operations into stateful sequences | MIT | Catches schema-violation, crash, and validation-bypass bugs that example-based tests don't think to write; complements rather than replaces contract testing | 2026-08-19 | Direct GitHub fetch: 3.5k stars, 224 forks |
| **Prism** (`stoplightio/prism`) | Turns an OpenAPI/Postman spec into a mock server, plus a validation proxy for contract-testing live traffic against a spec | Apache-2.0 | Useful both for local mock-server development against a not-yet-implemented contract and for validating a live API's real responses against its published spec | 2026-08-19 | Direct GitHub fetch: 5.0k stars, 413 forks; search-confirmed still actively released (CLI v5.16.0, last published within ~24 days of this pass; repo updated 2026-08-13) — worth naming explicitly since some sources questioned its post-SmartBear-acquisition maintenance status and this pass found it still active |
| **MSW** (Mock Service Worker, `mswjs/msw`) | Network-level API mocking for JS/TS — intercepts requests in-browser (Service Worker) and in Node, usable identically in dev, test, and Storybook | MIT | The de facto standard for client-side/frontend-adjacent API mocking in the TS ecosystem; relevant to a backend-services doc specifically for consumer-side contract/integration tests that need to mock an upstream service | 2026-08-19 | Direct GitHub fetch: 18.1k stars, 616 forks |

## Explicitly out of scope

- Go-specific web frameworks (Gin, Echo, Chi, connect-go as a primary
  framework rather than a gRPC-codegen target) — Go named only as a
  gRPC-codegen output language per the Ecosystem-choice section above, not
  researched as a third primary ecosystem this pass.
- Database drivers/ORMs (SQLAlchemy, Prisma, Drizzle, etc.) — a
  data-layer concern downstream of the API-service pattern, not itself an
  API-service library category; likely belongs partly to Data & Analytics
  Platforms and partly to a future cross-cutting persistence doc.
- Message-broker client libraries (kafka-python, amqplib, etc.) — belongs
  to the Integration & Event-Driven Systems baseline.
- Full API-management/monetization SaaS platforms (Apigee, AWS API
  Gateway as a hosted product, Azure API Management) — named only where
  they surfaced as licensing-relevant (none did specifically) — self-hosted
  gateway software is this doc's focus, not hosted API-management SaaS.
- Deep GraphQL federation tooling beyond the licensing callout above
  (subgraph-composition libraries, federation-specific testing tools) — the
  ELv2 trap is flagged as the load-bearing fact; deeper federation-specific
  library research is deferred as a scale-dependent concern.
- Cost/pricing comparisons for any product above (Kong Enterprise/Konnect
  pricing, PactFlow pricing tiers) — license and self-hosting status are
  the durable signal per this repo's established convention; no numeric
  pricing researched.
- `orval` (TypeScript-specific client/hook generator from OpenAPI, popular
  in React/TanStack-Query codebases) — surfaced in search but not
  independently vetted or direct-fetched this pass; OpenAPI Generator and
  Speakeasy above cover the general client-SDK-generation category, orval's
  narrower TS/React-hooks niche is a gap worth a follow-up if that specific
  stack is in play.

## Sources

- https://github.com/tiangolo/fastapi — direct fetch: license, star/fork/
  commit counts — retrieved 2026-08-19
- https://github.com/fastify/fastify — direct fetch: license, star/fork/
  commit/issue counts, current-major signal — retrieved 2026-08-19
- Fastify v5.8.1/CVE-2026-3419 patch recency — search-corroborated via
  releasebot.io and GitHub releases listing, not independently
  direct-fetched from the releases page itself — retrieved 2026-08-19
- https://github.com/honojs/hono — direct fetch: license, star/fork/commit
  counts — retrieved 2026-08-19
- https://api.npmjs.org/downloads/point/last-week/{express,fastify,hono,
  express-rate-limit,zod,@fastify/rate-limit,graphql-yoga,apollo-server} —
  direct npm registry API fetches (not secondary-blog-claimed figures) for
  weekly download counts, week of 2026-08-09–2026-08-15 — retrieved
  2026-08-19
- https://github.com/pydantic/pydantic — direct fetch: license, star/fork/
  commit counts, Python version support — retrieved 2026-08-19
- https://github.com/colinhacks/zod — direct fetch: license, star/fork/
  commit counts — retrieved 2026-08-19
- https://github.com/scalar/scalar — direct fetch: license, star/fork/
  commit counts — retrieved 2026-08-19
- https://github.com/Redocly/redocly-cli — direct fetch: license, star/
  fork counts, OpenAPI 3.2 support confirmation — retrieved 2026-08-19
- https://github.com/bufbuild/buf — direct fetch: license, star/fork/commit
  counts — retrieved 2026-08-19
- https://connectrpc.com/ and https://github.com/connectrpc/connect-py —
  Connect protocol positioning (gRPC/gRPC-Web/Connect from one schema) —
  retrieved 2026-08-19
- https://www.apollographql.com/trust/licensing — direct fetch: exact
  per-package MIT vs. Elastic License v2 split (Apollo Server/Client/
  `@apollo/subgraph` = MIT; Federation v2.x+, Router Core, Rover
  composition add-on = ELv2) — retrieved 2026-08-19
- https://github.com/graphql-hive/graphql-yoga — direct fetch: license,
  star/fork counts — retrieved 2026-08-19
- Apollo Server 4 end-of-life (2026-01-26) — search-corroborated, not
  independently direct-fetched from an Apollo changelog page this pass —
  retrieved 2026-08-19
- https://github.com/envoyproxy/gateway — direct fetch: license, CNCF
  affiliation signal, star/fork/commit/issue counts, contributor-meeting
  cadence — retrieved 2026-08-19
- https://github.com/Kong/kong — direct fetch: license (Apache-2.0), star/
  fork counts; README did not itself mention the 3.10 distribution change
  — retrieved 2026-08-19
- https://github.com/Kong/kong/discussions/14405 — **direct fetch, on Kong's
  own GitHub org** ("Kong OSS container/docker image release for 3.10.0"):
  confirms Kong Gateway 3.10.0 was officially released 2025-03-27 but, as of
  the thread's most recent visible activity (through September 2025), no
  corresponding OSS Docker image had been published to Docker Hub; multiple
  community members report Kong "no longer release[s] the open source
  version" as prebuilt images and note a move to Cloudsmith package hosting
  where the 3.10.0 LTS OSS image was also reportedly unavailable; **the
  thread shows no official Kong-maintainer response** despite direct
  appeals in-thread — this is Kong's own community/support channel, not a
  secondary blog, which upgrades this from a corroborated-only claim to a
  primary-adjacent one, though it remains a community discussion rather
  than an official Kong changelog statement — retrieved 2026-08-19.
  Secondary sources (tasrieit.com, moneyassetlifestyle.com) corroborate the
  same distribution-model shift and additionally claim Enterprise's prior
  no-license "free mode" was removed at the same release — that
  Enterprise-specific claim was not found in the Kong-hosted thread itself
  and remains secondary-sourced only — retrieved 2026-08-19
- https://pypi.org/project/slowapi/ — direct fetch: license, version
  0.1.10, release date 2026-06-13, description — retrieved 2026-08-19
- https://github.com/express-rate-limit/express-rate-limit — direct fetch:
  license, star/fork counts — retrieved 2026-08-19
- https://github.com/pact-foundation/pact-js — direct fetch: license, star/
  fork/commit counts — retrieved 2026-08-19
- https://pactflow.io/oss/ and https://stackshare.io/stackups/pact-vs-pactflow
  — Pact Broker (OSS) vs. PactFlow (commercial, vendor-described as "a
  managed version of the Open Source Pact Broker") distinction — retrieved
  2026-08-19
- https://github.com/specmatic/specmatic — direct fetch: license, star
  count (395) — retrieved 2026-08-19
- https://github.com/schemathesis/schemathesis — direct fetch: license,
  star/fork counts, description — retrieved 2026-08-19
- https://github.com/stoplightio/prism — direct fetch: license, star/fork
  counts; https://www.npmjs.com/package/@stoplight/prism-cli — search-
  corroborated recent release (v5.16.0) and repo-update recency (2026-08-13)
  confirming active maintenance despite some sources questioning
  post-acquisition status — retrieved 2026-08-19
- https://github.com/mswjs/msw — direct fetch: license, star/fork counts,
  description — retrieved 2026-08-19
- https://github.com/OpenAPITools/openapi-generator — direct fetch:
  license (Apache-2.0), star/fork counts, 30+ language coverage — retrieved
  2026-08-19
- https://www.speakeasy.com/blog/comparison-sdk-generators-openapi and
  https://www.speakeasy.com/blog/speakeasy-vs-openapi-generator — vendor-
  authored (Speakeasy sells the commercial alternative) comparison citing
  OpenAPI Generator's 4,500+ open issues and generic-output critique;
  flagged explicitly as vendor-interested content, not neutral — retrieved
  2026-08-19
- Local precedent search (not a web source): same search described in
  stack.md's Local-precedent section — searched 2026-08-19

## Open questions for the user

- Kong's 3.10 OSS-Docker-image discontinuation is now primary-adjacent
  confirmed (Kong's own GitHub discussion thread, `Kong/kong#14405`,
  direct-fetched this pass) rather than secondary-blog-only. The narrower
  Enterprise-"free-mode"-removal claim, however, remains secondary-sourced
  only — it wasn't found in the Kong-hosted thread itself. Should authoring
  do one more direct fetch (Kong's own official changelog or
  `developer.konghq.com/gateway/version-support-policy/`, both surfaced in
  search but not fetched this pass) to close that narrower gap before
  publishing the Enterprise-free-mode claim specifically, or is the
  Docker-image finding alone (which is the more load-bearing "trap" for a
  team evaluating self-hosted OSS Kong) sufficient to publish as-is with the
  free-mode claim kept as a lighter, explicitly secondary-sourced footnote?
- Litestar, Traefik, Pact Broker/PactFlow's own version numbers, and Apollo
  Server 4's exact EOL date were named via search corroboration rather than
  a direct fetch of their own primary page (GitHub repo, official docs, or
  changelog). Per the same Checkpoint-B policy carried over from the
  Agentic & MCP Platforms baseline, should authoring do a direct-fetch pass
  on each before publishing, or is search-corroboration acceptable for
  these lower-impact/supporting entries specifically (as opposed to the
  higher-impact Kong claim above)?
- Should the authored doc name one single opinionated default gateway
  (Envoy Gateway, as this baseline leans toward) or present Envoy Gateway/
  Kong/Traefik as a fuller comparison table given how real and recent the
  Kong distribution-model change is — teams with existing Kong investment
  need the nuance, not just a single recommended alternative.
- The Pact-vs-Specmatic adoption gap (Pact's multi-repo ecosystem vs.
  Specmatic's single 395-star repo) is large enough that recommending both
  as co-equal options may overstate Specmatic's real-world traction.
  Confirm whether the authored doc should name Pact as the clear default
  with Specmatic demoted to "worth knowing about for contract-first teams"
  rather than a parallel table row.

## Resolutions (Checkpoint C review, 2026-08-19)

- **Gateway default**: Envoy Gateway as the named default, full comparison
  table (including the Kong distribution-model finding) kept as backup
  detail — matches the doc-shape convention already set.
- **Contract testing default**: Pact as the clear default; Specmatic
  demoted to "worth knowing about for contract-first teams" rather than a
  parallel table row, given the real adoption gap.
- **Remaining unverified figures** (Litestar/Traefik/Pact Broker version
  numbers, Apollo Server 4 EOL date, Kong's Enterprise-free-mode claim
  specifically): direct-fetch verification deferred to Phase 2 authoring,
  per the standing "verify before publish" policy — applies uniformly, no
  per-item decision needed now.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/backend-api-services.md
  — est. 300–380 lines (9 category tables/sections plus the Apollo/Kong
  licensing-trap callouts, matching the Agentic & MCP Platforms baseline's
  structure and rough length).
