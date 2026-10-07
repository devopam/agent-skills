#!/usr/bin/env bash
set -euo pipefail
cat > 'README.md' <<'EOF_FIXTURE'
# billing-service

FastAPI backend with a Postgres database.
EOF_FIXTURE
cat > 'pyproject.toml' <<'EOF_FIXTURE'
[project]
name = "billing-service"
version = "1.4.0"
dependencies = ["fastapi", "sqlalchemy", "psycopg[binary]", "alembic"]
EOF_FIXTURE
mkdir -p 'app'
cat > 'app/main.py' <<'EOF_FIXTURE'
from fastapi import FastAPI
from app.db import engine
app = FastAPI()
@app.get('/invoices')
def invoices(): return []
EOF_FIXTURE
mkdir -p 'app'
cat > 'app/db.py' <<'EOF_FIXTURE'
from sqlalchemy import create_engine
engine = create_engine('postgresql+psycopg://app@db/billing')
EOF_FIXTURE
mkdir -p 'alembic/versions'
cat > 'alembic/versions/0001_init.py' <<'EOF_FIXTURE'
# initial migration
EOF_FIXTURE
mkdir -p 'tests'
cat > 'tests/test_invoices.py' <<'EOF_FIXTURE'
def test_invoices(): assert True
EOF_FIXTURE
