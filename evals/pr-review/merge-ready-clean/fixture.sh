#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p 'app'
cat > 'app/dates.py' <<'EOF_FIXTURE'
def parse_date(s):
    y, m, d = s.split('-')
    return (int(y), int(d), int(m))  # bug: month/day swapped
EOF_FIXTURE
cat > 'CHANGELOG.md' <<'EOF_FIXTURE'
# Changelog

## [Unreleased]
EOF_FIXTURE
cat > '.pre-commit-config.yaml' <<'EOF_FIXTURE'
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
EOF_FIXTURE
git add -A && git commit -qm "initial"
git checkout -qb fix-parse-date
mkdir -p 'app'
cat > 'app/dates.py' <<'EOF_FIXTURE'
def parse_date(s):
    y, m, d = s.split('-')
    return (int(y), int(m), int(d))
EOF_FIXTURE
mkdir -p 'tests'
cat > 'tests/test_parse_date.py' <<'EOF_FIXTURE'
from app.dates import parse_date

def test_parse_date_month_day_order():
    assert parse_date('2024-03-09') == (2024, 3, 9)
EOF_FIXTURE
cat > 'CHANGELOG.md' <<'EOF_FIXTURE'
# Changelog

## [Unreleased]

### Fixed

- `parse_date` returned month and day swapped.
EOF_FIXTURE
git add -A && git commit -qm "fix: parse_date month/day order"
