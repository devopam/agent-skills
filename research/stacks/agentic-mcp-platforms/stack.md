# Baseline: Agentic & MCP Platforms — Architecture & Stack
Status: draft      Date: 2026-08-19

## Local precedent used throughout

`C:\Users\devop\GitHub\MCPg\` — a production, single-process async Python MCP
server (254 tools) — is used as a concrete worked example in every section
below. Read directly: `CLAUDE.md`, `CONTRIBUTING.md`, `docs/architecture.md`,
`docs/adr/0002-technology-stack.md`, and `src/mcpg/otel_tracing.py`. MCPg is
one real data point, not the sole source — external research is cited
alongside it, and divergences are called out honestly rather than assumed
correct.

## In scope

- **Which cross-cutting architecture patterns fit an agent/MCP backend, and
  why** — impact: high — depth: section. MCPg's own request lifecycle
  (`docs/architecture.md`) is a layered-with-ports-and-adapters shape in
  practice even though no ADR names "hexagonal" explicitly: `AuditedMCPServer`
  (transport/protocol adapter) → tool wrapper (port, translates MCP calls to
  typed Python calls) → logic module (domain) → composable driver stack
  (`SafeSqlDriver` → `RoutedSqlDriver` → `TenantSqlDriver`, each an adapter
  decorating the next) → `psycopg3` pool (outbound adapter to PostgreSQL).
  This is a reusable shape: MCP servers are naturally hexagonal because the
  protocol *is* the inbound port and the wrapped external system (DB, API,
  filesystem) is the outbound adapter — the domain logic in between should
  not know it's being called over MCP. Layered/n-tier fits small single-tool
  servers where the ceremony of explicit ports isn't earned yet. Microservices
  fit only past a genuine multi-team/multi-domain boundary (splitting tool
  families across processes is rarely justified below that line — MCPg keeps
  254 tools in one process). Event-driven overlays fit the notification /
  async-tool-result side (MCP's own `notifications/*` messages, and patterns
  like MCPg's LISTEN/NOTIFY-to-tool-poll bridge in `mcpg.listen`) more than
  they replace the core request/response tool-call path. CQRS/event sourcing
  is rarely justified for a tool-serving backend (same caution as the
  cross-cutting doc). Serverless is a live, spec-endorsed option specifically
  *because* of the 2026-07-28 statelessness change (see below) — but only for
  transports/languages that support it well (see Deployment models).

- **The 2026-07-28 MCP spec revision going stateless — the single most
  consequential recent architecture fact for this category** — impact: high
  — depth: section. As of the 2026-07-28 specification (release candidate
  locked 2026-05-21, final published 2026-07-28), MCP removed the
  `initialize`/`notifications/initialized` handshake and the
  `Mcp-Session-Id` header from Streamable HTTP; every request now carries
  its protocol version and capabilities inline, `tools/list` /
  `resources/list` / `prompts/list` no longer vary per-connection, and any
  server that needs cross-call state must mint an explicit handle passed as
  an ordinary tool argument rather than relying on transport-level session
  state. This turns a compliant MCP server into "an ordinary HTTP workload":
  any request can land on any instance behind a plain round-robin load
  balancer, enabling serverless/edge deployment and trivial horizontal
  scaling. Practical note for the authored doc: this spec finalized about
  three weeks before this baseline's date — SDK and client adoption will lag
  behind the spec for a while, so the authored guidance should present
  stateless as *the direction the ecosystem is moving*, not yet as something
  every client already speaks. **MCPg divergence, noted honestly**: MCPg's
  ADR-0002 and `http_runtime` module predate this change and are built
  against the 2025-06-18-era transport model (`streamable-http` / `sse`
  chosen by env var, OIDC/bearer auth, per-request `X-MCPG-Role` header) —
  this is not wrong for a project that started before mid-2026, but a new
  project starting today should default to the stateless request model from
  the outset rather than reproduce MCPg's session-era pattern.

- **Transport choice for MCP servers: stdio vs. HTTP (Streamable HTTP) vs.
  SSE** — impact: high — depth: table. stdio: local subprocess, one client
  per server instance, zero network exposure, the default for
  desktop-integrated servers (Claude Desktop, Cursor, local dev) — cannot
  serve multiple remote clients. Streamable HTTP: the current standard for
  remote/multi-client servers, single endpoint supporting POST+GET,
  optional SSE-style streaming of individual responses; this is what replaced
  the older dedicated SSE transport. Plain SSE transport: deprecated in the
  2025-06-18 spec revision in favor of Streamable HTTP — MCPg still offers
  it as a selectable transport for backward compatibility with older
  clients, which is a legitimate compatibility trade-off worth naming
  explicitly rather than treating as a mistake (broad-compatibility-vs.-
  latest-spec is a real axis projects choose along).

- **Auth models for MCP** — impact: high — depth: section/table. The spec's
  own model (2025-06-18 onward): the MCP server acts as an OAuth 2.1
  *resource server*, not an authorization server — it MUST implement OAuth
  2.0 Protected Resource Metadata (RFC 9728) so clients can discover the
  associated authorization server, and clients MUST use RFC 8707 Resource
  Indicators so a malicious server can't obtain a token scoped too broadly.
  Authorization is spec-optional but standardized when used. For simpler/
  internal deployments, a static bearer token or API key (MCPg's
  `MCPG_HTTP_AUTH_TOKEN` constant-time-compare option) is a legitimate lighter
  weight alternative to full OAuth — the trade-off is client-management
  overhead (rotate/distribute a shared secret) vs. OAuth's per-user
  delegation and audit trail. MCPg's concrete pattern worth carrying forward:
  layering a **role-propagation** concern (`X-MCPG-Role` header or an OIDC
  role claim) on top of authentication, read by a `TenantSqlDriver` to scope
  the connection — i.e., authn and per-request authorization-scope are
  separate middleware concerns, not one gate.

- **Tool/resource/prompt schema design** — impact: high — depth: checklist.
  Current (2026) guidance converges on: be verbose in the tool *description*
  (drives tool selection and argument generation) but concise/precise in
  parameter names and types (machine-readable structure, not model
  guidance); use the 2025-03-26+ tool **annotations**
  (`readOnlyHint`/`destructiveHint`/`idempotentHint`/`openWorldHint`) to
  declare behavioral properties so clients and agents can reason about risk
  before calling; keep each tool's input schema narrow and single-purpose
  rather than one mega-tool with many optional modes; measure tool-selection
  accuracy empirically (cited informal bar: 20-50 test prompts, treat
  <95% straightforward-query accuracy as a signal to rename/re-describe, not
  to add more tools). MCPg's concrete instance of "generated beats
  hand-maintained" for this concern: its tool surface is pinned by a
  contract-test snapshot (`tests/contract/tool_surface.snapshot.json`) that
  fails CI on any undocumented name/description/schema drift — a reusable
  pattern for any MCP server with a nontrivial tool count.

- **Context/memory architecture for agent backends generally** (this half of
  the category is broader than pure MCP-server building — it covers the
  agent/orchestrator side that *calls* tools) — impact: high — depth:
  section. Three recurring patterns in current sources, roughly in order of
  operational maturity: (a) monolithic/in-context — everything lives in the
  prompt, zero extra infrastructure, fine for short-lived single-session
  agents, degrades via context-window pressure and summarization drift as
  sessions lengthen; (b) context + external retrieval store — working memory
  stays in the context window, long-term facts/episodes live in an external
  store (vector DB, SQL, file) fetched on demand; (c) tiered/hierarchical
  memory — a hot layer (recent turns verbatim) plus compressed/summarized
  historical layers, often with a controller deciding what gets promoted or
  evicted. Practical framing for the authored doc: pick (a) by default for
  short-lived agent runs, move to (b)/(c) only once a session's expected
  length or persistence requirement demands it — this mirrors the
  cross-cutting doc's "complexity, not size, is the trigger" theme. Note:
  MCPg itself is a stateless tool provider with no agent memory of its own
  (memory belongs to whatever agent/client calls it) — this sub-topic serves
  the "agent backend" half of the category more than the "MCP server" half,
  and the authored doc should say so explicitly so MCP-server-only builders
  know they can skip it.

- **Model-switching / provider-abstraction patterns** — impact: med — depth:
  paragraph. Two shapes in current use: an in-process abstraction library
  (call any of 100+ providers through one interface, e.g. LiteLLM) versus a
  network-level gateway/proxy (route/failover/cache at the HTTP layer, e.g.
  Vercel AI Gateway). The in-process shape is simpler for a single service;
  the gateway shape earns its keep once several services/agents need
  centralized cost tracking, rate limiting, or automatic provider failover.
  This is a library-selection question more than an architecture-pattern
  question — full detail lives in libraries.md; this doc names the two
  shapes and when each is warranted.

- **When an agent framework is warranted vs. a raw SDK / hand-rolled loop**
  — impact: high — depth: section. This is the most important honesty check
  in the category. For **building an MCP server**, current sources and
  MCPg's own choice agree: use the official/community MCP SDK (or a thin
  ergonomic wrapper like FastMCP) directly — a general agent-orchestration
  framework (LangGraph, CrewAI, etc.) is solving a different problem
  (multi-step reasoning/orchestration on the *client* side) and adds
  complexity an MCP server doesn't need, since the server's job is exposing
  typed tools/resources, not reasoning. For **building the agent that
  consumes tools** (including MCP tools), a framework earns its cost once
  the orchestration itself is nontrivial — multi-agent handoffs, durable/
  resumable long-running workflows, human-in-the-loop approval steps — and
  is genuine overhead for a single linear tool-use loop, where a raw
  provider SDK loop is often the better-regarded current advice. The
  authored doc should state this two-sided answer plainly rather than
  defaulting to "use a framework."

- **Testing harnesses for agentic systems** — impact: high — depth: table/
  checklist. Current (2026) convergence describes a layered model: (1) unit
  tests with the LLM call mocked/injected — deterministic, fast, verify
  prompt construction, tool-argument-schema matching, and output parsing
  without hitting a real model; (2) tool-routing tests — fixed prompt in,
  assert the expected tool + correctly-shaped arguments were selected,
  including malformed-output and LLM-failure edge cases; (3)
  protocol-level integration tests against a real (or containerized) MCP
  server using the MCP Inspector's scriptable CLI/TUI modes for CI-friendly
  automated checks; (4) contract/snapshot tests pinning the tool surface and
  return shapes against regressions — MCPg's two-snapshot contract-test
  pattern (`test_tool_surface_snapshot.py` for names/descriptions/schemas,
  an AST-derived snapshot for return-shape fields) is a concrete, reusable
  instance of layer 4 worth citing directly. Full tool names for each layer
  live in libraries.md.

- **Deployment models** — impact: high — depth: table. Local/stdio-subprocess
  (desktop integration — Claude Desktop, Cursor, IDE-embedded — no network
  exposure, one client per process); long-running containerized HTTP service
  (MCPg's model: hardened multi-stage Docker image, non-root
  `uid=10001`/`gid=10001`, read-only application files — appropriate for
  stateful drivers, connection pools, or heavier runtimes like Python that
  don't map cleanly to edge isolates); serverless/edge (Cloudflare Workers,
  AWS Lambda, Vercel Functions — enabled architecturally by the 2026-07-28
  stateless spec revision, but with a real language-runtime constraint:
  V8-isolate platforms like Cloudflare Workers run JS/TS natively with
  millisecond cold starts, while Python frameworks like FastMCP are reported
  by practitioners as a poor fit there — container-based serverless (Lambda,
  Vercel Functions) supports Python but with slower cold starts than a V8
  isolate). VPS/self-hosted (full control, no serverless transport
  restrictions, same container in dev and prod). Publishing/discoverability
  is a related but distinct concern: the official MCP Registry (minimal,
  canonical, `server.json` + `mcp-publisher publish`) versus discovery
  layers like Smithery/Glama/PulseMCP that add search/curation on top —
  MCPg ships to PyPI, GHCR, the MCP registry, Smithery, and an HF Spaces
  demo simultaneously, illustrating that these are complementary
  distribution channels, not competing choices.

- **Security concerns specific to this category** — impact: high — depth:
  section. The dominant 2026 MCP-specific threat is **tool poisoning**:
  malicious instructions embedded in a tool's *description*/metadata field
  (an unsanitized attack surface the model reads and may follow, even though
  the user only sees a benign-looking label) — distinct from classic prompt
  injection via tool *output*, though both exploit the same trust boundary.
  Reported prevalence figures from 2026 scans (cited with the caveat that
  these are single-source/vendor-published stats, not independently
  reproduced): command-injection patterns in a meaningful share of tested
  servers, and SSRF/path-traversal exposure tied to file-operation and
  network-fetching tools. MCPg's concrete mitigations worth citing as a
  reusable pattern: a capability/access-mode policy gate (`read-only` /
  `restricted` / `unrestricted`, with higher-blast-radius capabilities like
  `DDL`/`SHELL`/`LISTEN` requiring their own additional opt-in env var) that
  determines which tools are even *registered* for a given deployment,
  rather than gating at call time only; a first-party SQL-safety kernel that
  parses and allowlists agent-supplied SQL before execution instead of
  trusting the model's output; and identifier validation via regex
  everywhere user/model-supplied names reach SQL. The general principle:
  the server, not the model, must be the enforcement boundary for anything
  destructive — annotations (`destructiveHint`) inform the *client's* UX,
  they are not a security control the server can rely on.

