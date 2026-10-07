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
mkdir -p 'src/features/checkout'
cat > 'src/features/checkout/Cart.tsx' <<'EOF_FIXTURE'
export const Cart = () => <div style={{ color: '#e11d48', padding: '11px' }}>Cart</div>;
EOF_FIXTURE
mkdir -p 'src/features/checkout'
cat > 'src/features/checkout/Pay.tsx' <<'EOF_FIXTURE'
export const Pay = () => <div style={{ background: '#0f172a', margin: '9px' }}>Pay</div>;
EOF_FIXTURE
mkdir -p 'src/components'
cat > 'src/components/PrimaryButton.tsx' <<'EOF_FIXTURE'
export const PrimaryButton = (p: any) => <button style={{ background: '#3B82F6' }} {...p} />;
EOF_FIXTURE
mkdir -p 'src/features/checkout'
cat > 'src/features/checkout/SubmitButton.tsx' <<'EOF_FIXTURE'
export const SubmitButton = (p: any) => <button style={{ background: '#2563EB' }} {...p} />;
EOF_FIXTURE
mkdir -p 'src/features/profile'
cat > 'src/features/profile/SaveBtn.tsx' <<'EOF_FIXTURE'
export const SaveBtn = (p: any) => <button style={{ background: '#1d4ed8' }} {...p} />;
EOF_FIXTURE
