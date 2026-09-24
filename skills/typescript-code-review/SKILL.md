---
name: typescript-code-review
description: >-
  Reviews TypeScript code across 11 domains — standards compliance, code quality,
  security, dependency/supply-chain security, performance, concurrency & async
  correctness, idioms & patterns, architecture, observability, scalability &
  resilience, and testing — producing a scored report. Use for TypeScript
  libraries, apps, or shared packages; for React-specific UI patterns prefer
  react-code-review; for Node runtime/service concerns prefer nodejs-code-review.
---

# TypeScript Code Review

Reviews a TypeScript project (or changed files) across **11 domains** and
produces a scored report with concrete file-and-line findings. Portable:
read code and reference files sequentially — no host-specific slash commands.

## Scope and configuration

Look for `typescript-review-config.toml` in the project root. If absent, apply
defaults from [`assets/review-config-template.toml`](assets/review-config-template.toml).

Ask only what is still unclear:

1. **Scope**: full project (`.ts` / `.tsx` excluding generated) or **diff** vs base branch (default `main`).
2. **Tier**: `script` | `web` (default) | `enterprise`.
3. **Sibling skills**: If the tree is primarily React UI, note that `react-code-review` may go deeper on components/hooks; if primarily Node services, `nodejs-code-review` may go deeper on runtime/HTTP. This skill remains valid for shared TS packages and language-level quality.

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

For each domain: read the reference file, review in-scope files, score **1–10**, list findings (Critical / Important / Minor), then proceed. Do not skip the reference file.

## Report

Use [`assets/report-template.md`](assets/report-template.md). Overall score = mean of domain scores unless config weights differ. Never invent file paths or line numbers.

## Boundaries

- TypeScript/JavaScript source and config (`tsconfig`, ESLint, package manifests).
- Does not replace `react-code-review` or `nodejs-code-review` for stack-specific depth.
- Does not certify security or compliance.
