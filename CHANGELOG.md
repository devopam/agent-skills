# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Contributor Covenant 3.0** (`CODE_OF_CONDUCT.md`): reporting via
  `devopam@gmail.com` (preferred for private matters) or a GitHub Issue;
  linked from README and CONTRIBUTING.
- **GitHub Pages documentation** (MkDocs Material): site source under `docs/`,
  config `mkdocs.yml`, deploy workflow `.github/workflows/docs.yml`.
  Published URL: https://devopam.github.io/agent-skills/
- **`llms.txt`** at the docs site root ([llmstxt.org](https://llmstxt.org/)
  convention): curated index for agents pointing at docs pages and canonical
  `SKILL.md` sources on GitHub.

## [0.13.0] - 2026-09-09

### Fixed
- **Cross-skill review pass** across all 5 shipped skills, from a full read-through
  of each `SKILL.md` + references + evals for internal consistency, MCPg/tool
  accuracy, and eval coverage:
  - `postgresql-review`: fixed a scoring-guide contradiction (a missing
    `pg_stat_statements` no longer scores 9–10), added a verified
    `audit_database` category→domain mapping and missing tool-map entries
    (cross-checked against MCPg's `src/mcpg/audit.py`), trimmed a
    workflow-narrating description, aligned the report template.
  - `ci-cd-plumber`: the release-workflow example no longer ships the exact
    floating-tag anti-pattern it flags as Important; added concrete GitLab
    `id_tokens:` OIDC guidance, a `concurrency:` reference section, and fixed
    a `uv sync --frozen`/`--locked` inconsistency.
  - `pr-review`: fixed a two-severity contradiction, added secret-redaction/
    rotation guidance for the secret-in-diff case, and an explicit
    "suggest, don't edit the diff" boundary.
  - `project-incubation`: added a `## Boundaries` section naming the
    `ci-cd-plumber` handoff (previously unnamed despite an eval requiring it),
    and snapshot-date markers on preferred-libraries docs.
  - `python-code-review`: added the missing "Required Evidence in Findings"
    section to domain docs, an explicit cross-domain finding-dedup rule in
    aggregation, and a tier-gating disclaimer fix in Scalability & Resilience.
  - Additional eval cases covering gaps surfaced (GitLab inception, Critical
    severity, degraded-mode, Not-Implemented coverage, Idioms & Patterns /
    Observability, license/ADR offer, blast-radius).

### Added
- **`postgresql-review` domain deepening:** all 7 reference docs expanded to
  research-baseline target depth via live PostgreSQL docs + MCPg source
  (not memory), each paired with provenance under `research/postgresql-review/`.
  Corrections: RLS `FORCE ROW LEVEL SECURITY` closes table-owner bypass only
  (not superuser/`BYPASSRLS`); `run_advisors` duplicate/redundant-index checks
  listed in the tool map.
- **Eval inventory growth:** 51 hand-authored cases across five skills
  (see `evals/README.md`).
- **graphify corpus map** under `graphify-out/` (refresh after skill changes;
  ~1608 nodes / 1423 edges as of 2026-09-08). Cache paths remain gitignored.

### Changed
- **`project-incubation` research provenance** nested under
  `research/project-incubation/` (was flat under `research/`); cross-references
  updated repo-wide.
- Docs and `.claude-plugin/plugin.json` aligned to **0.13.0**.

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
