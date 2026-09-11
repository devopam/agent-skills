# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **`ui-system-review` skill (v0→packs):** UI *system* consistency audit —
  tokens/theme, component reuse, icons/media, form factors, platform idioms,
  code-level a11y, governance. Scored domains, severity-ordered findings,
  **remediation suggestions**. Packs: **Web** (responsive),
  **Apple/SwiftUI** (iPhone+iPad), **Android/Compose** (phone+tablet).
  Research under `research/ui-system-review/`; skill under
  `skills/ui-system-review/`.
- **`evals/ui-system-review/` (10 cases):** web drift, dual kits, icons,
  remediation, evidence, no-UI, Apple hardcoded colors + iPad gap, Android
  XML+Compose dual theme + tablet claim.
- **Contributor Covenant 3.0** (`CODE_OF_CONDUCT.md`).
- **GitHub Pages** + **`llms.txt`** (see prior Unreleased notes / site).

## [0.13.0] - 2026-09-09

### Fixed
- **Cross-skill review pass** across all 5 shipped skills (see full notes in
  git history for 0.13.0).

### Added
- **`postgresql-review` domain deepening**, eval growth to 51 cases, graphify
  corpus map; plugin **0.13.0**.

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
