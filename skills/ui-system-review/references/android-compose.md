# Android / Compose pack

**Status:** stub for v1.1 depth — use evidence-backed findings only until expanded.

## Interim checks (allowed now)

- Raw `Color(0xFF…)` vs `MaterialTheme.colorScheme` roles
- App content outside `MaterialTheme` { } without documented custom theme
- Dual XML theme + Compose theme as conflicting sources of truth
- Tablet / expanded width claimed without WindowSizeClass (or equivalent) usage

## Full pack (v1.1)

Expand with: M3 roles, typography/shapes scales, shared composable modules,
48dp-class targets, nav rail / list-detail, `@Preview` governance.

See `research/ui-system-review/06-android-compose-pack.md`.
