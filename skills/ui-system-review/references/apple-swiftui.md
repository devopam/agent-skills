# Apple / SwiftUI pack

**Form factors:** iPhone (compact) + **iPad** (regular / adaptive). Optional
macOS notes only when a Mac target is present.

Snapshot guidance: 2026-09-11. Prefer evidence in the target tree over
generic advice.

## System foundation

- Shared design-system module or token/component package imported by features
- App entry applies a single theme/style environment (custom `Theme` view,
  environment keys, or asset-driven semantic colors)
- Feature modules should not each redefine primary Button/TextField styles

**Red flags:** multiple unrelated “DesignSystem” folders with conflicting
colors; UIKit storyboards + SwiftUI with no shared token story for the same
screens.

## Tokens & theme

Prefer:

- Semantic colors via **Asset Catalog** (`Color("Background")`) or a small
  token enum (`AppColor.accent`) — not scattered `Color.blue` / `Color(red:…)`
- **Spacing scale** (`Spacing.md`) instead of magic `.padding(13)`
- **Typography** tied to Dynamic Type (`.body`, `.title2`, or named text
  styles) instead of only `.font(.system(size: 17))`
- Light/dark pairs in assets or adaptive `Color` definitions

Flag widespread hardcoded hex/RGB and one-off paddings when any token module
already exists.

## Component reuse

- Inventory primary actions, text fields, lists, toolbars
- Parallel custom buttons with the same role across features → Important
- Prefer composition of shared controls over copy-paste styled stacks

## Icons & media

- **SF Symbols** as the default system icon language unless a brand icon set
  is centralized and documented
- Asset catalogs with @2x/@3x (or vector) consistency
- Avoid random PNGs in feature folders with no naming convention

## Form factors (iPhone + iPad)

| Signal | Prefer |
|--------|--------|
| Size class | `@Environment(\.horizontalSizeClass)` for coarse chrome (sidebar vs stack) |
| iPad | `NavigationSplitView` / sidebar patterns when regular width is in scope |
| Geometry | For fine layout, also consider available width — size class alone is coarse (landscape iPhone can be `.regular`) |
| Touch | Interactive controls aiming for **≥ 44pt** minimum targets |

**Red flags:** iPad target in the project but only phone-stack navigation and
fixed narrow layouts; `userInterfaceIdiom == .pad` as the *only* layout branch
without size-class/geometry thought.

## Platform idioms

- Prefer SwiftUI layout (stacks, grids, safe areas) over heavy UIKit wrapping
  for pure presentation
- Support Dynamic Type; avoid locking content size without reason
- Prefer semantic hierarchy (navigation titles, list styles) consistent across
  tabs

## Accessibility (code)

- Icon-only controls: `.accessibilityLabel`
- Decorative images: hidden from accessibility when appropriate
- Do not strip accessibility traits from custom controls without replacement

## Governance

- `#Preview` / Xcode Previews for shared components strengthens score
- Optional design-token docs or `docs/ui-system-baseline.md` entry for Apple
  surface

## Remediation direction (examples)

- Introduce `AppColor` / Asset Catalog semantic colors; replace `Color.blue`
- Centralize `PrimaryButton` style; delete feature-local copies
- Add size-class-aware navigation for iPad destinations
- Document SF Symbols vs custom icon policy

## Sources

- SwiftUI adaptive layout / size-class practice; token and spacing scales
- Common audit rules: hardcoded color/space/type; 44pt targets
- Research baseline: `research/ui-system-review/05-apple-swiftui-pack.md`
