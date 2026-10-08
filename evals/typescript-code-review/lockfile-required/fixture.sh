#!/usr/bin/env bash
set -euo pipefail
cat > 'package.json' <<'EOF_FIXTURE'
{
  "name": "web",
  "private": true,
  "dependencies": { "express": "^4.19.0", "zod": "^3.23.0" },
  "devDependencies": { "typescript": "^5.4.0" }
}
EOF_FIXTURE
cat > 'tsconfig.json' <<'EOF_FIXTURE'
{ "compilerOptions": { "strict": true, "target": "ES2022", "module": "NodeNext", "outDir": "dist" } }
EOF_FIXTURE
mkdir -p 'src'
cat > 'src/index.ts' <<'EOF_FIXTURE'
import express from 'express';
const app = express();
app.get('/health', (_req, res) => res.json({ ok: true }));
app.listen(3000);
EOF_FIXTURE
