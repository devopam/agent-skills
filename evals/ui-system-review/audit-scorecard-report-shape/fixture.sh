#!/usr/bin/env bash
set -euo pipefail
cat > 'package.json' <<'EOF_FIXTURE'
{
  "name": "fixture-app",
  "private": true,
  "version": "0.0.0",
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "tailwindcss": "3.4.0"
  }
}
EOF_FIXTURE
cat > 'tailwind.config.js' <<'EOF_FIXTURE'
module.exports = { content: ['./src/**/*.{ts,tsx}'], theme: { extend: { colors: { brand: '#2563eb' } } } };
EOF_FIXTURE
mkdir -p 'src'
cat > 'src/App.tsx' <<'EOF_FIXTURE'
export default () => (
  <div className="flex w-[1180px] bg-[#f3f4f6] p-[13px]">
    <aside className="w-[240px] text-[#111]">Nav</aside>
    <main className="bg-brand text-white">Content</main>
  </div>
);
EOF_FIXTURE
mkdir -p 'src/components'
cat > 'src/components/Card.tsx' <<'EOF_FIXTURE'
export const Card = ({ children }: any) => <div className="rounded-lg shadow p-4">{children}</div>;
EOF_FIXTURE
