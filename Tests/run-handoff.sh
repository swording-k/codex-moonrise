#!/bin/zsh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
xcrun swift "$ROOT/Tests/GUIEnvironment.swift"
BUILD="$ROOT/.build/handoff-tests"
FIXTURE="$BUILD/HandoffFixture.app"
mkdir -p "$FIXTURE/Contents/MacOS"
xcrun swiftc "$ROOT/Tests/Fixture.swift" -o "$FIXTURE/Contents/MacOS/Fixture" -framework AppKit
cat > "$FIXTURE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>local.codex.moonrise.test-fixture</string><key>CFBundleExecutable</key><string>Fixture</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>
PLIST
codesign --force --sign - "$FIXTURE"
xcrun swiftc -parse-as-library "$ROOT/Source/ClientHandoff.swift" "$ROOT/Tests/HandoffIntegration.swift" -o "$BUILD/handoff-integration" -framework AppKit
for scenario in reopen cold stale missing; do
 "$BUILD/handoff-integration" "$FIXTURE" "$scenario"
done
