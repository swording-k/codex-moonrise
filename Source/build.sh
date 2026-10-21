#!/bin/zsh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/Codex Moonrise.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ROOT/.build"
for ARCH in arm64 x86_64; do
 xcrun swiftc -O -target "${ARCH}-apple-macos13.0" "$ROOT/Source/main.swift" -o "$ROOT/.build/Moonrise-$ARCH" -framework AppKit -framework WebKit
done
xcrun lipo -create "$ROOT/.build/Moonrise-arm64" "$ROOT/.build/Moonrise-x86_64" -output "$APP/Contents/MacOS/Moonrise"
cp "$ROOT/Preview/index.html" "$APP/Contents/Resources/index.html"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>local.codex.moonrise</string><key>CFBundleName</key><string>Codex Moonrise</string><key>CFBundleDisplayName</key><string>Codex Moonrise</string><key>CFBundleExecutable</key><string>Moonrise</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>2.0</string><key>CFBundleVersion</key><string>2</string><key>LSMinimumSystemVersion</key><string>13.0</string><key>LSUIElement</key><true/><key>NSHighResolutionCapable</key><true/></dict></plist>
PLIST
if [[ -f "$ROOT/Source/Moonrise.icns" ]]; then
 cp "$ROOT/Source/Moonrise.icns" "$APP/Contents/Resources/Moonrise.icns"
 /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string Moonrise' "$APP/Contents/Info.plist"
fi
codesign --force --sign - "$APP"
echo "Built: $APP"
