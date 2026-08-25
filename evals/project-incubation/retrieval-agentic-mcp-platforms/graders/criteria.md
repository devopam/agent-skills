# Grading criteria: retrieval — Agentic & MCP Platforms

Tests whether `project-incubation` correctly routes an MCP-server-shaped
project to the right category and surfaces its actual (not generic)
guidance.

## Must show

- Invokes/follows the `project-incubation` skill (this is what
  `--ablation with-without` checks via `tool_used: Skill`).
- Asks the software-vs-non-software fork question before anything
  category-specific (this is a software project, but the question should
  still be asked, not skipped).
- Selects **Agentic & MCP Platforms** as the category — not Backend & API
  Services (a plausible but wrong adjacent pick, since MCP servers are
  services with an API surface).
- Surfaces category-specific content, not generic advice — at least one of:
  hexagonal/ports-and-adapters named as the default pattern for MCP
  servers, transport choice (stdio vs. Streamable HTTP vs. SSE), or the
  tool-poisoning security consideration.
- Recommends concrete libraries from `references/preferred-libraries/agentic-mcp-platforms.md`
  (e.g. the official MCP SDK, MCP Inspector) rather than generic "pick a
  framework" advice.
- Does not force a compliance-signal discussion when the user stated none
  applies.

## Should not show

- Treating this as a Backend & API Services project.
- Generic "here's a basic project structure" advice that doesn't draw on
  the category-specific reference doc at all.
- Skipping the LLM/agent-component question — even though the answer is
  obviously yes here, the question should still be asked explicitly per
  the skill's own flow, not silently assumed.
