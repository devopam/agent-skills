# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **`regulatory-compliance-applicability-scan` (v0 content on main):**
  - Runnable packs: privacy-eu ± de/fr/it, privacy-in, privacy-us/ca/br,
    privacy-ae/sa, domain-fintech, domain-healthcare-pharma
  - Hybrid registry + monthly refresh workflow; coverage matrix; EU overlay
    model; generic **Not covered** for any missing jurisdiction (CN/KR/RU/JP
    planned later — not special-case keywords)
  - **11 evals** (disclaimer, coverage, GDPR gap, unpacked jurisdiction,
    DE limits, no invented articles, suggest-not-certify, DE overlay pairing,
    HIPAA gate, PCI no-certify, multi-jurisdiction intake)
  - README documents skill as Unreleased pending plugin version bump

## [0.14.0] - 2026-09-11

### Added
- **`ui-system-review`** and related. Plugin **0.14.0**.

## [0.13.0] - 2026-09-09

### Fixed
- Cross-skill review pass.

### Added
- postgresql-review deepening; plugin **0.13.0**.

## [0.12.0] - 2026-09-07

### Added
- **`postgresql-review` skill (v0).**

## [0.11.0] - 2026-09-07

### Added
- **`pr-review` skill (v0).**

## [0.10.1] - 2026-09-01

### Changed
- **`ci-cd-plumber`:** audit scorecard and baseline.

## [0.10.0] - 2026-09-01

### Added
- **`ci-cd-plumber` skill (v0 core).**

## Prior history

See git history prior to 0.10.0.
