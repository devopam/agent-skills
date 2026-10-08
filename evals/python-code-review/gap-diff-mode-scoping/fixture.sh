#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p 'app/utils'
cat > 'app/utils/formatting.py' <<'EOF_FIXTURE'
def format_currency(amount, currency='USD'):
    return str(amount) + ' ' + currency
EOF_FIXTURE
mkdir -p 'app'
cat > 'app/db.py' <<'EOF_FIXTURE'
import sqlite3
def get(uid):
    c = sqlite3.connect('x.db')
    return c.execute(f"select * from users where id={uid}").fetchone()  # pre-existing issue, out of scope
EOF_FIXTURE
mkdir -p 'app'
cat > 'app/legacy.py' <<'EOF_FIXTURE'
def f(a, b=[]):
    b.append(a)  # pre-existing issue, out of scope
    return b
EOF_FIXTURE
git add -A && git commit -qm "initial"
git checkout -qb tweak-formatting
mkdir -p 'app/utils'
cat > 'app/utils/formatting.py' <<'EOF_FIXTURE'
def format_currency(amount, currency="USD"):
    return f"{amount:.2f} {currency}"
EOF_FIXTURE
git add -A && git commit -qm "format currency to 2dp"
