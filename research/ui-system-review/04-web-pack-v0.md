# Web pack (v0) — baseline

**Target file (later):** `skills/ui-system-review/references/web.md`  
**Form factors:** desktop + tablet + mobile **responsive** patterns in the same pack.

## Checks

### System foundation

- Single primary component source (`@/components/ui`, `@mui/material`, etc.)
- App root wraps theme/provider when the library requires it
- No second full component library imported for the same primitives without migration plan

### Tokens & theme

- Prefer CSS variables / theme tokens / Tailwind `@theme` over raw `#hex` and magic `px` in product UI
- Dark mode via class/data-theme or theme API, not scattered overrides only
- Flag high volume of inline styles / arbitrary Tailwind values when a token scale exists

### Component reuse

- Inventory Button, Input, Modal/Dialog, Select — count parallel implementations
- Prefer composition of system components over copy-paste styled `div`s for the same pattern (3+ repeats → Important)

### Icons & media

- One primary icon package (or SVG sprite pipeline); mixed Heroicons + MUI icons + ad-hoc SVGs without convention → Important
- Images: consistent optimization approach (next/image, responsive `srcset`, etc.) when framework supports it

### Form factors (responsive)

- Defined breakpoint scale (Tailwind screens, MUI breakpoints, CSS media queries) used intentionally
- Mobile navigation pattern present if multi-page app
- Avoid only-fixed pixel layouts for primary shells; relative/fluid units preferred
- Touch-friendly targets on small breakpoints where interactive elements are defined in CSS/components

### Platform idioms

- **shadcn/Radix:** components read CSS variables; avoid hard-coded zinc palettes fighting theme
- **MUI/Chakra:** use theme/spacing APIs; limit one-off `sx={{ color: '#xxx' }}` sprawl
- **Tailwind:** prefer design scale; audit `-[…]` arbitrary values density

### A11y (code)

- Interactive elements not bare `div`/`span` with click handlers without role/button
- Icon-only buttons have accessible names
- Focus rings not globally removed without replacement

### Governance

- Storybook / Histoire / Ladle or equivalent component catalog
- Lint for design tokens (Stylelint strict-value, ESLint plugins) when present — absence is Minor unless scale is large

## Explicit non-goals for v0 web

- Full WCAG certification
- Running the app in a browser (optional enhancement later)
