---
name: react-code-review
description: >-
  Reviews React applications across 11 domains — standards compliance, code
  quality, security, dependency/supply-chain security, performance, concurrency
  & async correctness, idioms & patterns, architecture, observability,
  scalability & resilience, and testing — producing a scored report. Use for
  React 18/19 apps, Next.js/Remix/Vite frontends, component libraries, and
  hooks. Prefer typescript-code-review for pure TS package concerns;
  nodejs-code-review for API servers; ui-system-review for design-system
  token/component consistency across platforms.
---

# React Code Review

Reviews React codebases across **11 domains** with a scored report. Sequential
portable review (no host-specific tooling required).

## Scope and configuration

Look for `react-review-config.toml`; else
[`assets/review-config-template.toml`](assets/review-config-template.toml).

Clarify if needed:

1. **Scope**: full vs diff.
2. **Tier**: `script` | `web` (default) | `enterprise`.
3. **Stack**: CRA/Vite SPA, Next.js (app/pages router), Remix, etc.
4. **TypeScript**: yes/no (TS preferred).

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

[`assets/report-template.md`](assets/report-template.md). Not a design-system audit (see `ui-system-review`) and not a certification.
