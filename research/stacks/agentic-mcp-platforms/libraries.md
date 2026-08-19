# Baseline: Agentic & MCP Platforms — Preferred Libraries
Status: draft      Date: 2026-08-19      Snapshot date: 2026-08-19

## Local precedent used throughout

`C:\Users\devop\GitHub\MCPg\docs\adr\0002-technology-stack.md` records a real
production MCP server's stack choices (Python 3.12+, official `mcp` SDK /
`FastMCP`, `psycopg` 3, `pglast`, `uv`, `pytest`, `ruff`, `mypy --strict`).
Used as one data point per entry below, not as the sole justification —
every entry is cross-checked against current external sources with a
retrieval date. All star/download/version figures below were found in
searches run 2026-08-19 and should be treated as approximate,
single-snapshot figures, not verified against the repos directly (no direct
GitHub API fetch was performed this pass — see Open questions).

## In scope

### MCP SDKs (official) — impact: high — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| `modelcontextprotocol/python-sdk` | Official Python MCP server/client SDK | MIT (repo transitioning new contributions to Apache-2.0 per MCP project-wide license migration) | The canonical, Anthropic/Linux-Foundation-governed implementation; MCPg builds on it directly | 2026-08-19 | ~24k GitHub stars, 3.8k forks, 1,035+ commits on main, 199 open issues as of this pass; shipped a v2 rework in 2026 for the 2026-07-28 spec (v1.x still gets critical fixes on a separate branch) |
| `modelcontextprotocol/typescript-sdk` | Official TypeScript MCP server/client SDK | Apache-2.0 for new contributions, MIT for existing code (same project-wide license transition) | Canonical TS implementation; first choice for any MCP server targeting edge/serverless (V8-isolate) runtimes | 2026-08-19 | ~13.2k GitHub stars, 1,605+ commits on main, 288 open issues; also reworked for the 2026-07-28 spec, v1.x supported ≥6 months post-v2 |
| Official SDKs for Java, Kotlin, C#, Go, Ruby, Swift, PHP, Rust (`modelcontextprotocol` GitHub org) | Non-Python/TS MCP server/client implementations | Varies by repo, predominantly MIT/Apache-2.0 | Anthropic-endorsed org-level SDKs exist for most mainstream languages; use the org listing to confirm current status per language before committing, since maturity varies | 2026-08-19 | Not individually star-checked this pass — flagged as a gap, see Open questions |

**MCP Inspector** (`modelcontextprotocol/inspector`) — the official visual/CLI/TUI
testing tool for any MCP server regardless of implementation language; MIT/
Apache-2.0 (same project-wide transition); ~10.7k stars as of this pass;
ships Web, scriptable CLI, and Ink-based TUI modes, the CLI mode being the
one to wire into CI. **Security note carried forward**: versions below
0.14.1 carried a CVSS 9.4 RCE (CVE-2025-49596) — pin a patched version.
Last reviewed 2026-08-19.

### High-level Python MCP-server framework — impact: high — depth: paragraph

**FastMCP (standalone, `PrefectHQ/fastmcp`)** — a Pythonic, decorator-based
layer for building MCP servers/clients, now maintained under PrefectHQ
(moved from the original `jlowin/fastmcp`). Distinct from the
official Python SDK's own bundled server class of the same lineage — FastMCP
1.0 was folded into the official SDK back in 2024, but the standalone project
kept evolving independently and reached a 3.0 GA on 2026-02-18. One
self-reported source claims it (in some version, across languages) "powers
70% of MCP servers" and sees ~1M downloads/day — cited here with an explicit
caveat that this is a single, apparently vendor/author-adjacent source, not
independently corroborated, and should not be repeated in authored content
without a second source. **Naming collision to flag explicitly**: the
official SDK's own bundled high-level class was itself called `FastMCP`
until a 2026-06-30 v2.0 beta renamed it to `MCPServer` specifically to
reduce confusion with the standalone project — authored guidance should use
`MCPServer` (official SDK) vs. `FastMCP` (standalone PrefectHQ project) as
the disambiguating terms going forward. **Recommendation, stated honestly**:
for a from-scratch MCP server, the raw official SDK (or its bundled
`MCPServer` class) is sufficient and is what MCPg itself uses per ADR-0002 —
reach for standalone FastMCP when its added ergonomics (richer typed
decorators, built-in client testing utilities, proxying/composition
features) are worth the extra dependency; it is not a mandatory layer on
top of the SDK. Last reviewed 2026-08-19.

