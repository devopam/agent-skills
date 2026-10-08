#!/usr/bin/env bash
set -euo pipefail
mkdir -p 'docs'
cat > 'docs/ci-cd-baseline.md' <<'EOF_FIXTURE'
# CI/CD Baseline

**Project:** fixture-service
**Baseline created:** 2026-03-01
**Last audited:** never

## Context

- **Primary platform:** GitHub Actions
- **Language / runtime / packaging:** Python 3.12 + uv
- **Repo shape:** single deployable
- **Deployment target type:** container
- **Maturity / risk posture:** standard service
- **Compliance / policy constraints affecting the pipeline:** none
- **Linked project-incubation baseline:** none

## Pipeline structure

- **Layers present:** PR/MR validation | main/trunk
- **Branching model assumed:** trunk-based
EOF_FIXTURE
mkdir -p '.github/workflows'
cat > '.github/workflows/ci.yml' <<'EOF_FIXTURE'
name: ci
on: [push, pull_request]
permissions: write-all
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@8c5e7a9d0e0f3b4c1a2d5e6f7a8b9c0d1e2f3a4b
      - run: uv run pytest
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/build-push-action@v5
EOF_FIXTURE
