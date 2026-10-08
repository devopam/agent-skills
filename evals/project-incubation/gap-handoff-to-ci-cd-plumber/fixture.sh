#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p 'docs'
cat > 'docs/project-incubation-baseline.md' <<'EOF_FIXTURE'
# Project Incubation Baseline

**Project:** orders-api
**Baseline created:** 2026-09-01
**Last audited:** 2026-09-01

## Project shape

- **Path:** software
- **Repo shape:** single project
- **Purpose:** REST API for order management.

## Stack

- **Primary category:** Backend & API Services
- **Language:** Python 3.12 (FastAPI, uv)
- **Compliance:** none
- **LLM/agent component:** none
EOF_FIXTURE
mkdir -p '.github/workflows'
cat > '.github/workflows/ci.yml' <<'EOF_FIXTURE'
name: ci
on: [push]
jobs:
  placeholder:
    runs-on: ubuntu-latest
    steps:
      - run: echo 'TODO: real CI'
EOF_FIXTURE
cat > 'README.md' <<'EOF_FIXTURE'
# orders-api
EOF_FIXTURE
