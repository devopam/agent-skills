#!/usr/bin/env bash
set -euo pipefail
cat > 'README.md' <<'EOF_FIXTURE'
# Fixture: bad-web-app (intentional anti-patterns)

**Not a real application.** Synthetic tree for `ui-system-review` effectiveness
checks. Known injected problems:

1. Dual full UI kits: `@mui/material` + `@chakra-ui/react` + both providers
2. Token file exists but product UI hardcodes hex / magic spacing
3. Three icon libraries with no policy
4. Fixed pixel shell only — no responsive breakpoints
5. Clickable `div` primary action (a11y footgun)

Expected audit outcome: multiple **Important/Critical** findings, non-trivial
remediation section, Tokens / System foundation / Icons / Form factors scored
low.
EOF_FIXTURE
cat > 'package.json' <<'EOF_FIXTURE'
{
  "name": "bad-web-app-fixture",
  "private": true,
  "version": "0.0.0",
  "dependencies": {
    "@chakra-ui/react": "2.8.2",
    "@emotion/react": "11.11.0",
    "@emotion/styled": "11.11.0",
    "@heroicons/react": "2.1.0",
    "@mui/icons-material": "5.15.0",
    "@mui/material": "5.15.0",
    "lucide-react": "0.300.0",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
EOF_FIXTURE
mkdir -p 'src'
cat > 'src/App.tsx' <<'EOF_FIXTURE'
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { ChakraProvider } from '@chakra-ui/react';
import { FeatureA } from './features/FeatureA';
import { FeatureB } from './features/FeatureB';

const muiTheme = createTheme();

export function App() {
  return (
    <ThemeProvider theme={muiTheme}>
      <ChakraProvider>
        <div style={{ width: '1200px', margin: '0 auto' }}>
          <FeatureA />
          <FeatureB />
        </div>
      </ChakraProvider>
    </ThemeProvider>
  );
}
EOF_FIXTURE
mkdir -p 'src/features'
cat > 'src/features/FeatureA.tsx' <<'EOF_FIXTURE'
import Button from '@mui/material/Button';
import HomeIcon from '@mui/icons-material/Home';
import { HomeIcon as HeroHome } from '@heroicons/react/24/solid';

export function FeatureA() {
  return (
    <div style={{ padding: '13px', backgroundColor: '#3B82F6', color: '#fff' }}>
      <Button variant="contained">Save</Button>
      <HomeIcon />
      <HeroHome width={20} />
    </div>
  );
}
EOF_FIXTURE
mkdir -p 'src/features'
cat > 'src/features/FeatureB.tsx' <<'EOF_FIXTURE'
import { Button } from '@chakra-ui/react';
import { Save } from 'lucide-react';

export function FeatureB() {
  return (
    <div style={{ margin: '7px', border: '1px solid #ccc' }}>
      <Button colorScheme="blue">Save</Button>
      <Save size={18} />
      <div onClick={() => alert('ok')} style={{ cursor: 'pointer', color: '#ef4444' }}>
        Delete
      </div>
    </div>
  );
}
EOF_FIXTURE
mkdir -p 'src/theme'
cat > 'src/theme/tokens.css' <<'EOF_FIXTURE'
:root {
  --color-primary: #2563eb;
  --space-md: 16px;
}
EOF_FIXTURE
