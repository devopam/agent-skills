# Responsive UI and form factors

Cross-cutting domain **Form factors** applies in every pack.

## Web (v0)

| Concern | Audit signal |
|---------|----------------|
| Breakpoint system | Tailwind screens, MUI breakpoints, shared SCSS breakpoints, or documented CSS custom media |
| Fluid layout | `%`/`fr`/`rem`/`vw` vs only fixed px shells |
| Navigation | Collapse/priority patterns for narrow viewports |
| Type & media | Scalable type; responsive images when applicable |
| Touch | Adequate target size classes on small breakpoints |

Does **not** require running Lighthouse; code and config evidence only in v0.

## Apple

| Concern | Audit signal |
|---------|----------------|
| Compact vs regular | Size-class-driven layout |
| iPad | Sidebar/split; not merely scaled phone UI if iPad target exists |
| Touch | 44pt minima |

## Android

| Concern | Audit signal |
|---------|----------------|
| Width buckets | WindowSizeClass / adaptive scaffolds |
| Tablet | Nav rail / list-detail when appropriate |
| Touch | 48dp-class targets where explicit |

## Scoring guidance

- Product is **web-only** → score web responsive; N/A mobile packs
- Product claims **iPad/tablet** support but only phone layouts → Important/Not Implemented under Form factors
- Multi-platform monorepo → one report section per surface or separate invocations
