# Domains (cross-platform scorecard)

Score each applicable domain 0–10. Mark N/A only with explicit justification (e.g. no mobile targets).

| # | Domain | What good looks like |
|---|--------|----------------------|
| 1 | **System foundation** | One declared UI system / library; app shell uses it |
| 2 | **Tokens & theme** | Colors, space, type, radius via tokens/theme API; light/dark coherent |
| 3 | **Component reuse** | Shared primitives; few one-off parallel Buttons/Inputs/Modals |
| 4 | **Icons & media** | One primary icon set; image/asset conventions |
| 5 | **Form factors** | Responsive breakpoints (web) or size-class / window-size (Apple/Android) used consistently |
| 6 | **Platform idioms** | Pack-specific anti-patterns avoided (see pack docs) |
| 7 | **Accessibility (code)** | Labels, semantics, focus/touch minima where visible in code |
| 8 | **Governance & tooling** | Previews/Storybook, token lint, docs/baseline |

**Composite:** average of scored (non-N/A) domains.

Severity mapping:

- **Critical** — no system at all + widespread hardcoding; multiple conflicting design systems in production paths
- **Important** — systematic drift (hex soup, dual icon libraries, missing theme)
- **Minor** — local exceptions, missing docs, incomplete Storybook
- **Not Implemented** — expected control absent (no dark theme, no tablet layout) when product claims that surface
