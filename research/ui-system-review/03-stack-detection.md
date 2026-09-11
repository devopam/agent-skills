# Stack detection

Infer **primary** pack from repo signals; confirm with user before deep scoring. Multi-pack repos (e.g. RN + web) score per surface or ask which surface to audit.

## Web (v0)

Signals: `package.json` deps (`react`, `vue`, `svelte`, `@mui/material`, `antd`, `@chakra-ui`, `tailwindcss`, `shadcn`, `@radix-ui`), `components/ui`, `tailwind.config.*`, CSS variables / `@theme`, Storybook.

Sub-flavors (same pack, different idioms):

- **Token-CSS / shadcn / Tailwind** — CSS variables, CVA, Radix
- **MUI / Chakra / Mantine** — theme provider + component imports from one package
- **CSS Modules / plain CSS** — variables or SCSS tokens without a component kit

## Apple (post-v0)

Signals: `*.xcodeproj`, `Package.swift`, `import SwiftUI`, `Assets.xcassets`, `Color("…")` asset catalogs, iOS/iPadOS targets.

## Android (post-v0)

Signals: `build.gradle.kts`, `import androidx.compose`, `MaterialTheme`, `material3`, `res/values/themes.xml` (legacy dual theme).

## Flutter / React Native (backlog)

Flutter: `pubspec.yaml`, `ThemeData`, Material/Cupertino.  
RN: `react-native`, Paper / NativeBase / Tamagui.  
Schedule after Apple + Android packs unless a user project needs them first.

## Form-factor flags

- Web: presence of breakpoints, container queries, mobile nav patterns
- Apple: `horizontalSizeClass`, `UIDevice` idioms, iPad destinations
- Android: `WindowSizeClass`, adaptive layouts, foldables (note only if present)
