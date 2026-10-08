# Changelog

## [0.18.0] - 2026-10-08

### Fixed
- **`claude plugin eval` now loads every case.** Grader files lacked `type`/`weight` front matter, so all cases failed with `invalid case.yaml: graders: Required`.

### Changed
- Evals restructured to `evals/<skill>/<case>/prompt.md` + `graders/*.md` (149 cases); the 65 flat `.md` cases are converted. Case names are unique (`<skill>-<case>`).
- Each case that starts a fresh task has a `skill-fired` grader (`tool_used: Skill`, with-only arm).
- Cases that describe repo files ship `fixture.sh` + `case.yaml` scaffolds (run with `--scaffold`); code-review cases embed target code; postgresql cases supply MCPg results inline.
- Stale cases removed or refreshed (`not-covered-japan`, `not-covered-de-overlay`, Cuba as the unpacked-jurisdiction example).
- Skill trigger descriptions extended for python-code-review, pr-review, project-incubation, ci-cd-plumber, postgresql-review and regulatory-compliance-applicability-scan.
- python-code-review: rate limiting is reported once, under Security. project-incubation: ADR offer is an explicit question; a license recommendation is always stated.
- Docs: `docs/evals.md` and `evals/README.md` describe the layout, `--scaffold`, and rubric guidance.
- Plugin version **0.18.0**.

### Notes
- Latest measured results are mixed: roughly three quarters of cases passed in the last full pass, about nine cases are flaky across runs, and `pr-review-merge-ready-clean` does not reliably fire its skill. See `RELEASE-NOTES-v0.18.0.md`.

## [0.17.0] - 2026-09-24

### Added
- **`typescript-code-review`** — 11-domain scored TypeScript review (config, report template, domain refs, evals).
- **`nodejs-code-review`** — 11-domain scored Node.js service/API review.
- **`react-code-review`** — 11-domain scored React/Next UI review.
- Expanded evals for the three new skills (security, async, testing, boundaries).
- Plugin version **0.17.0**.

### Notes
- Domain reference docs are v0 baselines (actionable checks); depth can grow toward the Python skill’s longer references.
- Use with `ui-system-review` when the ask is design-system tokens/components across platforms.

## [0.16.0] - 2026-09-17

### Added / expanded
- **`regulatory-compliance-applicability-scan`**: Stage I geographic close-out, force/thin-pack re-checks, EU overlay article-level depth (DE FR IT ES NL AT SE PL).
- See `RELEASE-NOTES-v0.16.0.md`.

## [0.15.0] - 2026-09-16

### Added
- **`regulatory-compliance-applicability-scan`** first skill release cut:
  - Stages A–F global privacy packs + domain packs
  - Registry + refresh with retries; evals; Stage G baseline
- Plugin version **0.15.0**

## [0.14.0] - 2026-09-11

### Added
- `ui-system-review`. Plugin **0.14.0**.

## Prior

See git history.
