# Agentic & MCP Platforms — Architecture & Stack

This category covers two overlapping things: building an **MCP server**
(exposing tools/resources/prompts over the Model Context Protocol) and
building the **agent/orchestrator** that consumes tools, MCP or otherwise.
Several sections below apply to only one half — each says so explicitly, so
an MCP-server-only builder can skip the agent-backend material and vice
versa.

**Worked example used throughout**: `MCPg` — a production, single-process
async Python MCP server exposing 254 tools over a PostgreSQL backend. It is
one real data point, not the sole source; external research is cited
alongside it, and every place MCPg's own choices diverge from current
best practice is called out honestly rather than smoothed over.

## Table of contents

- [The default pattern: hexagonal (ports & adapters)](#the-default-pattern-hexagonal-ports--adapters)
- [The 2026-07-28 stateless spec revision](#the-2026-07-28-stateless-spec-revision)
- [Transport choice: stdio vs. Streamable HTTP vs. SSE](#transport-choice-stdio-vs-streamable-http-vs-sse)
- [Auth models](#auth-models)
- [Tool, resource, and prompt schema design](#tool-resource-and-prompt-schema-design)
- [Context and memory architecture for agent backends](#context-and-memory-architecture-for-agent-backends)
- [Model-switching and provider-abstraction patterns](#model-switching-and-provider-abstraction-patterns)
- [Framework vs. raw SDK: when orchestration is warranted](#framework-vs-raw-sdk-when-orchestration-is-warranted)
- [Testing harnesses for agentic systems](#testing-harnesses-for-agentic-systems)
- [Deployment models](#deployment-models)
- [Security: tool poisoning and the server-side enforcement boundary](#security-tool-poisoning-and-the-server-side-enforcement-boundary)
- [Observability architecture pattern](#observability-architecture-pattern)
- [Agent-to-agent protocols: a brief note](#agent-to-agent-protocols-a-brief-note)
- [Sources](#sources)

## The default pattern: hexagonal (ports & adapters)

**Hexagonal (ports & adapters) is the recommended default structural
pattern for MCP-server backends.** MCP servers are naturally hexagonal
whether or not anyone names it that way: the protocol itself *is* the
inbound port, and every wrapped external system — database, API,
filesystem — is an outbound adapter. The domain logic in between should
not know, or care, that it's being called over MCP rather than any other
transport.

MCPg's request lifecycle is this shape in practice, with no ADR ever
naming "hexagonal" explicitly: `AuditedMCPServer` (transport/protocol
adapter) → a tool wrapper (the port, translating MCP calls into typed
Python calls) → a logic module (the domain) → a composable driver stack
(`SafeSqlDriver` → `RoutedSqlDriver` → `TenantSqlDriver`, each an adapter
decorating the next) → a `psycopg3` connection pool (the outbound adapter
to PostgreSQL). Nothing in the logic modules imports anything MCP-specific
— they'd work identically behind a REST endpoint or a CLI.

That reasoning is also the boundary for when hexagonal *isn't* earned:

- **Layered/n-tier** fits small, single-tool servers where the ceremony of
  explicit ports isn't paying for itself yet — a handful of tools with one
  real dependency don't need a formal port/adapter split to stay testable.
- **Microservices** fit only past a genuine multi-team or multi-domain
  boundary. Splitting tool families across processes is rarely justified
  below that line — MCPg keeps all 254 tools in one process precisely
  because there's no organizational boundary demanding otherwise.
- **Event-driven overlays** fit the notification / async-tool-result side
  of an MCP server (the protocol's own `notifications/*` messages, and
  patterns like MCPg's LISTEN/NOTIFY-to-tool-poll bridge in `mcpg.listen`)
  more than they replace the core request/response tool-call path itself.
- **CQRS/event sourcing** is rarely justified for a tool-serving backend,
  for the same reason the cross-cutting architecture doc gives generally:
  most tool servers don't have the read/write asymmetry or audit-trail
  requirement that earns the added complexity.
- **Serverless** is a live, spec-endorsed option specifically *because* of
  the stateless spec revision below — but it's a runtime-target choice
  that composes with hexagonal, not a competing structural pattern. See
  [Deployment models](#deployment-models) for the language-runtime caveat
  that actually gates it.

## The 2026-07-28 stateless spec revision

This is the single most consequential recent architecture fact for this
category. As of the **2026-07-28** MCP specification (release candidate
locked 2026-05-21, final published 2026-07-28), the protocol removed the
`initialize`/`notifications/initialized` handshake and the
`Mcp-Session-Id` header from Streamable HTTP. Every request now carries
its protocol version and capabilities inline; `tools/list`,
`resources/list`, and `prompts/list` no longer vary per-connection; and
any server that genuinely needs cross-call state must mint an explicit
handle, passed as an ordinary tool argument, rather than leaning on
transport-level session state.

The practical consequence: a spec-compliant MCP server becomes an ordinary
HTTP workload. Any request can land on any instance behind a plain
round-robin load balancer, which is what makes serverless/edge deployment
and trivial horizontal scaling viable in the first place.

**Treat this as the direction the ecosystem is moving, not yet as
something every client already speaks.** The spec finalized only about
three weeks before 2026-08-19 — SDK and client
adoption lags the spec by design, and a hard "always build stateless"
mandate would be premature. A new project starting today should default
to the stateless request model from the outset; an existing project isn't
wrong to still be migrating.

**MCPg divergence, noted honestly**: MCPg's ADR-0002 and its
`http_runtime` module predate this change and are built against the
2025-06-18-era transport model — `streamable-http` / `sse` selected by
environment variable, OIDC/bearer auth, a per-request `X-MCPG-Role`
header. That's not a mistake for a project that started before mid-2026;
it's exactly the kind of divergence this doc flags rather than assumes is
wrong. A new project starting today, with no legacy session-era code to
carry forward, should default to the stateless model rather than
reproduce MCPg's pattern.

## Transport choice: stdio vs. Streamable HTTP vs. SSE

| Transport | Fit | Notes |
|---|---|---|
| **stdio** | Local subprocess, one client per server instance, desktop-integrated servers (Claude Desktop, Cursor, local dev) | Zero network exposure. Cannot serve multiple remote clients — this is the hard limit that forces a move to HTTP once a server needs to be shared. |
| **Streamable HTTP** | Remote/multi-client servers | Current standard: a single endpoint supporting POST+GET, with optional SSE-style streaming of individual responses. This replaced the older dedicated SSE transport and is the default choice for anything not purely local. |
| **Plain SSE (legacy)** | Backward compatibility with older clients that predate Streamable HTTP | Deprecated in the 2025-06-18 spec revision. MCPg still offers it as a selectable transport specifically for this reason — a legitimate compatibility trade-off, not an oversight. Broad-compatibility-vs.-latest-spec is a real axis projects choose along, not a mistake to be corrected on sight. |

## Auth models

The spec's own model (2025-06-18 onward) casts the MCP server as an OAuth
2.1 **resource server**, not an authorization server. A compliant server
implementing OAuth MUST support OAuth 2.0 Protected Resource Metadata (RFC
9728) so clients can discover the associated authorization server, and
clients MUST use RFC 8707 Resource Indicators so a malicious server can't
obtain a token scoped more broadly than the client intended. Authorization
itself is spec-optional, but standardized when a server chooses to
implement it.

For simpler or internal deployments, a static bearer token or API key is a
legitimate, lighter-weight alternative to full OAuth — MCPg's
`MCPG_HTTP_AUTH_TOKEN` constant-time-compare option is a concrete instance.
The trade-off is real in both directions: a shared secret means
client-management overhead (rotate and distribute it yourself) in exchange
for avoiding OAuth's setup cost; OAuth buys per-user delegation and an
audit trail in exchange for that setup cost. Neither is a "correct"
default independent of deployment context.

MCPg's pattern worth carrying forward regardless of which auth model is
chosen: **layer a role-propagation concern on top of authentication as a
separate step**, not folded into the same gate. Its `X-MCPG-Role` header
(or, in OIDC deployments, a role claim from the token) is read by a
`TenantSqlDriver` to scope the connection. Authentication answers "who is
this," authorization-scope answers "what can they touch on this specific
call" — treating them as one gate conflates two concerns that change on
different schedules.

## Tool, resource, and prompt schema design

Current (2026) guidance converges on a short, concrete checklist:

- **Be verbose in the tool description, concise in parameter names and
  types.** The description drives tool selection and argument generation
  — that's model-facing prose, and it earns detail. Parameter names/types
  are machine-readable structure, not model guidance — keep them precise
  rather than padded.
- **Use the 2025-03-26+ tool annotations** — `readOnlyHint`,
  `destructiveHint`, `idempotentHint`, `openWorldHint` — to declare
  behavioral properties so clients and agents can reason about risk
  *before* calling a tool, not just interpret the result after.
- **Keep each tool's input schema narrow and single-purpose.** One
  mega-tool with many optional modes is harder for a model to select and
  argue correctly than several small, unambiguous tools.
- **Measure tool-selection accuracy empirically, not by inspection.** The
  informally cited bar: run 20–50 test prompts against the tool surface
  and treat anything under 95% straightforward-query accuracy as a signal
  to rename or re-describe the offending tool — not as a signal to add
  more tools or more description text on top of what's already confusing
  the model.

MCPg's concrete instance of "generated beats hand-maintained" for this
concern: its tool surface is pinned by a contract-test snapshot
(`tests/contract/tool_surface.snapshot.json`) that fails CI on any
undocumented name/description/schema drift. That's a reusable pattern for
any MCP server with a nontrivial tool count — schema drift is otherwise
the kind of thing that only gets noticed once a client breaks in
production.

## Context and memory architecture for agent backends

**This section serves the agent-backend half of the category, not the
MCP-server half.** MCPg itself is a stateless tool provider with no agent
memory of its own — memory belongs to whatever agent or client calls it.
An MCP-server-only builder can skip this section.

Three recurring patterns, roughly in order of operational maturity:

1. **Monolithic/in-context** — everything lives in the prompt, zero extra
   infrastructure. Fine for short-lived, single-session agents; degrades
   via context-window pressure and summarization drift as sessions
   lengthen.
2. **Context + external retrieval store** — working memory stays in the
   context window; long-term facts/episodes live in an external store
   (vector DB, SQL, file) fetched on demand.
3. **Tiered/hierarchical memory** — a hot layer of recent turns verbatim
   plus compressed/summarized historical layers, often with a controller
   deciding what gets promoted or evicted.

**Default to (1)** for short-lived agent runs; move to (2) or (3) only
once a session's expected length or a real persistence requirement
demands it. This is the same "complexity, not size, is the trigger" theme
that governs the structural-pattern decision in the cross-cutting
architecture doc — building tiered memory ahead of an actual
context-pressure problem is solving a problem you don't have yet.

## Model-switching and provider-abstraction patterns

Two shapes are in current use:

- **In-process abstraction library** — call any of 100+ providers through
  one interface inside your own service (e.g. LiteLLM). Simpler for a
  single service; the natural default.
- **Network-level gateway/proxy** — route, fail over, and cache at the
  HTTP layer, in front of one or more services (e.g. Vercel AI Gateway).
  Earns its keep once several services or agents need centralized cost
  tracking, rate limiting, or automatic provider failover that a
  per-service library can't coordinate.

This is fundamentally a library-selection question rather than an
architecture-pattern one — full detail, including specific libraries and
their licenses, lives in the companion
[`preferred-libraries` doc](../preferred-libraries/agentic-mcp-platforms.md)
for this category. This section exists only to name the two shapes and
when each is warranted.

## Framework vs. raw SDK: when orchestration is warranted

This is the most important honesty check in the category, and it splits
cleanly into two different answers depending on which side of the
category you're building.

**Building an MCP server**: use the official/community MCP SDK directly
(or a thin ergonomic wrapper like FastMCP). A general agent-orchestration
framework — LangGraph, CrewAI, and similar — solves a different problem
(multi-step reasoning/orchestration on the *client* side) and adds
complexity an MCP server doesn't need. The server's job is exposing typed
tools and resources, not reasoning about what to do with them. MCPg's own
production choice agrees: no agent-orchestration framework anywhere in its
dependency tree.

**Building the agent that consumes tools** (including MCP tools): a
framework earns its cost once the orchestration itself is genuinely
nontrivial — multi-agent handoffs, durable/resumable long-running
workflows, human-in-the-loop approval steps. For a single linear
tool-use loop, a framework is often genuine overhead, and a raw provider
SDK loop is the better-regarded current advice. State this two-sided
answer plainly rather than defaulting to "use a framework" — the honest
default for most single-agent products is *not* a framework until a
specific orchestration need shows up.

## Testing harnesses for agentic systems

Current (2026) convergence describes a layered model:

1. **Unit tests with the LLM call mocked/injected** — deterministic, fast,
   verify prompt construction, tool-argument-schema matching, and output
   parsing without hitting a real model.
2. **Tool-routing tests** — fixed prompt in, assert the expected tool and
   correctly-shaped arguments were selected, including malformed-output
   and LLM-failure edge cases.
3. **Protocol-level integration tests** against a real (or containerized)
   MCP server, using the MCP Inspector's scriptable CLI/TUI modes for
   CI-friendly automated checks.
4. **Contract/snapshot tests** pinning the tool surface and return shapes
   against regressions. MCPg's two-snapshot pattern —
   `test_tool_surface_snapshot.py` for names/descriptions/schemas, plus an
   AST-derived snapshot for return-shape fields — is a concrete, reusable
   instance of this layer.

Specific tool names for each layer (which eval framework, which tracing
library) live in the companion
[`preferred-libraries` doc](../preferred-libraries/agentic-mcp-platforms.md)
— this section covers the shape of the harness, not the vendor choice.

## Deployment models

| Model | Fit | Notes |
|---|---|---|
| **Local/stdio-subprocess** | Desktop integration — Claude Desktop, Cursor, IDE-embedded | No network exposure, one client per process. |
| **Long-running containerized HTTP service** | Stateful drivers, connection pools, or heavier runtimes that don't map cleanly to edge isolates | MCPg's model: a hardened multi-stage Docker image, non-root `uid=10001`/`gid=10001`, read-only application files. |
| **Serverless/edge** | Enabled architecturally by the 2026-07-28 stateless spec revision | Real language-runtime constraint: V8-isolate platforms (Cloudflare Workers) run JS/TS natively with millisecond cold starts, while Python frameworks like FastMCP are reported by practitioners as a poor fit there. Container-based serverless (Lambda, Vercel Functions) supports Python, but with slower cold starts than a V8 isolate. |
| **VPS/self-hosted** | Full control, no serverless transport restrictions | Same container in dev and prod; the fallback when neither of the above fits the deployment constraint. |

Publishing/discoverability is a related but distinct concern from where
the server *runs*: the official MCP Registry (minimal, canonical,
`server.json` + `mcp-publisher publish`) versus discovery layers like
Smithery, Glama, or PulseMCP that add search/curation on top. MCPg ships
to PyPI, GHCR, the MCP registry, Smithery, and an HF Spaces demo
simultaneously — these are complementary distribution channels, not
competing choices; there's no reason to pick just one.

## Security: tool poisoning and the server-side enforcement boundary

The dominant 2026 MCP-specific threat is **tool poisoning**: malicious
instructions embedded in a tool's *description* or metadata field — an
attack surface the model reads and may follow, even though the user only
sees a benign-looking label. This is distinct from classic prompt
injection via tool *output*, though both exploit the same trust boundary
(the model treating server-supplied text as instructions).

Reported prevalence figures from 2026 scans are cited here with an
explicit caveat: these are single-source, vendor-published statistics, not
independently reproduced findings — command-injection patterns showed up
in a meaningful share of tested servers, and SSRF/path-traversal exposure
was tied specifically to file-operation and network-fetching tools. Treat
the qualitative threat pattern as solid; treat any specific percentage as
a single vendor's snapshot.

MCPg's concrete mitigations are worth citing as a reusable pattern:

- A **capability/access-mode policy gate** (`read-only` / `restricted` /
  `unrestricted`), with higher-blast-radius capabilities like `DDL` /
  `SHELL` / `LISTEN` requiring their own additional opt-in environment
  variable, that determines which tools are even *registered* for a given
  deployment — not just which are callable at runtime.
- A **first-party SQL-safety kernel** that parses and allowlists
  agent-supplied SQL before execution, instead of trusting the model's
  output directly.
- **Identifier validation via regex** everywhere a user- or
  model-supplied name reaches SQL.

The general principle behind all three: **the server, not the model, must
be the enforcement boundary for anything destructive.** Annotations like
`destructiveHint` inform the *client's* UX — they are not a security
control the server can rely on, because nothing forces a client to honor
them.

## Observability architecture pattern

The recurring shape is one span per tool call, with span status
(OK/ERROR) plus structured attributes: tool name, argument *count* rather
than raw argument values (to avoid leaking secrets/PII into a trace
backend), and error type/message. MCPg's `otel_tracing.py` is a concrete
instance of this shape, using its own `mcp.tool.*` attribute namespace.

**Divergence worth naming honestly**: the OpenTelemetry GenAI semantic
conventions (`gen_ai.*` namespace, covering agent/workflow/tool/model
spans) are the emerging standardized alternative — but as of this doc's
of v1.41 (May 2026), they remain in **Development** stability status,
meaning attribute names can still change without a major-version bump.
MCPg's choice to define its own small, stable attribute set instead of
adopting an actively-churning standard is a defensible engineering
trade-off, not an oversight. Present both options with this stability
caveat rather than unconditionally recommending the standard — build
alerting or dashboards on `gen_ai.*` attribute names only with the
understanding that they may move under you before they stabilize.

## Agent-to-agent protocols: a brief note

Agent-to-agent (A2A) protocols exist and address a genuinely different
problem than MCP: peer coordination between agents, rather than an
agent's access to tools. MCP is this category's anchor protocol for tool
access; A2A-style peer coordination is related but meaningfully less
mature as of 2026-08-19, and is intentionally not covered in depth here.
If a project's design genuinely needs agent-to-agent
coordination rather than tool access, treat that as a separate research
question, not an extension of the MCP guidance above.

## Sources

- MCP specification changelog, 2025-06-18 —
  https://modelcontextprotocol.io/specification/2025-06-18/changelog —
  OAuth Resource Server classification, RFC 8707 Resource Indicators
  requirement, `MCP-Protocol-Version` header requirement. Retrieved
  2026-08-19.
- MCP blog, 2026-07-28 spec announcement —
  https://blog.modelcontextprotocol.io/posts/2026-07-28/ and the
  release-candidate post — stateless protocol core, removal of the init
  handshake and `Mcp-Session-Id` header, RC locked 2026-05-21, final
  published 2026-07-28. Retrieved 2026-08-19.
- MCP specification changelog, 2026-07-28 —
  https://modelcontextprotocol.io/specification/2026-07-28/changelog —
  official changelog for the stateless-era spec. Retrieved 2026-08-19.
- MCP specification, transports (2025-03-26) —
  https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
  — stdio and then-current SSE/HTTP transport definitions. Retrieved
  2026-08-19.
- MCP specification, authorization (draft) —
  https://modelcontextprotocol.io/specification/draft/basic/authorization
  — OAuth 2.1 resource-server model, RFC 9728, RFC 8707. Retrieved
  2026-08-19.
- Descope, "The MCP Authorization Spec" —
  https://www.descope.com/blog/post/mcp-auth-spec — secondary corroboration
  of the resource-server framing. Retrieved 2026-08-19.
- Kansei Link, "MCP Tool Schema Design Guide 2026" —
  https://kansei-link.com/en/insights/mcp-tool-schema-design-guide-2026.html
  — description-verbosity vs. parameter-concision guidance, annotations
  vocabulary, the 95%-accuracy testing bar. Retrieved 2026-08-19.
- ExplainX, "Tool Definition Schema Design" —
  https://www.explainx.ai/blog/tool-definition-schema-design-context-engineering-2026
  — corroborating schema-design guidance. Retrieved 2026-08-19.
- Wavect, "MCP Stateless Server Migration 2026" —
  https://wavect.io/blog/mcp-stateless-server-migration-2026/ and Fast.io,
  "Building Stateful MCP Servers" —
  https://fast.io/resources/building-stateful-mcp-servers/ — the
  "default-to-stateless, use explicit handles for real state" guidance.
  Retrieved 2026-08-19.
- Atlan, "Agent Memory Architectures" —
  https://atlan.com/know/agent-memory-architectures/ — the
  monolithic/context+retrieval/tiered pattern set. Retrieved 2026-08-19.
- AgentMarketCap, "Agent Context Engineering" —
  https://agentmarketcap.ai/blog/2026/04/11/agent-context-engineering-sliding-windows-memory-2026
  — corroborating tiered-memory patterns for long-running agents.
  Retrieved 2026-08-19.
- Nerova, "Claude Agent SDK vs. LangGraph" —
  https://nerova.ai/comparisons/claude-agent-sdk-vs-langgraph-2026 and
  Developers Digest, same comparison —
  https://www.developersdigest.tech/blog/claude-agent-sdk-vs-langgraph —
  framework-vs-raw-SDK positioning. Retrieved 2026-08-19.
- iamraghuveer.com, "Unit Testing Custom Agents" —
  https://www.iamraghuveer.com/posts/unit-testing-custom-agents/ and
  Callsphere, "Unit Testing AI Agents" —
  https://callsphere.ai/blog/unit-testing-ai-agents-mocking-llm-calls-deterministic-tests
  — the mocked-LLM unit-testing pattern. Retrieved 2026-08-19.
- Atlan, "How to Test an AI Agent Harness" —
  https://atlan.com/know/how-to-test-ai-agent-harness/ — the layered
  agent-testing-harness model. Retrieved 2026-08-19.
- `modelcontextprotocol/inspector` on GitHub —
  https://github.com/modelcontextprotocol/inspector — Web/CLI/TUI
  inspection modes; 10,702 stars confirmed by direct API fetch,
  2026-08-20.
- Kansei Link, "Cloudflare Workers MCP Deployment Guide 2026" —
  https://kansei-link.com/en/insights/cloudflare-workers-mcp-deployment-guide-2026.html
  — the Python/V8-isolate runtime mismatch. The post's "52% of public
  remote MCP servers abandoned" figure is a single-source stat, not
  independently verified, and is deliberately not repeated in this doc.
  Retrieved 2026-08-19.
- Speakeasy, "Deploying MCP Servers" —
  https://www.speakeasy.com/mcp/deploying-mcp-servers/ — corroborating
  Docker/VPS vs. serverless/edge trade-offs. Retrieved 2026-08-19.
- MCP blog, "MCP Registry Preview" —
  https://blog.modelcontextprotocol.io/posts/2025-09-08-mcp-registry-preview/
  — official Registry announcement (`server.json`, `mcp-publisher`,
  namespace verification). Retrieved 2026-08-19.
- Kong, "What Is an MCP Registry" —
  https://konghq.com/blog/learning-center/what-is-an-mcp-registry — the
  Registry-vs.-Smithery/Glama/PulseMCP distinction. Retrieved 2026-08-19.
- Practical DevSecOps, "MCP Security Vulnerabilities" —
  https://www.practical-devsecops.com/mcp-security-vulnerabilities/ and
  Cloud Security Alliance research note —
  https://labs.cloudsecurityalliance.org/research/csa-research-note-mcp-tool-poisoning-auto-execution-20260701/
  — tool poisoning as the dominant 2026 MCP-specific threat; vulnerability
  prevalence figures cited there as vendor/scan-published, not
  independently reproduced. Retrieved 2026-08-19.
- Simon Willison, "MCP and Prompt Injection" —
  https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/ — earlier,
  widely-cited independent explainer distinguishing MCP prompt-injection
  risk from classic prompt injection. Retrieved 2026-08-19.
- Uptrace, "OpenTelemetry for AI Systems" —
  https://uptrace.dev/blog/opentelemetry-ai-systems and Greptime, "OTel
  GenAI Semantic Conventions" —
  https://greptime.com/blogs/2026-05-09-opentelemetry-genai-semantic-conventions
  — OTel GenAI conventions status (Development stability as of v1.41, May
  2026). Retrieved 2026-08-19.
- Local precedent (not a web source, read directly):
  `C:\Users\devop\GitHub\MCPg\CLAUDE.md`, `CONTRIBUTING.md`,
  `docs\architecture.md`, `docs\adr\0002-technology-stack.md`,
  `src\mcpg\otel_tracing.py` — read 2026-08-19.