### Agent orchestration frameworks — impact: high — depth: table + honest caveat

**Honesty check first, since the research prompt asked for it explicitly**:
for *building an MCP server*, none of the frameworks below are needed — the
raw MCP SDK is the better-regarded current advice, and MCPg's own
production server confirms this in practice (no agent-orchestration
framework anywhere in its dependency tree). The frameworks below matter for
the *agent/client* side of this category — the thing that reasons over
multiple steps and calls MCP tools (or other tools) along the way — and
even there, a raw provider-SDK loop is often adequate for a single linear
tool-use flow; framework adoption is warranted once orchestration itself
(multi-agent handoffs, durable/resumable workflows, human-in-the-loop
approval) is genuinely complex.

| Library | For | License | Why recommended (or not) | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| Claude Agent SDK (Anthropic) | Single-agent, environment-driven work (code, files, systems, long autonomous runs) inside Claude's own tool-use loop | Anthropic SDK license (not a copyleft/OSS license — check current terms before depending on it in a redistributable OSS project) | Best fit when the product wants "Claude Code's working-agent loop" embedded in an application; MCP is its native tool-integration layer | 2026-08-19 | Actively developed by Anthropic; version/cadence not independently star-checked this pass (not a traditional community-stars OSS project) |
| OpenAI Agents SDK (`openai/openai-agents-python`, `openai-agents-js`) | Multi-agent workflows with explicit handoffs/guardrails; voice agents (JS variant) | MIT | Strong fit when the job is routing between specialist agents rather than one agent working an environment | 2026-08-19 | ~28.5k stars (Python), ~3.1k stars (JS) as of mid-2026; roughly weekly releases (e.g. v0.17.5, 2026-06-11) but still pre-1.0 (0.x) fifteen months after launch — note the API-stability caveat that implies |
| LangGraph (`langchain-ai/langgraph`) | Low-level, graph-based agent runtime: explicit state, persistence, interrupts/resumability, production control | Core (`langgraph`, `langchain-core`, model integrations): MIT. **`langgraph-api` specifically: Elastic License 2.0** — not permissive OSS; check which package a given deployment actually depends on before assuming full MIT coverage | Most control of any option here, at the cost of more boilerplate; the right choice when the product *is* the orchestration (long-running, resumable, model-agnostic across Anthropic/OpenAI/Gemini/local) | 2026-08-19 | ~126k–139k stars as of mid-2026 (source variance); v1.1.6 in April 2026, PyPI showed a release as recent as 2026-08-11 — actively maintained |
| Pydantic AI (`pydantic/pydantic-ai`) | Type-safe agent framework for Python teams already invested in Pydantic | MIT | Appreciated by data/Python teams wanting production type-safety without LangGraph's lower-level ceremony | 2026-08-19 | ~16.5k-16.8k stars as of this pass; launched public beta late 2024, steady growth since |
| CrewAI (`crewAIInc/crewAI`) | Role-playing multi-agent scenarios (defined "crew" of agents with roles) | MIT | Popular for role-based multi-agent scripting; weaker fit than the above for single-agent environment-driven work | 2026-08-19 | ~25k-44k stars depending on source (wide variance found — flagged, not independently reconciled this pass) |

### Model-provider abstraction — impact: med — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| LiteLLM | In-process unified interface to 100+ LLM providers (OpenAI-compatible call shape); also ships a standalone proxy/gateway mode | MIT | Simplest path to model-switching/fallback for a single service; works standalone or as a dependency inside LangChain/LlamaIndex-style stacks | 2026-08-19 | Actively developed; gained a March-2026 first-party Vercel deployment integration, a signal of continued ecosystem investment |
| Vercel AI SDK (`ai-sdk.dev`) | Unified provider API for TypeScript/JS apps, especially ones already on Vercel | Apache-2.0 | Two-line model swap; tightest integration with Vercel's edge/serverless deployment story and its AI Gateway | 2026-08-19 | Actively maintained by Vercel; positioned as the default for the Next.js/edge ecosystem specifically |

