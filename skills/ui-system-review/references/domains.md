# Domains

Score 0–10. Use N/A only with justification.

| Domain | 9–10 | 5–7 | 0–3 |
|--------|------|-----|-----|
| **System foundation** | One system, used at app shell | Partial adoption | None / conflicting systems in product UI |
| **Tokens & theme** | Semantic tokens; light/dark coherent | Mixed tokens + hardcoding | Hex/magic numbers dominate |
| **Component reuse** | Shared primitives; rare forks | Some parallel widgets | Many one-off Buttons/Inputs |
| **Icons & media** | One icon strategy + asset rules | Mild mix | Uncoordinated packs/assets |
| **Form factors** | Breakpoints/size classes intentional | Partial responsive | Fixed desktop-only or phone-only when more claimed |
| **Platform idioms** | Pack guidance followed | Occasional anti-patterns | Systematic anti-patterns |
| **Accessibility (code)** | Labels/semantics/targets mostly sound | Gaps on secondary flows | Icon-only bare divs, removed focus |
| **Governance & tooling** | Catalog + lint or baseline | One of previews/docs | No governance signals |

**Composite:** mean of non-N/A scores.

Severity:

- **Critical** — conflicting systems in production paths; total token absence with large UI surface
- **Important** — dual icon libraries, widespread hardcoding, dual XML+Compose themes, missing tablet layout when claimed
- **Minor** — docs, incomplete Storybook, local exceptions
- **Not Implemented** — expected capability absent (dark theme, iPad layout, token lint at scale)
