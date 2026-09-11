# Android / Compose pack

**Form factors:** phone + **tablet** / multi-window via window size classes.

Snapshot guidance: 2026-09-11 (Material 3 in Compose). Prefer evidence in the
target tree over generic advice.

## System foundation

- App content wrapped in a single theme entrypoint (`MaterialTheme` or a
  documented custom theme that still exposes coherent roles)
- Prefer **Material 3** (`androidx.compose.material3`) when starting or
  migrating; note M2 vs M3 dual usage as migration debt
- Shared UI module for reusable composables beats per-feature copies

**Red flags:** screens outside any theme; two competing theme wrappers; large
XML View UI + Compose with **two sources of truth** for colors/type
(XML `themes.xml` + Compose `ColorScheme`) without a migration plan.

## Tokens & theme

Material 3 subsystems via `MaterialTheme`:

- **colorScheme** — role colors (`primary`, `onPrimary`, `surface`, …), not
  raw `Color(0xFF…)` in product UI
- **typography** — `MaterialTheme.typography.titleLarge` etc.
- **shapes** — `MaterialTheme.shapes.medium` etc.

Prefer light/dark schemes (`lightColorScheme` / `darkColorScheme`) or dynamic
color where product chooses it, with a non-dynamic fallback.

Flag painting everything with `primary`; prefer secondary/tertiary/surface
roles for hierarchy.

## Component reuse

- Prefer M3 components (`Button`, `TextField`, `Card`, …) or shared wrappers
- Three+ custom primary buttons across features → Important
- List-detail / pane scaffolds from adaptive libraries when tablet is in scope

## Icons & media

- Material Icons or one curated vector set
- Mixed ad-hoc drawables + multiple icon libs without convention → Important
- Vector assets over unmanaged bitmap sprawl when possible

## Form factors (phone + tablet)

| Signal | Prefer |
|--------|--------|
| Window size | `WindowSizeClass` / `currentWindowAdaptiveInfo()` (Material 3 adaptive) |
| Width buckets | Compact / medium / expanded (and large/XL if supported) |
| Tablet UI | Navigation rail, list-detail (`ListDetailPaneScaffold` or equivalent) when expanded width is claimed |
| Touch | Explicit sizes should respect comfortable touch targets (~**48dp** class) |

**Red flags:** tablet or large-screen screenshots in store listing but only
single-pane phone composables; orientation-only branching with no size class.

## Platform idioms

- Use color **roles**, not one-off hex matching brand in every screen
- Prefer theme shapes/type over per-call `RoundedCornerShape(11.dp)` soup when
  a scale exists
- Keep experimental Material3 APIs opt-in and localized if used

## Accessibility (code)

- Icon-only: `contentDescription` (null only when decorative)
- Prefer meaningful semantics on custom clickable composables
- Minimum touch target modifiers when custom hit areas are defined

## Governance

- `@Preview` (light/dark, sizes) for core components
- Theme documented in module README or UI baseline

## Remediation direction (examples)

- Wrap app in one `AppTheme` using M3 `colorScheme` + light/dark
- Replace raw `Color(0xFF…)` with scheme roles
- Unify XML and Compose themes or finish migration to one source of truth
- Introduce `WindowSizeClass`-driven list-detail for tablet

## Sources

- Android Developers: Material 3 in Compose (color, type, shape)
- Window size classes / adaptive layouts (`currentWindowAdaptiveInfo`)
- XML → Compose theme migration dual-source risk
- Research baseline: `research/ui-system-review/06-android-compose-pack.md`
