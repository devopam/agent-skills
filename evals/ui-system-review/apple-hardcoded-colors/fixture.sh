#!/usr/bin/env bash
set -euo pipefail
mkdir -p 'App/Theme'
cat > 'App/Theme/.gitkeep' <<'EOF_FIXTURE'

EOF_FIXTURE
mkdir -p 'App/Views'
cat > 'App/Views/HomeView.swift' <<'EOF_FIXTURE'
import SwiftUI
struct HomeView: View {
  var body: some View {
    VStack { Text("Home").foregroundColor(Color.blue); Rectangle().fill(Color(red: 0.2, green: 0.4, blue: 0.9)) }
  }
}
EOF_FIXTURE
mkdir -p 'App/Views'
cat > 'App/Views/AlertView.swift' <<'EOF_FIXTURE'
import SwiftUI
struct AlertView: View { var body: some View { Text("Alert").foregroundColor(Color.red) } }
EOF_FIXTURE
mkdir -p 'App'
cat > 'App/RootView.swift' <<'EOF_FIXTURE'
import SwiftUI
struct RootView: View { var body: some View { NavigationStack { HomeView() } } }  // single NavigationStack, no size-class branch, no NavigationSplitView
EOF_FIXTURE
mkdir -p 'App.xcodeproj'
cat > 'App.xcodeproj/project.pbxproj' <<'EOF_FIXTURE'
// minimal fixture
TARGETED_DEVICE_FAMILY = "1,2";  // iPhone + iPad
EOF_FIXTURE
