# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
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