- **Observability architecture pattern (the "how", not the tool)** — impact:
  med — depth: paragraph (tool-specific detail deferred to libraries.md).
  The recurring shape is one span per tool call, with span status
  (OK/ERROR) plus structured attributes (tool name, argument *count* rather
  than raw values to avoid leaking secrets/PII into a trace backend, error
  type/message). MCPg's `otel_tracing.py` is a concrete instance of this
  shape, using its own `mcp.tool.*` attribute namespace. Divergence worth
  naming honestly: the OpenTelemetry GenAI semantic conventions (`gen_ai.*`
  namespace, covering agent/workflow/tool/model spans) are the emerging
  standardized alternative, but as of mid-2026 remain in **Development**
  stability status, meaning attribute names can still change without a
  major-version bump — MCPg's choice to define its own small, stable
  attribute set instead of adopting an actively-churning standard is a
  defensible engineering trade-off, not obviously wrong, and the authored
  doc should present both options with that stability caveat rather than
  unconditionally recommending the standard.

## Explicitly out of scope

- Specific library/framework/vendor names and their license/maintenance
  detail — belongs entirely in the companion `libraries.md` baseline; this
  doc only names *categories* and *when* each is warranted.
- Prompt-engineering technique and prompt-design craft (few-shot structuring,
  chain-of-thought prompting, etc.) — not an architecture/stack concern.
