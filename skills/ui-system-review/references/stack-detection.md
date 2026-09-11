# Stack detection

Confirm with the user before deep scoring.

## Web

- JS/TS manifests: `react`, `vue`, `svelte`, `tailwindcss`, `@mui/material`, `@chakra-ui`, `antd`, `@radix-ui`, shadcn-style `components/ui`
- Theme: `ThemeProvider`, CSS `--*` variables, Tailwind `@theme` / `tailwind.config`

## Apple

- Xcode project / `Package.swift`, `import SwiftUI`, asset catalogs, iOS/iPadOS targets

## Android

- Gradle modules, `androidx.compose`, `MaterialTheme`, `material3`, optional `themes.xml`

## Multi-surface

Monorepos may need **one invocation per surface** (e.g. `apps/web` then `apps/ios`). Do not blend scores across platforms into one silent average without labeling sections.
