#!/bin/bash
# Builds a .app with the GUI and the daemon bundled in Resources.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/fase-2-gui/dist/Scarlett 8i6 Mixer.app"

CONFIG="${1:-release}"
(cd "$ROOT/fase-1-daemon" && make >/dev/null)
(cd "$ROOT/fase-2-gui/scarlett-app" && swift build -c "$CONFIG" >/dev/null)

BIN="$(cd "$ROOT/fase-2-gui/scarlett-app" && swift build -c "$CONFIG" --show-bin-path)/scarlett-app"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/scarlett-app"
cp "$ROOT/fase-1-daemon/build/scarlett-daemon" "$APP/Contents/Resources/scarlett-daemon"
cp "$ROOT/fase-2-gui/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>scarlett-app</string>
    <key>CFBundleIdentifier</key><string>local.scarlett8i6.mixer</string>
    <key>CFBundleName</key><string>Scarlett 8i6 Mixer</string>
    <key>CFBundleDisplayName</key><string>Scarlett 8i6 Mixer</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>0.2.0</string>
    <key>CFBundleVersion</key><string>0.2.0</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.music</string>
</dict>
</plist>
PLIST

# 8i6: sign with a fixed identity if it exists (see ../setup_signing.sh) so macOS
# keeps the Accessibility permission across rebuilds. Otherwise sign ad-hoc.
IDENTITY="Scarlett 8i6 Local Signing"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
    codesign --force --deep --sign "$IDENTITY" "$APP"
    echo "Signed with \"$IDENTITY\" (the Accessibility permission survives rebuilds)"
else
    codesign --force --deep --sign - "$APP" 2>/dev/null || true
    echo "NOTE: ad-hoc signature. Run ./setup_signing.sh once so rebuilds keep the Accessibility permission."
fi
echo "OK: $APP"