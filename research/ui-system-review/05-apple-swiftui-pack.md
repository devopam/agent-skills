# Apple / SwiftUI pack — baseline (post-v0)

**Target file (later):** `skills/ui-system-review/references/apple-swiftui.md`  
**Form factors:** iPhone + **iPad** (size classes), optional macOS Catalyst notes only if target exists.

## Checks

### System foundation

- Shared design-system module or `Theme` / token enums used app-wide
- Feature modules import shared components rather than redefining Button styles

### Tokens & theme

- Prefer semantic `Color("…")` asset catalog / token enums over `Color.blue`, random `Color(hex:)`
- Spacing scale (`Spacing.md`) over magic `.padding(13)`
- Typography tokens / Dynamic Type–friendly styles over fixed `.font(.system(size: 17))` everywhere
- Light/dark: asset catalog dark variants or semantic colors; test both

### Component reuse

- Shared controls for primary actions, text fields, lists
- Parallel custom buttons with same role → Important

### Icons & media

- SF Symbols as default system icons unless brand set is deliberate and centralized
- Asset catalog organization; avoid one-off images without scale factors

### Form factors

- `horizontalSizeClass` / adaptive layouts for **iPad** vs compact iPhone
- Navigation split views / sidebars where tablet UX is claimed
- Touch targets ≥ 44pt for interactive controls (code-visible frame/min sizes)

### Platform idioms

- Prefer SwiftUI layout system over excessive UIKit bridging for pure UI
- Accessibility: labels on icon-only controls; Dynamic Type not disabled without reason

### Governance

- Xcode Previews for shared components
- Optional SwiftUI audit tooling if already in repo (do not require third-party tools)

## Sources

- SwiftUI design-token / theme practice; production audit patterns (hardcoded color/space/type)
- Apple HIG consistency and touch targets (via common audit rulesets)