- Model selection/comparison (which LLM to call) and pricing — orthogonal to
  backend architecture; belongs to a model-selection concern outside this
  skill's scope.
- Fine-tuning, RAG-corpus construction, and training infrastructure — this
  category covers serving/orchestration architecture, not model-building.
- Deep coverage of Agent-to-Agent (A2A) or other emerging agent-to-agent
  protocols — MCP (tool access) is this category's anchor protocol; A2A-style
  peer coordination is a related-but-distinct and less mature area, flagged
  as an open question below rather than researched in depth this pass.
- Deep regulatory/compliance detail — treated only as a signal (per the
  cross-cutting architecture-templates.md convention), not researched here.
- Cost modeling / numeric cloud pricing comparisons — same convention as the
  cross-cutting doc: qualitative trade-offs only.

## Sources

- https://modelcontextprotocol.io/specification/2025-06-18/changelog —
  official MCP changelog for the 2025-06-18 revision: OAuth Resource Server
  classification, RFC 8707 Resource Indicators requirement, elicitation,
  resource links, `MCP-Protocol-Version` header requirement — retrieved
  2026-08-19 (direct fetch)
- https://blog.modelcontextprotocol.io/posts/2026-07-28/ and
  https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/
  — official announcement of the 2026-07-28 spec (stateless protocol core,
  removal of the init handshake and `Mcp-Session-Id` header, RC locked
  2026-05-21, final published 2026-07-28) — retrieved 2026-08-19
