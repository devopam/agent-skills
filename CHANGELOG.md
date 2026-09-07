# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.12.0] - 2026-09-07

### Added
- **`postgresql-review` skill (v0):** live PostgreSQL review across seven
  domains (health & configuration, schema integrity, indexing, workload &
  query performance, maintenance, security & access, hygiene & conventions).
  **Phase 0 MCPg readiness** requires install, client config, and verified
  reachability for the target database and schema scope before scoring.
  Prefer `MCPG_ACCESS_MODE=read-only`; remediations are suggested SQL/ops only.
  Includes `SKILL.md`, `references/mcpg-tooling.md` + domain refs, report
  template, eval cases, and research under `research/postgresql-review/`.

## [0.11.0] - 2026-09-07

### Added
- **`pr-review` skill (v0):** portable pre-submit and PR change review focused
  on reducing rework — local quality gates (pre-commit / hooks / lint / test),
  intent & blast radius, tests for the change, docs/changelog hygiene, CI
  readiness, and diff-scoped security footguns. Complements (does not replace)
  `python-code-review` for deep Python domain work. Includes `SKILL.md`,
  references (`pre-submit-gates`, `change-risk-and-tests`, `pr-hygiene`),
  report template, and eval suite.
- **Eval expansion across all skills:** new `evals/pr-review/` cases; additional
  `ci-cd-plumber` cases (scorecard shape, baseline close-out, progressive-
  delivery N/A); `project-incubation` handoff-to-ci-cd case; `python-code-review`
  overall scorecard/verdict case. Repo `evals/README.md` updated for four skills.

## [0.10.1] - 2026-09-01

### Changed
- **`ci-cd-plumber`:** Audit mode now **requires** a domain scorecard (0–10
  per domain + composite average), findings ordered by the skill's four
  severity levels (Critical / Important / Minor / Not Implemented), and a
  baseline close-out (Last audited date, Drift Log, optional Last audit
  scores table). `assets/baseline-template.md` gains an optional scores
  section for trend tracking.

## [0.10.0] - 2026-09-01

### Added
- **`ci-cd-plumber` skill (v0 core):** portable CI/CD incubator + auditor.

## Prior history

See git history prior to 0.10.0 for the full record of `project-incubation`
and `python-code-review` evolution (categories, domains, and eval cases).
