# ui-system-review — research index

**Skill name:** `ui-system-review`  
**Status:** v0 web + **Apple/SwiftUI** + **Android/Compose** pack depth on main
(2026-09-11). Evals: 10 cases. Public-repo smoke test still pending.  
**Goal:** Audit an *existing* project for UI **system consistency** (tokens,
components, icons/media, themes, form-factor adaptation), not subjective visual
taste.

## Documents

| File | Content |
|------|---------|
| [01-scope-and-modes.md](01-scope-and-modes.md) | In/out scope, modes, report shape |
| [02-domains.md](02-domains.md) | Scored domains (cross-platform) |
| [03-stack-detection.md](03-stack-detection.md) | How the agent detects packs |
| [04-web-pack-v0.md](04-web-pack-v0.md) | Web (React-first) + responsive |
| [05-apple-swiftui-pack.md](05-apple-swiftui-pack.md) | Apple / SwiftUI (+ iPad) |
| [06-android-compose-pack.md](06-android-compose-pack.md) | Android / Compose (+ tablet) |
| [07-responsive-and-form-factors.md](07-responsive-and-form-factors.md) | Browser responsive + phone/tablet |
| [08-remediation-and-roadmap.md](08-remediation-and-roadmap.md) | Suggestions depth + phased roadmap |

## Authored skill refs

| Pack | Path |
|------|------|
| Web | `skills/ui-system-review/references/web.md` |
| Apple | `skills/ui-system-review/references/apple-swiftui.md` |
| Android | `skills/ui-system-review/references/android-compose.md` |

## Sources (snapshot)

- Design-system / token audit practice
- Web: shadcn/Radix/Tailwind; MUI/Chakra; Stylelint/ESLint hygiene
- Apple: SwiftUI tokens; size class + geometry; 44pt targets
- Android: Material 3 `MaterialTheme`; WindowSizeClass adaptive; XML+Compose dual theme risk

Retrieval window: 2026-09-11.
