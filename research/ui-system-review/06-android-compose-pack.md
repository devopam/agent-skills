# Android / Compose pack — baseline (post-v0)

**Target file (later):** `skills/ui-system-review/references/android-compose.md`  
**Form factors:** phone + **tablet** / window size classes.

## Checks

### System foundation

- Single `MaterialTheme` (M2 or M3) or documented custom theme wrapping the app
- Compose screens use theme components (`Button`, `Text`, …) consistently

### Tokens & theme

- `MaterialTheme.colorScheme` / typography / shapes as source of truth
- Prefer role colors (`primary`, `onSurface`) over raw `Color(0xFF…)` in UI
- Light/dark schemes defined and applied via theme wrapper
- **Migration risk:** XML themes + Compose themes as dual sources of truth → Important until unified

### Component reuse

- Shared design-system composables module
- Duplicate custom buttons/cards across features → Important

### Icons & media

- Material Icons / consolidated vector set; avoid mixed ad-hoc drawables without convention

### Form factors

- `WindowSizeClass` or equivalent adaptive layouts for **tablet**
- Navigation rail / supporting pane patterns when expanded width is in product scope
- Minimum touch target sizes (48dp guidance) where modifiers set sizes explicitly

### Platform idioms

- M3 role usage (don’t paint everything `primary`)
- Shape and type scales from theme

### Governance

- `@Preview` for core components
- Theme documentation or baseline entry

## Sources

- Android Developers: Material 2/3 in Compose; theme migration XML→Compose
- Material role and surface guidance
