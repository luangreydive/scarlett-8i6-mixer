#!/bin/bash
# ============================================
# Builds "Scarlett 8i6 Mixer.app" in this folder.
#   ./build_8i6.sh
# Requires the Xcode Command Line Tools (they include clang and swift).
# ============================================
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

if ! xcode-select -p >/dev/null 2>&1 || ! command -v swift >/dev/null 2>&1; then
    echo "The Xcode Command Line Tools are missing."
    echo "The installer will open; when it finishes, run ./build_8i6.sh again."
    xcode-select --install || true
    exit 1
fi

echo "[1/2] Building (the first build can take a couple of minutes)..."
bash "$DIR/fase-2-gui/package.sh"

# Quit the app if it is running (it stays in the menu bar after its window is closed)
pkill -x scarlett-app 2>/dev/null || true
sleep 1

echo "[2/2] Copying the app to this folder..."
rm -rf "$DIR/Scarlett 8i6 Mixer.app"
cp -R "$DIR/fase-2-gui/dist/Scarlett 8i6 Mixer.app" "$DIR/"
xattr -cr "$DIR/Scarlett 8i6 Mixer.app" 2>/dev/null || true

# If it is already installed in Applications, update that copy (Launch at Login keeps working)
INSTALLED="/Applications/Scarlett 8i6 Mixer.app"
if [ -d "$INSTALLED" ]; then
    rm -rf "$INSTALLED"
    cp -R "$DIR/Scarlett 8i6 Mixer.app" "$INSTALLED"
    open "$INSTALLED"
    echo ""
    echo "Updated in Applications and launched: $INSTALLED"
else
    echo ""
    echo "Done: $DIR/Scarlett 8i6 Mixer.app"
    echo "Recommended: move it to Applications before enabling 'Launch at Login'."
fi
echo "If the volume keys do not respond: System Settings > Privacy & Security > Accessibility"
echo "(remove the app with '-' if it is listed, then reopen it so it asks for the permission again)."
