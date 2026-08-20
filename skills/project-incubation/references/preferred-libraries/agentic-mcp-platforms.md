# Agentic & MCP Platforms — Preferred Libraries

Star, fork, and license figures below were confirmed by direct fetch
against each repo's GitHub API endpoint (or its raw `LICENSE` file) on
**2026-08-20**, not carried forward from secondary blog coverage. Two
figures in particular turn out to differ meaningfully from what's widely
repeated about them elsewhere — LangGraph's star count and Arize
Phoenix's license — both called out below where they matter. Treat every
number here as a single-snapshot figure that will drift; the license and
governance findings are the more durable part.

`C:\Users\devop\GitHub\MCPg\docs\adr\0002-technology-stack.md` — a real
production MCP server's stack choices (Python 3.12+, the official `mcp`
SDK, `psycopg` 3, `pglast`, `uv`, `pytest`, `ruff`, `mypy --strict`) — is
used as one data point throughout, not the sole justification.

## Table of contents

- [Defaults at a glance](#defaults-at-a-glance)
- [MCP SDKs: official implementations](#mcp-sdks-official-implementations)
- [MCP Inspector: the default testing tool](#mcp-inspector-the-default-testing-tool)
- [High-level Python MCP-server framework: FastMCP vs. MCPServer](#high-level-python-mcp-server-framework-fastmcp-vs-mcpserver)
- [Agent orchestration frameworks](#agent-orchestration-frameworks)
- [Model-provider abstraction](#model-provider-abstraction)
- [Testing and eval tooling for agents](#testing-and-eval-tooling-for-agents)
- [Observability and tracing for LLM and agent runs](#observability-and-tracing-for-llm-and-agent-runs)
- [The default toolchain, end to end](#the-default-toolchain-end-to-end)
- [Claude Agent SDK: licensing, verified](#claude-agent-sdk-licensing-verified)
- [Sources](#sources)

## Defaults at a glance

| Category | Default pick | Reach for something else when… |
|---|---|---|
| MCP SDK | The official SDK for your language (`modelcontextprotocol/python-sdk`, `/typescript-sdk`, or the org's other language SDKs) | Never, for the SDK layer itself — this is the canonical implementation, not a competitive choice |
| Python MCP-server ergonomics | The official SDK's own `MCPServer` class — no extra dependency | Standalone FastMCP's richer decorators, built-in client testing utilities, or proxying/composition are worth the added dependency |
| Agent orchestration | No framework — a raw provider SDK loop | Orchestration itself is genuinely complex: multi-agent handoffs, durable/resumable workflows, human-in-the-loop approval |
| Model-provider abstraction | LiteLLM (Python/backend) or Vercel AI SDK (TS/edge, already on Vercel) | — |
| Testing / eval | MCP Inspector CLI (protocol level) + DeepEval (pytest-native assertions) | Evaluation rigor/auditability matters more than pytest ergonomics → Inspect AI |
| Observability | Langfuse | Team is already fully committed to LangChain/LangGraph and accepts proprietary, non-self-hostable tracing → LangSmith |

Full comparison tables with license and maintenance detail follow each
category below — treat this table as the fast path, not the whole answer.

## MCP SDKs: official implementations

**Default: the official SDK for whatever language the server is written
in.** There's no real competing choice at this layer — it's the
canonical, Anthropic/Linux-Foundation-governed implementation, and it's
what MCPg itself builds on directly.

| Library | For | License | Maintenance/adoption signal (verified 2026-08-20) |
|---|---|---|---|
| `modelcontextprotocol/python-sdk` | Official Python MCP server/client SDK | MIT (project-wide transition of *new* contributions to Apache-2.0 is in progress; legacy code stays MIT) | 24,060 stars, 3,813 forks, 391 open issues. Shipped a v2 rework for the 2026-07-28 spec; v1.x still receives critical fixes on a separate branch. |
| `modelcontextprotocol/typescript-sdk` | Official TypeScript MCP server/client SDK | Same project-wide multi-license transition (Apache-2.0 for new contributions, MIT for pre-transition code) | 13,205 stars, 2,100 forks, 559 open issues. First choice for any MCP server targeting edge/serverless (V8-isolate) runtimes. Also reworked for the 2026-07-28 spec. |
| Official SDKs for Java, Kotlin, C#, Go, Ruby, Swift, PHP, Rust (`modelcontextprotocol` GitHub org) | Non-Python/TS MCP server/client implementations | Varies by repo, predominantly MIT/Apache-2.0 | Anthropic-endorsed org-level SDKs exist for most mainstream languages, but maturity varies — check the org listing for current status per language before committing rather than assuming parity with the Python/TS SDKs. Not individually star-checked. |

## MCP Inspector: the default testing tool

**Default: use it regardless of implementation language.** `modelcontextprotocol/inspector`
is the official visual/CLI/TUI testing tool for any MCP server — 10,702
stars, 1,487 forks, 50 open issues as of a 2026-08-20 direct fetch. It ships Web, scriptable CLI, and
Ink-based TUI modes; the CLI mode is the one to wire into CI for
protocol-level integration tests (layer 3 of the testing model in the
companion [stack doc](../stacks/agentic-mcp-platforms.md)).

**Security note, carried forward and worth repeating**: versions below
0.14.1 carried a CVSS 9.4 remote-code-execution vulnerability
(CVE-2025-49596). Pin a patched version — don't let this be the one
dependency in the stack nobody version-pins because "it's just a dev
tool."

## High-level Python MCP-server framework: FastMCP vs. MCPServer

**Naming collision, resolved explicitly**: the official SDK's own
bundled high-level server class was itself called `FastMCP` until a
2026-06-30 v2.0 beta renamed it to `MCPServer` specifically to reduce
confusion with the standalone project of the same earlier name. Use
`MCPServer` (official SDK) and `FastMCP` (standalone `PrefectHQ/fastmcp`
project) as the disambiguating terms — both names show up in older
tutorials referring to different things.

**Default: for a from-scratch MCP server, the raw official SDK (its
bundled `MCPServer` class) is sufficient**, and it's what MCPg itself
uses per ADR-0002. Reach for standalone FastMCP when its added ergonomics
— richer typed decorators, built-in client testing utilities,
proxying/composition features — are worth the extra dependency. It is not
a mandatory layer on top of the SDK; treat it as an ergonomics upgrade,
not a prerequisite.

Standalone FastMCP (`PrefectHQ/fastmcp`, moved from the original
`jlowin/fastmcp`) reached a 3.0 GA on 2026-02-18 and is now maintained
under PrefectHQ: 27,300 stars, 2,255 forks, 269 open issues, Apache-2.0,
confirmed by direct fetch 2026-08-20. A widely-repeated adoption claim
("powers 70% of MCP servers," ~1M downloads/day) traces to a single,
apparently vendor/author-adjacent source with no independent
corroboration — not repeated here as a figure.

## Agent orchestration frameworks

**Honesty check, stated plainly**: for *building an MCP server*, none of
the frameworks below are needed — the raw MCP SDK is the better-regarded
choice, and MCPg's own production server confirms this in practice (no
agent-orchestration framework anywhere in its dependency tree). The
frameworks below matter for the *agent/client* side — the thing that
reasons over multiple steps and calls MCP (or other) tools along the way.

**Default even there: no framework, a raw provider SDK loop**, until the
orchestration itself is genuinely complex — multi-agent handoffs,
durable/resumable long-running workflows, human-in-the-loop approval
steps. Once one of those is real, pick by shape: LangGraph for maximum
control over state/persistence/resumability, OpenAI Agents SDK for
handoff-centric multi-agent routing, or the Claude Agent SDK when the
product wants Claude's own working-agent loop embedded directly (see the
[licensing section](#claude-agent-sdk-licensing-verified) below before
committing to that one).

| Library | For | License | Why (or not) | Maintenance/adoption signal (verified 2026-08-20 unless noted) |
|---|---|---|---|---|
| Claude Agent SDK (Anthropic) | Single-agent, environment-driven work (code, files, systems, long autonomous runs) inside Claude's own tool-use loop | See dedicated section below — it's more nuanced than a single license tag | Best fit when the product wants "Claude Code's working-agent loop" embedded in an application; MCP is its native tool-integration layer | Actively developed by Anthropic; not a traditional community-stars OSS project, so no star count applies |
| OpenAI Agents SDK (`openai/openai-agents-python`, `openai-agents-js`) | Multi-agent workflows with explicit handoffs/guardrails; voice agents (JS variant) | MIT | Strong fit when the job is routing between specialist agents rather than one agent working an environment | 28,775 stars / 4,538 forks (Python), 3,660 stars / 923 forks (JS). Python package at v0.22.0 — still pre-1.0 roughly 18 months after launch, a real API-stability caveat to weigh. |
| **LangGraph** (`langchain-ai/langgraph`) | Low-level, graph-based agent runtime: explicit state, persistence, interrupts/resumability, production control | Core (`langgraph`, `langchain-core`, model integrations): MIT. **See the licensing callout immediately below — `langgraph-api` is a separate, non-permissive license.** | Most control of any option here, at the cost of more boilerplate; the right choice when the product *is* the orchestration | 40,044 stars, 6,742 forks, 702 open issues (direct fetch, 2026-08-20) — well below the 126k+ figures sometimes quoted for "LangGraph." The separate `langchain-ai/langchain` repo has 144,582 stars (also verified 2026-08-20); figures in that range are for `langchain`, not `langgraph`. 40k is the confirmed count for `langchain-ai/langgraph` itself. |
| Pydantic AI (`pydantic/pydantic-ai`) | Type-safe agent framework for Python teams already invested in Pydantic | MIT | Appreciated by data/Python teams wanting production type-safety without LangGraph's lower-level ceremony | 19,400 stars, 2,561 forks, 723 open issues |
| CrewAI (`crewAIInc/crewAI`) | Role-playing multi-agent scenarios (defined "crew" of agents with roles) | MIT | Popular for role-based multi-agent scripting; weaker fit than the above for single-agent environment-driven work | 57,343 stars, 8,194 forks, 821 open issues |

> **LangGraph licensing trap — read this before assuming "LangGraph is
> MIT."** The `langgraph` and `langchain-core` packages, and the model
> integrations, are MIT. The **`langgraph-api` package specifically is
> Elastic License 2.0 (ELv2)** — confirmed directly against its PyPI
> metadata (license field `Elastic-2.0`, latest version `0.12.6` as of
> 2026-08-20). ELv2 is not permissive OSS: among other restrictions, it
> prohibits offering the licensed software as a hosted or managed service
> to third parties without a separate commercial agreement. If a
> deployment pulls in `langgraph-api` (the piece that serves LangGraph
> Cloud-style deployments) rather than just the core graph library, it is
> **not** running under the MIT terms someone would reasonably assume from
> "LangGraph is MIT." Check which package a given deployment actually
> depends on before making any licensing claim about it.

## Model-provider abstraction

**Default: LiteLLM for a Python/backend service; Vercel AI SDK for a
TypeScript/JS app already on Vercel's edge platform.** Neither entry
below carries a specific adoption number — the choice here turns on
runtime fit more than popularity.

| Library | For | License | Why recommended |
|---|---|---|---|
| LiteLLM | In-process unified interface to 100+ LLM providers (OpenAI-compatible call shape); also ships a standalone proxy/gateway mode | MIT | Simplest path to model-switching/fallback for a single service; works standalone or as a dependency inside LangChain/LlamaIndex-style stacks. Gained a first-party Vercel deployment integration in 2026, a signal of continued ecosystem investment. |
| Vercel AI SDK (`ai-sdk.dev`) | Unified provider API for TypeScript/JS apps, especially ones already on Vercel | Apache-2.0 | Two-line model swap; tightest integration with Vercel's edge/serverless deployment story and its AI Gateway. |

## Testing and eval tooling for agents

**Default: MCP Inspector CLI for protocol-level checks, DeepEval for
pytest-native assertions on model/agent output.** DeepEval fits directly
into the same `pytest` convention MCPg itself already uses, which is the
deciding factor over the alternatives below for a Python-first stack —
reach for Inspect AI instead when evaluation rigor and auditability
matter more than pytest ergonomics (public-sector or safety-evaluation
contexts, for instance).

| Library | For | License | Why recommended (or not) | Maintenance/adoption signal |
|---|---|---|---|---|
| `modelcontextprotocol/inspector` | Protocol-level manual + scripted testing of any MCP server | MIT, per the repo's own About sidebar — note there's no standalone `LICENSE` file at the repo root for GitHub's automated detector to key off, so this reads from `package.json` rather than a dedicated file; confirm before relying on it for a compliance-sensitive use | Official, transport-agnostic; CLI mode is CI-friendly | 10,702 stars — see the security-pin note above |
| **DeepEval** (`confident-ai/deepeval`) | pytest-native unit/integration assertions for LLM and agent output, with built-in LLM-as-judge metrics | Apache-2.0 | Fits directly into an existing pytest suite; Python and TypeScript support | 17,712 stars, 1,828 forks, 469 open issues (verified 2026-08-20) |
| Inspect AI (UK AI Security Institute) | Registry-style, rigorous agent/model evaluation, notably used in public-sector/safety evaluation contexts | MIT | A credible choice when evaluation rigor/auditability matters more than pytest-native ergonomics; one of the more established open eval frameworks alongside DeepEval and OpenAI Evals | Actively maintained by the UK AI Security Institute; not independently version-pinned in this doc |
| Promptfoo | CLI for prompt/LLM-app regression testing, red-teaming, multi-provider comparison | MIT — confirmed to remain MIT post-acquisition | Strong for regression-testing prompts/tool-selection across provider changes; wide adoption | 24,386 stars, 2,211 forks, 510 open issues (verified 2026-08-20). **Governance note**: OpenAI acquired Promptfoo on 2026-03-09 (~$86M); OpenAI's public statement commits to keeping it open source under the current MIT license, but a non-OpenAI team should still weigh the vendor-objectivity question this creates for a tool used to evaluate OpenAI's own models among others. Not a reason to avoid it — a reason to know who owns it. |

## Observability and tracing for LLM and agent runs

**Default: Langfuse.** It's the leading open, self-hostable option,
framework-agnostic via OTel-based tracing plus 20+ native integrations,
and — after the verification pass below — the more clearly permissive
choice among the open-source contenders.

| Library | For | License | Why recommended (or not) | Maintenance/adoption signal |
|---|---|---|---|---|
| OpenTelemetry GenAI semantic conventions | Standardized span/attribute naming (`gen_ai.*`) for LLM calls, agent/workflow spans, tool-call spans, token-usage metrics | Apache-2.0 (CNCF/OpenTelemetry project) | Vendor-neutral, and the direction observability backends and frameworks are converging on | Reported as emitted directly by several coding agents by mid-2026, but attributes remain **Development**-stability as of v1.41 (May 2026) — don't build alerting on attribute names that can still change without a major-version bump |
| **Langfuse** | Self-hostable LLM/agent tracing, prompt management, evaluation | Core: MIT — verified directly against the repo's `LICENSE` file (standard MIT text; enterprise-only directories are carved out separately, the usual open-core pattern) | The open, self-hostable default; framework-agnostic | 33,414 stars, 3,595 forks, 798 open issues (verified 2026-08-20). ClickHouse acquired Langfuse in January 2026; core stayed MIT and self-hosting continued post-acquisition. A March-2026 data-model redesign leans further into ClickHouse as the storage backend — worth re-checking self-host complexity if that dependency matters to a given deployment. |
| LangSmith | LangChain/LangGraph-native hosted tracing and evaluation | **Proprietary** — client SDKs are open source, but backend/UI/storage are closed; self-hosting is Enterprise-only | Deepest native integration if a team is already fully committed to LangChain/LangGraph; **not the default** for teams wanting an open, self-hostable observability layer — named for honest comparison, not as the preferred pick | LangChain shipped "SmithDB," a purpose-built trace database, in May 2026, reporting up to 15x faster core experiences for LangSmith Cloud — a real investment signal that doesn't change the licensing/self-hosting trade-off |
| Arize Phoenix (`Arize-ai/phoenix`) | LLM/agent observability and evaluation, OTel-native | **Elastic License 2.0 (ELv2)** — verified directly against the repo's `LICENSE` file and PyPI metadata, 2026-08-20 | Phoenix is often described as Apache-2.0. It isn't: ELv2 governs the whole repository, not an isolated component, and carries the same non-permissive, no-hosted-service-resale restriction as `langgraph-api` above. That's the deciding factor against naming it the default here — Langfuse's confirmed MIT core is the more clearly permissive open option. | 11,118 stars, 1,067 forks, 946 open issues |

## The default toolchain, end to end

Putting the category defaults together into one concrete recommendation,
informed by the license and maintenance data verified above: **MCP
Inspector CLI (protocol-level testing) + DeepEval (pytest-native
assertions) + Langfuse (open, self-hostable tracing)** is the default
trio for a from-scratch MCP-server-adjacent agent project. All three are
permissively licensed (MIT/Apache-2.0 core), all three fit a Python
`pytest`-based workflow without forcing a framework commitment, and none
of the three requires accepting a proprietary or ELv2-restricted
dependency to get started. Swap in Inspect AI over DeepEval for
higher-rigor evaluation needs, or LangSmith over Langfuse only if the
project is already fully committed to the LangChain/LangGraph ecosystem
and the proprietary self-hosting trade-off is acceptable.

## Claude Agent SDK: licensing, verified

Because this skill is itself Claude-ecosystem-adjacent, its license terms
were checked directly against both official repos on 2026-08-20 rather
than assumed:

- **`anthropics/claude-agent-sdk-python`** ships a standard **MIT**
  `LICENSE` file (copyright 2025, Anthropic PBC) and displays an MIT
  license badge on its README. The code itself can be redistributed and
  embedded under ordinary MIT terms. Separately, the README's "License
  and terms" section states that *use* of the SDK is governed by
  Anthropic's [Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms),
  "including when you use it to power products and services that you
  make available to your own customers and end users." Read that
  correctly: it's the standard terms-of-service layer that applies to
  *calling the Claude API* through any means, SDK or not — not an
  SDK-specific redistribution restriction stacked on top of MIT. Code
  license and API-usage terms are two different things here, and both
  apply simultaneously.
- **`anthropics/claude-agent-sdk-typescript`** does **not** carry the same
  MIT badge or MIT-licensed file — there is no plain `LICENSE` file in the
  repo at all, only a `LICENSE.md`. That file's content reads as an
  all-rights-reserved notice ("© Anthropic PBC. All rights reserved. Use
  is subject to Anthropic's Commercial Terms of Service"), with no
  separate permissive code license identified anywhere in the repo. This
  is a real, verified divergence from the Python package's own MIT
  `LICENSE` file — not an assumption that the two packages match.

**Practical guidance**: for the Python SDK, MIT-terms redistribution of
the code is confirmed. For the TypeScript SDK, do not assume the same —
verify the current `LICENSE.md` per package directly before redistributing
or embedding it in a product. Either way, and regardless of which
package's code license applies, actually calling Claude through the SDK
is always subject to Anthropic's Commercial Terms of Service, the same as
calling the API directly with no SDK involved at all.

## Sources

- https://github.com/modelcontextprotocol/python-sdk (and its API mirror
  at https://api.github.com/repos/modelcontextprotocol/python-sdk) —
  direct fetch 2026-08-20: star/fork/issue counts, MIT license
  confirmation.
- https://github.com/modelcontextprotocol/typescript-sdk and
  https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/LICENSE
  — direct fetch 2026-08-20: star/fork/issue counts, multi-license
  transition text.
- https://github.com/modelcontextprotocol/inspector — direct fetch
  2026-08-20: star/fork/issue counts, MIT per About sidebar (no
  standalone `LICENSE` file at repo root).
- https://www.agenticwire.news/article/fastmcp-vs-mcp-python-sdk — the
  official-SDK `FastMCP` → `MCPServer` rename (2026-06-30 v2.0 beta) and
  the standalone-vs-bundled distinction. Retrieved 2026-08-19.
- https://github.com/PrefectHQ/fastmcp (originally `jlowin/fastmcp`) —
  direct fetch 2026-08-20: star/fork/issue counts, Apache-2.0 license,
  PrefectHQ ownership confirmed. https://jlowin.dev/blog/fastmcp-3 and
  `/fastmcp-3-launch` corroborate the 2026-02-18 3.0 GA date. Retrieved
  2026-08-19.
- https://github.com/openai/openai-agents-python and
  https://github.com/openai/openai-agents-js — direct fetch 2026-08-20:
  star/fork/issue counts, MIT license. https://pypi.org/pypi/openai-agents/json
  — direct fetch 2026-08-20: v0.22.0, confirming pre-1.0 status.
- https://github.com/langchain-ai/langgraph and its raw `LICENSE` —
  direct fetch 2026-08-20: 40,044 stars, MIT core license confirmed.
  https://github.com/langchain-ai/langchain — direct fetch 2026-08-20:
  144,582 stars, confirming that larger figures sometimes quoted for
  "LangGraph" belong to the separate `langchain` repo.
  https://pypi.org/pypi/langgraph-api/json — direct fetch 2026-08-20:
  license field `Elastic-2.0`, version 0.12.6, confirming the
  licensing-trap callout above.
- https://github.com/pydantic/pydantic-ai — direct fetch 2026-08-20:
  star/fork/issue counts, MIT license.
- https://github.com/crewAIInc/crewAI — direct fetch 2026-08-20: 57,343
  stars, MIT license.
- https://docs.litellm.ai/ and
  https://vercel.com/changelog/litellm-server-now-supported-on-vercel —
  LiteLLM purpose and the March-2026 Vercel integration. Retrieved
  2026-08-19.
- https://ai-sdk.dev/docs/introduction and
  https://vercel.com/docs/ai-sdk — Vercel AI SDK positioning. Retrieved
  2026-08-19.
- https://github.com/confident-ai/deepeval — direct fetch 2026-08-20:
  17,712 stars, Apache-2.0 license confirmed.
- https://dev.to/thedailyagent/top-5-ai-agent-eval-tools-after-promptfoos-exit-576i
  — the eval-landscape framing (DeepEval, Inspect AI, OpenAI Evals as the
  open-source convergence). Retrieved 2026-08-19.
- https://github.com/promptfoo/promptfoo — direct fetch 2026-08-20: 24,386
  stars, MIT license confirmed. OpenAI's acquisition announcement
  (2026-03-09, ~$86M) and public commitment to keep Promptfoo MIT-licensed
  — https://openai.com/index/openai-to-acquire-promptfoo/ — retrieved
  2026-08-19.
- https://uptrace.dev/blog/opentelemetry-ai-systems and
  https://greptime.com/blogs/2026-05-09-opentelemetry-genai-semantic-conventions
  — OTel GenAI conventions license/governance and Development-stability
  status (v1.41, May 2026). Retrieved 2026-08-19.
- https://github.com/langfuse/langfuse and its raw `LICENSE` — direct
  fetch 2026-08-20: 33,414 stars, MIT core confirmed (enterprise
  directories carved out separately). ClickHouse acquisition (January
  2026) and March-2026 data-model redesign per
  https://langfuse.com/resources/engineering/langsmith-alternative and
  https://www.datacamp.com/blog/langfuse-vs-langsmith, retrieved
  2026-08-19.
- https://github.com/Arize-ai/phoenix and its `LICENSE` file (both the
  GitHub blob view and https://pypi.org/pypi/arize-phoenix/json) — direct
  fetch 2026-08-20: 11,118 stars, Elastic License 2.0 confirmed for the
  whole repository and the PyPI package alike.
- https://github.com/anthropics/claude-agent-sdk-python and
  https://github.com/anthropics/claude-agent-sdk-typescript — direct
  fetch 2026-08-20: LICENSE file contents, README "License and terms" sections,
  confirming the Python package's MIT code license plus Commercial-ToS
  usage terms, and the TypeScript package's all-rights-reserved
  `LICENSE.md` with no separate permissive code license identified.
  Anthropic Commercial Terms of Service —
  https://www.anthropic.com/legal/commercial-terms — retrieved 2026-08-20.
- Local precedent (not a web source, read directly):
  `C:\Users\devop\GitHub\MCPg\docs\adr\0002-technology-stack.md` — real
  production stack choices. Read 2026-08-19.
