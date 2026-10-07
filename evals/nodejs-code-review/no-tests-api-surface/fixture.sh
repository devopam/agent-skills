#!/usr/bin/env bash
set -euo pipefail
cat > 'package.json' <<'EOF_FIXTURE'
{
  "name": "api",
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "4.19.0" }
}
EOF_FIXTURE
cat > 'server.js' <<'EOF_FIXTURE'
const app = require('express')();
app.use(require('./src/routes/users'));
app.use(require('./src/routes/orders'));
app.use(require('./src/routes/auth'));
app.listen(3000);
EOF_FIXTURE
mkdir -p 'src/routes'
cat > 'src/routes/users.js' <<'EOF_FIXTURE'
const r = require('express').Router();
r.get('/users', (q, s) => s.json([]));
r.post('/users', (q, s) => s.sendStatus(201));
r.put('/users/:id', (q, s) => s.sendStatus(204));
r.delete('/users/:id', (q, s) => s.sendStatus(204));
module.exports = r;
EOF_FIXTURE
mkdir -p 'src/routes'
cat > 'src/routes/orders.js' <<'EOF_FIXTURE'
const r = require('express').Router();
r.get('/orders', (q, s) => s.json([]));
r.post('/orders', (q, s) => s.sendStatus(201));
r.post('/orders/:id/refund', (q, s) => s.sendStatus(202));
module.exports = r;
EOF_FIXTURE
mkdir -p 'src/routes'
cat > 'src/routes/auth.js' <<'EOF_FIXTURE'
const r = require('express').Router();
r.post('/login', (q, s) => s.json({ ok: true }));
r.post('/logout', (q, s) => s.sendStatus(204));
module.exports = r;
EOF_FIXTURE