### Testing / eval tooling for agents — impact: high — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| `modelcontextprotocol/inspector` (MCP Inspector) | Protocol-level manual + scripted testing of any MCP server | MIT/Apache-2.0 (project-wide transition) | Official, transport-agnostic (stdio/SSE/Streamable HTTP), CLI mode is CI-friendly | 2026-08-19 | ~10.7k stars; see security-pin note above |
| DeepEval (`confident-ai/deepeval`) | pytest-native unit/integration assertions for LLM and agent output, with built-in LLM-as-judge metrics | Apache-2.0 | Fits directly into an existing pytest suite (matches MCPg's own `pytest`-based testing convention); Python and TypeScript support | 2026-08-19 | Reported as the fastest-growing LLM eval framework by download volume in early 2026 (3M+ monthly PyPI downloads), 10k+ GitHub stars — figures from a single source (Confident AI's own material), not independently cross-verified |
| Inspect AI (UK AI Security Institute) | Registry-style, rigorous agent/model evaluation, notably used in public-sector/safety evaluation contexts | MIT | Positioned by 2026 sources as one of three converging open-source eval standards (alongside DeepEval and OpenAI Evals); a credible choice when evaluation rigor/auditability matters more than pytest-native ergonomics | 2026-08-19 | Cited version v0.3.225 as of a May-2026 source; not independently re-verified this pass |
| Promptfoo | CLI for prompt/LLM-app regression testing, red-teaming, multi-provider comparison | MIT (confirmed to remain MIT post-acquisition) | Strong for regression-testing prompts/tool-selection across provider changes; wide adoption | 2026-08-19 | ~22.3k stars, 907 forks, 255 contributors as of this pass. **Governance flag**: OpenAI announced acquisition of Promptfoo on 2026-03-09 (~$86M valuation); OpenAI's own public statement commits to keeping it open source under the current (MIT) license, but a non-OpenAI team should weigh the vendor-objectivity question this creates for a tool used to *evaluate* OpenAI's own models among others |

### Observability / tracing for LLM and agent runs — impact: high — depth: table

| Library | For | License | Why recommended | Last reviewed | Maintenance/adoption signal |
|---|---|---|---|---|---|
| OpenTelemetry GenAI semantic conventions | Standardized span/attribute naming (`gen_ai.*`) for LLM calls, agent/workflow spans, tool-call spans, token-usage metrics | Apache-2.0 (CNCF/OpenTelemetry project) | Vendor-neutral, and the direction observability backends (Datadog, Honeycomb, New Relic) and frameworks (LangChain, CrewAI, AutoGen) are converging on | 2026-08-19 | Coding agents (GitHub Copilot, Codex, Claude Code) reported emitting these conventions directly by mid-2026 — but **stability caveat carried forward from stack.md**: as of v1.41 (May 2026) nearly all `gen_ai.*` attributes carry Development-stability badges, meaning names can change without a major-version bump. Don't build alerting/dashboards that assume attribute-name stability yet |
| Langfuse | Self-hostable LLM/agent tracing, prompt management, evaluation | Core: MIT (self-hosting supported) | Leading open-source option; framework-agnostic via OTel-based tracing plus 20+ native integrations, avoiding vendor lock-in | 2026-08-19 | ClickHouse announced acquisition of Langfuse January 2026; core stayed MIT-licensed and self-hosting continued post-acquisition per the same sources; March-2026 data-model redesign leans further into ClickHouse as the storage backend — worth re-checking self-host complexity if that dependency matters |
| LangSmith | LangChain/LangGraph-native hosted tracing and evaluation | **Proprietary** — client SDKs are open source, but backend/UI/storage are closed; self-hosting is an Enterprise-only add-on | Deepest native integration if a team is already fully committed to LangChain/LangGraph; **not recommended as a default** for teams wanting an open, self-hostable observability layer — named here for completeness and honest comparison against Langfuse, not as the preferred pick | 2026-08-19 | LangChain shipped "SmithDB" (a purpose-built Rust/DataFusion trace database) in May 2026, reporting up to 15x faster core experiences for LangSmith Cloud — a real investment signal, but doesn't change the licensing/self-hosting trade-off |
| Arize Phoenix (`Arize-ai/phoenix`) | Open-source LLM/agent observability and evaluation, OTel-native | Apache-2.0 (no feature-gating per source; one source also referenced Elastic License 2.0 for an unspecified component — worth confirming per-package at authoring time) | Credible open-source alternative to Langfuse, notably OTel-native by design | 2026-08-19 | ~9k-10.3k stars depending on source/date within this pass |

## Explicitly out of scope

- Any library whose primary purpose is model training/fine-tuning (this
  category is serving/orchestration, not model-building).
