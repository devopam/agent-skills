# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `python-code-review` skill: `SKILL.md` (portable sequential-review
  router — no subagent dispatch, no host-specific slash command) + 11
  authored reference docs + 2 assets (`report-template.md`,
  `review-config-template.toml`). A portable rebuild of an existing
  Claude-Code-native tool (`python-code-review-skill-v1.1.tgz`), not a
  from-scratch build — every domain was verified/expanded against
  current sources, not just ported.
- 11 review domains: the original tool's 9 (Standards Compliance, Code
  Quality, Security, Performance, Idioms & Patterns, Architecture,
  Observability, Scalability & Resilience, and a newly-added Testing
  domain) plus 2 real gaps found by a dedicated domain-scoping research
  pass (Dependency & Supply Chain Security, Concurrency & Async
  Correctness) — see `research/python-code-review-domain-scoping.md`.
- `research/python-code-review/` provenance record for all 11 domain
  baselines, plus the original tool's extracted source preserved at
  `research/python-code-review/original-tool/` for reference.
- `project-incubation` skill, v1 complete: `SKILL.md` (inception + audit
  modes, a software/non-software top-level fork, category selection for
  5 stack archetypes), 13 authored reference docs (3 cross-cutting +
  5 stack categories × 2), and 3 assets (`adr-template.md`,
  `baseline-template.md`, `license-guide.md`).
- 5 stack categories: Data & Analytics Platforms, Business Applications,
  Integration & Event-Driven Systems, Backend & API Services, Agentic &
  MCP Platforms. 5 more confirmed for later addition — see
  `research/taxonomy-roadmap.md`.
- `evals/` suite: 5 retrieval scenarios (one per category) + 3 gap
  scenarios, hand-authored against the documented eval format (not yet
  executed — `claude plugin eval` requires early-access enrollment not
  available at authoring time; see `evals/README.md`).
- `research/` provenance record for all 13 baseline areas, kept
  indefinitely per this repo's retention policy (see `CONTRIBUTING.md`).

### Notes
- Every recommendation in the shipped reference docs was verified by
  direct fetch (GitHub API, PyPI, official docs) at authoring time, not
  carried from secondary sources — this surfaced and corrected several
  real errors along the way, including a mis-cited LangGraph star count,
  an incorrect Arize Phoenix license, and a disconfirmed Kong
  licensing-change claim.
- `python-code-review`'s research surfaced its own real corrections: the
  OWASP Top 10 moved 2021→2025 and OWASP's LLM Top 10 moved to a 2026
  edition published weeks before this research; a Django 6.1
  deprecation and a deprecated Uvicorn import path the original tool's
  content predated; and a precise resolution of Python's free-threading
  rollout status (PEP 703 vs. PEP 779's phased plan) that a naive read
  of PEP 703 alone gets wrong.
