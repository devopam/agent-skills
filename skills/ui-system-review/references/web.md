# Web pack (v0)

Includes **responsive** desktop / tablet / mobile checks.

## System foundation

- Prefer a single primary source of components (design-system package or `components/ui`)
- App root should apply the library theme/provider when required
- Second full library for the same primitives (e.g. MUI + Chakra both for buttons) without a migration boundary → Important or Critical

## Tokens & theme

- Favor CSS variables, theme objects, or Tailwind design scale over raw `#RRGGBB` and one-off spacing in product UI
- Dark mode via documented mechanism (`class`, `data-theme`, theme API)
- High density of arbitrary values (`w-[137px]`, inline hex) while a scale exists → Important

## Component reuse

- Sample high-traffic primitives: Button, Input/TextField, Dialog/Modal, Select
- Three or more parallel implementations of the same role → Important
- Prefer system composition over repeated custom styled shells

## Icons & media

- One primary icon approach (package or curated SVG pipeline)
- Mixing multiple icon kits with no documented split → Important
- Use framework image helpers when the stack provides them (e.g. optimized image component)

## Form factors (responsive)

- Shared breakpoint scale used in layout/nav
- Primary shell not only fixed pixel widths
- Narrow-viewport navigation pattern for multi-section apps
- Interactive controls should not rely on hover-only affordances without a non-hover path

## Platform idioms

| Flavor | Prefer | Avoid |
|--------|--------|--------|
| shadcn / Radix / Tailwind | Token-backed components, shared `components/ui` | Hard-coded palette classes fighting CSS variables |
| MUI / Chakra / Mantine | Theme spacing/palette APIs | Widespread one-off hex in `sx` / style props |
| Plain CSS/SCSS | Variable maps / tokens | Uncoordinated magic numbers per file |

## Accessibility (code)

- Prefer real `<button>` / links over clickable `div`s
- Icon-only controls need accessible names
- Do not remove focus indicators globally without a visible replacement

## Governance

- Component catalog (Storybook or similar) strengthens score
- Token-oriented lint is a plus, not a hard requirement for a passing audit
