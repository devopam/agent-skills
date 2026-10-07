#!/usr/bin/env bash
set -euo pipefail
mkdir -p 'docs'
cat > 'docs/project-incubation-baseline.md' <<'EOF_FIXTURE'
# Project Incubation Baseline

**Project:** orders-api
**Baseline created:** 2026-01-07
**Last audited:** 2026-01-07
**project-incubation skill version:** 0.15.0

## Project shape

- **Path:** software
- **Repo shape:** single project
- **Purpose:** REST API for order management.
- **Team size at incubation:** small team
- **Expected scale / lifespan:** production, long-lived

## Stack category + Architecture template + Preferred libraries snapshot

- **Primary category:** Backend & API Services
- **Architecture template:** Layered service
- **Preferred libraries snapshot date:** 2026-01-07
- **Preferred libraries:** fastapi, pydantic, sqlalchemy, pytest

## LLM/agent component

- **Status:** none

## Drift Log

- 2026-01-07: baseline created
EOF_FIXTURE
cat > 'README.md' <<'EOF_FIXTURE'
# orders-api

REST API for order management.
EOF_FIXTURE
cat > 'LICENSE' <<'EOF_FIXTURE'
MIT License (fixture)
EOF_FIXTURE
mkdir -p 'src/orders_api'
cat > 'src/orders_api/main.py' <<'EOF_FIXTURE'
from fastapi import FastAPI
app = FastAPI()
@app.get('/health')
def health(): return {'ok': True}
EOF_FIXTURE
mkdir -p 'tests'
cat > 'tests/test_health.py' <<'EOF_FIXTURE'
def test_health(): assert True
EOF_FIXTURE