- https://modelcontextprotocol.io/specification/2026-07-28/changelog —
  official changelog page for the stateless-era spec — retrieved 2026-08-19
- https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
  and https://spec.modelcontextprotocol.io/specification/2025-03-26/basic/transports/
  — stdio and (then-current) SSE/HTTP transport definitions — retrieved
  2026-08-19
- https://modelcontextprotocol.io/specification/draft/basic/authorization —
  official MCP authorization spec: OAuth 2.1 resource-server model, RFC 9728
  Protected Resource Metadata, RFC 8707 Resource Indicators — retrieved
  2026-08-19
- https://www.descope.com/blog/post/mcp-auth-spec — secondary explainer on
  the MCP authorization spec, corroborating the resource-server framing —
  retrieved 2026-08-19
- https://kansei-link.com/en/insights/mcp-tool-schema-design-guide-2026.html
  — tool schema design guidance (description verbosity vs. parameter
  concision, annotations vocabulary, 95%-accuracy testing bar) — retrieved
  2026-08-19
- https://www.explainx.ai/blog/tool-definition-schema-design-context-engineering-2026
  — corroborating tool/schema design guidance — retrieved 2026-08-19
- https://wavect.io/blog/mcp-stateless-server-migration-2026/ and
  https://fast.io/resources/building-stateful-mcp-servers/ — secondary
  coverage of stateless-vs-stateful MCP server design and the
  "default-to-stateless, use explicit handles for real state" guidance —
  retrieved 2026-08-19
