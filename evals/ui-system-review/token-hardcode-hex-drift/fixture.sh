#!/usr/bin/env bash
set -euo pipefail
cat > 'package.json' <<'EOF_FIXTURE'
{
  "name": "fixture-app",
  "private": true,
  "version": "0.0.0",
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
EOF_FIXTURE
mkdir -p 'src/theme'
cat > 'src/theme/tokens.css' <<'EOF_FIXTURE'
/* src/theme/tokens.css */
:root { --color-primary: #3B82F6; --color-surface: #ffffff; --space-1: 4px; --space-2: 8px; --space-3: 16px; }
EOF_FIXTURE
mkdir -p 'src/features'
cat > 'src/features/Checkout.tsx' <<'EOF_FIXTURE'
export const Checkout = () => (
  <div style={{ color: '#3B82F6', background: '#fff', padding: '13px', margin: '7px' }}>Pay</div>
);
EOF_FIXTURE
mkdir -p 'src/features'
cat > 'src/features/Profile.tsx' <<'EOF_FIXTURE'
export const Profile = () => (
  <section style={{ borderColor: '#3B82F6', backgroundColor: '#fff', padding: '13px', marginTop: '7px' }}>Profile</section>
);
EOF_FIXTURE