- General-purpose web frameworks (FastAPI, Express, etc.) used merely as the
  HTTP transport underneath an MCP server — those belong to the Backend &
  API Services stack baseline, not this one, except where an MCP-specific
  library (e.g. the SDK's own Streamable HTTP handling) is the actual
  subject.
- Vector database / RAG-corpus tooling (Pinecone, Weaviate, pgvector, etc.)
  — a memory/retrieval *backend* choice that's downstream of the
  architecture pattern named in stack.md, not itself an agent/MCP-platform
  library; likely belongs to Data & Analytics Platforms instead.
- Individual per-language non-Python/TS MCP SDKs' detailed maturity
  assessment — named as a category (see the org-listing row above) but not
  individually vetted this pass; flagged as an open question.
- Cost/pricing comparisons between the observability platforms — Langfuse
  vs. LangSmith vs. others' actual dollar costs were surfaced in research
  but are excluded here per the cross-cutting doc's no-pricing convention;
  license and self-hosting status are treated as the durable signal instead.
- Specific PostgreSQL/database driver libraries (`psycopg`, `pglast`, etc.)
  — those are MCPg's *domain* stack (a Postgres MCP server), not
  category-general MCP-platform libraries; out of scope for this
  category-level baseline.

## Sources

- https://github.com/modelcontextprotocol/python-sdk — direct fetch:
  license, star/fork/commit/issue counts, v2 rework framing — retrieved
  2026-08-19
- https://github.com/modelcontextprotocol/typescript-sdk — direct fetch:
  license (Apache-2.0 new / MIT existing), star/commit/issue counts —
  retrieved 2026-08-19
- https://github.com/modelcontextprotocol/inspector — official MCP
  Inspector repo and star count — retrieved 2026-08-19
- https://www.agenticwire.news/article/fastmcp-vs-mcp-python-sdk — the
  official-SDK `FastMCP`→`MCPServer` rename (2026-06-30 v2.0 beta) and the
  standalone-vs-bundled distinction — retrieved 2026-08-19
- https://jlowin.dev/blog/fastmcp-3 and
  https://jlowin.dev/blog/fastmcp-3-launch — standalone FastMCP 3.0 GA
  (2026-02-18), PrefectHQ maintainership — retrieved 2026-08-19
- https://pypi.org/project/fastmcp/ — corroborating standalone-FastMCP
  packaging details — retrieved 2026-08-19
- https://nerova.ai/comparisons/claude-agent-sdk-vs-langgraph-2026,
  https://www.developersdigest.tech/blog/claude-agent-sdk-vs-langgraph,
  https://nomadx.ae/blog/claude-agent-sdk-vs-openai-agents-sdk-2026/ —
  framework positioning/fit comparisons (Claude Agent SDK / OpenAI Agents
  SDK / LangGraph) — retrieved 2026-08-19
- https://github.com/openai/openai-agents-python and
  https://rywalker.com/research/openai-agents-sdk — OpenAI Agents SDK
  license (MIT), star counts, release cadence, pre-1.0 status — retrieved
  2026-08-19
- https://github.com/langchain-ai/langgraph and
  https://github.com/langchain-ai/langgraph/blob/main/LICENSE and
  https://rvernica.github.io/2026/03/langchain-license — LangGraph license
  nuance (MIT core vs. Elastic License 2.0 for `langgraph-api`), star count,
  release recency — retrieved 2026-08-19
- https://www.decisioncrafters.com/pydantic-ai-type-safe-ai-agent-framework-with-16-5k-github-stars/
  and https://www.zenml.io/blog/pydantic-ai-vs-crewai — Pydantic AI license
  (MIT) and star count — retrieved 2026-08-19
- https://ianas.fr/en/blog/2026/06/02/crewai-langchain-langgraph-comparatif-pragmatique/
  and https://www.respan.ai/market-map/compare/crewai-vs-pydantic-ai —
  CrewAI license (MIT) and star-count range — retrieved 2026-08-19
- https://docs.litellm.ai/ and
  https://vercel.com/changelog/litellm-server-now-supported-on-vercel —
  LiteLLM license/purpose and the March-2026 Vercel integration — retrieved
  2026-08-19
- https://ai-sdk.dev/docs/introduction and
  https://vercel.com/docs/ai-sdk — Vercel AI SDK positioning — retrieved
  2026-08-19
- https://dev.to/thedailyagent/top-5-ai-agent-eval-tools-after-promptfoos-exit-576i
  — the May-2026 eval-landscape framing (DeepEval, Inspect AI, OpenAI Evals
  as the open-source convergence; Braintrust/Promptfoo commercial side) —
  retrieved 2026-08-19
- https://github.com/confident-ai/deepeval/blob/main/LICENSE.md and
  https://www.confident-ai.com/frameworks/deepeval — DeepEval license
  (Apache-2.0), download/star figures — retrieved 2026-08-19
- https://github.com/promptfoo and
  https://openai.com/index/openai-to-acquire-promptfoo/ and the OpenAI
  X/Twitter statement confirming continued MIT licensing — Promptfoo
  license, star/fork/contributor counts, 2026-03-09 OpenAI acquisition and
  open-source commitment — retrieved 2026-08-19
- https://uptrace.dev/blog/opentelemetry-ai-systems and
  https://greptime.com/blogs/2026-05-09-opentelemetry-genai-semantic-conventions
  — OTel GenAI semantic conventions license/governance (CNCF/Apache-2.0),
  Development-stability caveat, v1.41/May-2026 status — retrieved 2026-08-19
- https://langfuse.com/resources/engineering/langsmith-alternative,
  https://openobserve.ai/blog/langfuse-vs-langsmith/,
  https://www.datacamp.com/blog/langfuse-vs-langsmith — Langfuse (MIT core,
  ClickHouse acquisition Jan 2026, March-2026 data-model redesign) vs.
  LangSmith (proprietary, Enterprise-only self-hosting, May-2026 SmithDB)
  comparison — retrieved 2026-08-19