- https://atlan.com/know/agent-memory-architectures/ — five agent-memory
  architecture patterns and trade-offs (monolithic/context+retrieval/tiered)
  — retrieved 2026-08-19
- https://agentmarketcap.ai/blog/2026/04/11/agent-context-engineering-sliding-windows-memory-2026
  — corroborating context-engineering/tiered-memory patterns for
  long-running agents — retrieved 2026-08-19
- https://nerova.ai/comparisons/claude-agent-sdk-vs-langgraph-2026 and
  https://www.developersdigest.tech/blog/claude-agent-sdk-vs-langgraph —
  framework-vs-raw-SDK positioning (Claude Agent SDK = one agent given an
  environment; OpenAI Agents SDK = many lightweight agents with handoffs;
  LangGraph = lower-level graph/state runtime) — retrieved 2026-08-19
- https://www.iamraghuveer.com/posts/unit-testing-custom-agents/ and
  https://callsphere.ai/blog/unit-testing-ai-agents-mocking-llm-calls-deterministic-tests
  — mocked-LLM unit-testing pattern for agent code — retrieved 2026-08-19
- https://atlan.com/know/how-to-test-ai-agent-harness/ — layered
  agent-testing-harness model (prompt construction / LLM call mechanics /
  output parsing; sandboxed tool-call interception) — retrieved 2026-08-19
- https://github.com/modelcontextprotocol/inspector — official MCP
  Inspector repo: Web/CLI/TUI inspection modes, ~10.7k stars — retrieved
  2026-08-19
- https://kansei-link.com/en/insights/cloudflare-workers-mcp-deployment-guide-2026.html
  — Cloudflare Workers MCP deployment guidance, including the Python/V8-
  isolate runtime mismatch and the "52% of public remote MCP servers
  abandoned" adoption-health stat (cited as a single-source figure, not
  independently verified) — retrieved 2026-08-19
