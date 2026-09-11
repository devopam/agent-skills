Apple/SwiftUI pack confirmed. Evidence:

- `App/Theme` is empty; views use `Color.blue`, `Color.red`, and
  `Color(red: 0.2, green: 0.4, blue: 0.9)` widely.
- iPad target exists in the Xcode project.
- Navigation is a single `NavigationStack` with no size-class branch and no
  `NavigationSplitView`.

User: "Audit UI system consistency for iOS."
