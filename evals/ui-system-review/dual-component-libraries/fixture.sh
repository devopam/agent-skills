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
    "@mui/material": "5.15.0",
    "@chakra-ui/react": "2.8.2",
    "@emotion/react": "11.11.0"
  }
}
EOF_FIXTURE
mkdir -p 'src'
cat > 'src/App.tsx' <<'EOF_FIXTURE'
import { ThemeProvider, createTheme } from '@mui/material';
import { ChakraProvider } from '@chakra-ui/react';
export default () => (
  <ThemeProvider theme={createTheme()}><ChakraProvider><Routes /></ChakraProvider></ThemeProvider>
);
EOF_FIXTURE
mkdir -p 'src/features'
cat > 'src/features/FeatureA.tsx' <<'EOF_FIXTURE'
import { Button } from '@mui/material';
export const A = () => <Button variant="contained">Save</Button>;
EOF_FIXTURE
mkdir -p 'src/features'
cat > 'src/features/FeatureB.tsx' <<'EOF_FIXTURE'
import { Button } from '@chakra-ui/react';
export const B = () => <Button colorScheme="blue">Save</Button>;
EOF_FIXTURE
