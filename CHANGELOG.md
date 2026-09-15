# Changelog

All notable changes to this repository's skills are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **`regulatory-compliance-applicability-scan` (in progress toward a full 0.15.0):**
  - First-wave runnable packs (EU±DE/FR/IT, IN, US-CA, CA, BR, AE, SA, fintech, healthcare)
  - Generic not-covered rule; major-economy **research** started (CN PIPL, KR PIPA,
    JP APPI, RU 152-FZ) — not runnable yet
  - 11 evals; hybrid registry; monthly refresh workflow
  - Refresh **timed retries** (3 attempts, 2s/5s/10s backoff, 20s timeout)

### Notes
- **0.15.0 not cut** until coverage expansion is a logical win

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
