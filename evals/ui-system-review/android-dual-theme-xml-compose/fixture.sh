#!/usr/bin/env bash
set -euo pipefail
mkdir -p 'app'
cat > 'app/build.gradle.kts' <<'EOF_FIXTURE'
plugins { id("com.android.application") }
dependencies { implementation("androidx.compose.material3:material3:1.2.0") }
EOF_FIXTURE
mkdir -p 'app/src/main/res/values'
cat > 'app/src/main/res/values/themes.xml' <<'EOF_FIXTURE'
<resources>
  <style name="Theme.App" parent="Theme.Material3.DayNight">
    <item name="colorPrimary">#6200EE</item>
  </style>
</resources>
EOF_FIXTURE
mkdir -p 'app/src/main/java/com/example'
cat > 'app/src/main/java/com/example/HomeScreen.kt' <<'EOF_FIXTURE'
@Composable fun HomeScreen() {
  MaterialTheme { Text("Home", color = Color(0xFF6200EE)) }
}
EOF_FIXTURE
mkdir -p 'app/src/main/java/com/example'
cat > 'app/src/main/java/com/example/ReportScreen.kt' <<'EOF_FIXTURE'
@Composable fun ReportScreen() {
  // no MaterialTheme wrapper here
  Text("Report", color = Color(0xFF6200EE))
}  // no WindowSizeClass / adaptive layout anywhere; product claims tablet support
EOF_FIXTURE