- https://github.com/arize-ai/phoenix and
  https://baeseokjae.github.io/posts/arize-phoenix-observability-guide-2026/
  — Arize Phoenix license (Apache-2.0, with one source noting an Elastic
  License 2.0 reference for an unspecified component) and star count —
  retrieved 2026-08-19
- Local precedent (not a web source, read directly):
  `C:\Users\devop\GitHub\MCPg\docs\adr\0002-technology-stack.md` — real
  production stack choices (official `mcp` SDK/`FastMCP`, `psycopg` 3,
  `pglast`, `uv`, `pytest`, `ruff`, `mypy --strict`) — read 2026-08-19

## Open questions for the user

- Several star/adoption figures above came from secondary blog/comparison
  sources rather than a direct GitHub API or repo-page fetch (CrewAI's star
  count varied 25k-44k across sources; per-language SDK maturity beyond
  Python/TS wasn't individually checked). Acceptable to carry these
  single-source, unverified figures into the authored doc with the caveats
  as written, or should authoring do a direct-fetch verification pass on
  each library's repo page before publishing specific numbers?
- The Claude Agent SDK's license terms weren't independently confirmed this
  pass beyond "Anthropic's own SDK license, not a standard OSS license" —
  worth a dedicated check before the authored doc states anything specific
  about redistribution/embedding rights, especially since this skill is
  itself an Anthropic/Claude-ecosystem skill and may want to recommend it
  more prominently.
- Should the authored `preferred-libraries` doc pick one opinionated default
  per category (per this repo's stated authoring convention of "one
  opinionated default"), e.g. "MCP Inspector CLI + DeepEval + Langfuse" as
  the default trio — or present the full comparison table and let the
  project-incubation Q&A logic pick per-project? The research above leans
  toward including full tables since the honest-comparison requirement
  (license/maintenance signals) argued against a single forced pick, but
  the opinionated-default convention from architecture-templates.md's
  ADR-template resolution suggests the authored doc may still want to name
  one default per row.
- LangGraph's `langgraph-api` Elastic-License-2.0 component is a real
  licensing trap for anyone assuming "LangGraph is MIT" — confirm whether
  the authored doc should call this out prominently (a dedicated callout
  box) given how easy it is to miss.
- Promptfoo's OpenAI ownership (since 2026-03-09) is a governance signal
  more than a license problem (license confirmed to remain MIT) — confirm
  whether that nuance (still fine to recommend, but note the conflict of
  interest for evaluating OpenAI's own models) is the right level of
  caution for the authored doc, or whether it should be dropped from the
  default recommendation entirely given the optics.

## Target file(s) + estimated length

- skills/project-incubation/references/preferred-libraries/agentic-mcp-platforms.md
  — est. 260–340 lines (6 category tables/sections plus honest-caveat prose
  for the framework and Promptfoo/LangGraph licensing callouts).