- https://www.speakeasy.com/mcp/deploying-mcp-servers/ — corroborating
  remote-MCP-server deployment trade-offs (Docker/VPS self-host vs.
  serverless/edge) — retrieved 2026-08-19
- https://blog.modelcontextprotocol.io/posts/2025-09-08-mcp-registry-preview/
  — official MCP Registry announcement (server.json, mcp-publisher,
  namespace verification via GitHub OIDC or DNS) — retrieved 2026-08-19
- https://konghq.com/blog/learning-center/what-is-an-mcp-registry — MCP
  Registry vs. Smithery/Glama/PulseMCP discovery-layer distinction —
  retrieved 2026-08-19
- https://www.practical-devsecops.com/mcp-security-vulnerabilities/ and
  https://labs.cloudsecurityalliance.org/research/csa-research-note-mcp-tool-poisoning-auto-execution-20260701/
  — tool poisoning as the dominant 2026 MCP-specific threat; IDE
  auto-execution risk; vulnerability-prevalence figures (cited as
  vendor/scan-published stats, not independently reproduced) — retrieved
  2026-08-19
- https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/ — earlier,
  widely-cited independent explainer distinguishing MCP prompt-injection
  risk from classic prompt injection — retrieved 2026-08-19
- https://uptrace.dev/blog/opentelemetry-ai-systems and
  https://greptime.com/blogs/2026-05-09-opentelemetry-genai-semantic-conventions
  — OpenTelemetry GenAI semantic conventions status as of 2026 (agent/
  workflow/tool/model span types; Development stability, attribute names
  not yet stable) — retrieved 2026-08-19
- Local precedent (not a web source, read directly): `C:\Users\devop\GitHub\MCPg\CLAUDE.md`,
  `CONTRIBUTING.md`, `docs\architecture.md`, `docs\adr\0002-technology-stack.md`,
  `src\mcpg\otel_tracing.py` — read 2026-08-19

## Open questions for the user

- Should the authored doc name hexagonal/ports-and-adapters as the *default
  recommended* pattern for MCP-server backends specifically (matching
  MCPg's de facto shape), or stay pattern-neutral the way the cross-cutting
  architecture-templates.md doc does and just describe the fit reasoning?
  This baseline leans toward naming a default given how consistently the
  transport-adapter/domain-logic/outbound-adapter shape recurs, but it's a
  meaningful prescriptiveness call.
- How much weight should the 2026-07-28 stateless spec revision carry, given
  it finalized only about three weeks before this baseline's date? Treat it
  as settled best practice, or hedge more heavily on ecosystem/SDK lag?
  This baseline currently hedges ("the direction the ecosystem is moving,"
  not "what every client already does").
- Agent-to-agent protocols (A2A and similar) were scoped out this pass as
  immature/tangential. Confirm that's correct, or should a short section
  acknowledge A2A exists and how it relates to MCP (tool access vs. peer
  coordination) even at low depth?
- The "agent backend memory/context architecture" sub-topic serves the
  broader "LLM agent backends generally" half of the category more than the
  "MCP server" half — MCPg itself has no agent memory of its own. Confirm
  the split is useful as written (explicitly flagging which sub-topics apply
  to which half of the audience) rather than presenting the category as one
  undifferentiated topic.
- Vulnerability-prevalence statistics for MCP-specific attack classes (tool
  poisoning, SSRF, path traversal) all trace to a small number of 2026
  scan/vendor publications this pass turned up, not independently
  cross-verified academic sources. Acceptable to cite with the "single-
  source, not independently reproduced" caveat as done here, or should
  authoring drop the specific percentages and keep only the qualitative
  threat descriptions?

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/agentic-mcp-platforms.md —
  est. 420–500 lines (12 subsections per the In-scope list above; several as
  tables, the transport/deployment/testing/security items likely the
  longest given table + worked-example density).
