---
name: nodejs-code-review
description: >-
  Reviews Node.js services and tooling across 11 domains — standards compliance,
  code quality, security, dependency/supply-chain security, performance,
  concurrency & async correctness, idioms & patterns, architecture, observability,
  scalability & resilience, and testing — producing a scored report. Use for
  Express/Fastify/Hono/Nest APIs, CLIs, workers, and Node backends. Prefer
  typescript-code-review for pure TS library language issues; prefer
  react-code-review for React UI.
---

# Node.js Code Review

Reviews Node.js applications (JavaScript or TypeScript) across **11 domains**
with a scored report. Sequential domain review; portable to any agentskills.io client.

## Scope and configuration

Look for `nodejs-review-config.toml`; else use
[`assets/review-config-template.toml`](assets/review-config-template.toml).

Clarify if needed:

1. **Scope**: full vs diff (base `main`).
2. **Tier**: `script` | `web` (default) | `enterprise`.
3. **Runtime**: Node version policy (LTS preferred); ESM vs CJS.

## Domains (in order)

1. [Standards Compliance](references/standards-compliance.md)
2. [Code Quality](references/code-quality.md)
3. [Security](references/security.md)
4. [Dependency & Supply Chain Security](references/dependency-supply-chain-security.md)
5. [Performance](references/performance.md)
6. [Concurrency & Async Correctness](references/concurrency-async-correctness.md)
7. [Idioms & Patterns](references/idioms-and-patterns.md)
8. [Architecture](references/architecture.md)
9. [Observability](references/observability.md)
10. [Scalability & Resilience](references/scalability-and-resilience.md)
11. [Testing](references/testing.md)

## Report

[`assets/report-template.md`](assets/report-template.md). No invented paths/lines. Not a certification.
