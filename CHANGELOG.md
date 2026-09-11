# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- (none yet)

## [0.14.0] - 2026-09-11

### Added
- **`ui-system-review` skill:** UI *system* consistency audit for existing
  apps — design tokens/theme, component reuse, icons/media, form factors,
  platform idioms, code-level a11y, governance. Scored domains (0–10),
  findings ordered Critical → Important → Minor → Not Implemented, and
  **required remediation suggestions** (What / Why / direction / evidence).
  - **Web pack** — responsive desktop/tablet/mobile (React/Tailwind/shadcn-style
    and general web patterns).
  - **Apple / SwiftUI pack** — iPhone + iPad (size class / adaptive navigation,
    semantic colors, SF Symbols).
  - **Android / Compose pack** — phone + tablet (`MaterialTheme`,
    `WindowSizeClass`, XML+Compose dual-theme risk).
  - Research under `research/ui-system-review/`; skill under
    `skills/ui-system-review/`.
- **`evals/ui-system-review/` (11 cases):** scorecard+remediation, token drift,
  dual kits, mixed icons, suggest-not-rewrite, evidence rule, no-UI stop,
  Apple hardcoded colors + iPad gap, Android dual theme + tablet claim,
  **fixture-bad-web-expected-findings**.
- **Intentional bad fixture** `evals/ui-system-review/fixtures/bad-web-app/`
  for effectiveness checks (dual MUI+Chakra, hex drift, mixed icons, fixed
  width shell).
- Effectiveness smoke tests (manual): high scores on mature public UIs
  (e.g. shadcn-ui/taxonomy, material-kit-react); low composite on bad fixture.
- **Contributor Covenant 3.0**, GitHub Pages docs, and **llms.txt** (carried
  from prior Unreleased work onto this release line).

### Changed
- Plugin manifest **0.14.0**; six skills listed in description and README.
- Eval inventory **62** hand-authored cases across six skills.

## [0.13.0] - 2026-09-09

### Fixed
- **Cross-skill review pass** across all 5 shipped skills (consistency,
  tool maps, eval coverage).

### Added
- **`postgresql-review` domain deepening**, eval growth, graphify corpus;
  plugin **0.13.0**.

## [0.12.0] - 2026-09-07

### Added
- **`postgresql-review` skill (v0).**

## [0.11.0] - 2026-09-07

### Added
- **`pr-review` skill (v0)** and eval expansion.

## [0.10.1] - 2026-09-01

### Changed
- **`ci-cd-plumber`:** required audit scorecard and baseline close-out.

## [0.10.0] - 2026-09-01

### Added
- **`ci-cd-plumber` skill (v0 core).**

## Prior history

See git history prior to 0.10.0 for `project-incubation` and
`python-code-review` evolution.
