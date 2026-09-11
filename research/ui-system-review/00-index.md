# ui-system-review — research index

**Skill name (proposed):** `ui-system-review`  
**Status:** coverage baselines (2026-09-11) — research before full reference authoring  
**Goal:** Audit an *existing* project for UI **system consistency** (tokens, components, icons/media, themes, form-factor adaptation), not subjective visual taste.

## Documents

| File | Content |
|------|---------|
| [01-scope-and-modes.md](01-scope-and-modes.md) | In/out scope, modes, report shape |
| [02-domains.md](02-domains.md) | Scored domains (cross-platform) |
| [03-stack-detection.md](03-stack-detection.md) | How the agent detects packs |
| [04-web-pack-v0.md](04-web-pack-v0.md) | Web (React-first) + responsive — **v0** |
| [05-apple-swiftui-pack.md](05-apple-swiftui-pack.md) | Apple / SwiftUI (+ iPad) — post-v0 |
| [06-android-compose-pack.md](06-android-compose-pack.md) | Android / Compose (+ tablet) — post-v0 |
| [07-responsive-and-form-factors.md](07-responsive-and-form-factors.md) | Browser responsive + phone/tablet |
| [08-remediation-and-roadmap.md](08-remediation-and-roadmap.md) | Suggestions depth + phased roadmap |

## Sources (snapshot)

- Design-system / token audit practice (inventory → tokens → components → a11y → docs)
- Web: shadcn/Radix/Tailwind token model; MUI/Chakra theme governance; Stylelint/ESLint design hygiene
- Apple: SwiftUI token systems; hardcoded Color/padding anti-patterns; 44pt targets
- Android: Material 3 `MaterialTheme` (colorScheme, typography, shapes); dual XML+Compose theme risk
- Responsive: breakpoints, fluid layout, touch targets, image/type scaling

Retrieval window: 2026-09-11.
