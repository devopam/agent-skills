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
    "lucide-react": "0.300.0",
    "@heroicons/react": "2.1.0",
    "@mui/icons-material": "5.15.0",
    "@mui/material": "5.15.0"
  }
}
EOF_FIXTURE
mkdir -p 'src/screens'
cat > 'src/screens/Home.tsx' <<'EOF_FIXTURE'
import { Home } from 'lucide-react';
export const S = () => <Home />;
EOF_FIXTURE
mkdir -p 'src/screens'
cat > 'src/screens/Settings.tsx' <<'EOF_FIXTURE'
import { Cog6ToothIcon } from '@heroicons/react/24/outline';
export const S = () => <Cog6ToothIcon />;
EOF_FIXTURE
mkdir -p 'src/screens'
cat > 'src/screens/Billing.tsx' <<'EOF_FIXTURE'
import PaymentIcon from '@mui/icons-material/Payment';
export const S = () => <PaymentIcon />;
EOF_FIXTURE
