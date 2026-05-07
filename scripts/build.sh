#!/bin/bash
set -e

echo "Building ColorPicker..."
cd "$(dirname "$0")/.."

# Build for both architectures (universal binary)
NATIVE_ARCH=$(uname -m)
if [ "$NATIVE_ARCH" = "arm64" ]; then
    OTHER_ARCH="x86_64"
else
    OTHER_ARCH="arm64"
fi

echo "Building for $NATIVE_ARCH..."
swift build -c release --triple "$NATIVE_ARCH-apple-macosx"

echo "Building for $OTHER_ARCH..."
swift build -c release --triple "$OTHER_ARCH-apple-macosx"

# Create app bundle
APP_DIR="build/ColorPicker.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Create universal binary
lipo -create \
    ".build/$NATIVE_ARCH-apple-macosx/release/ColorPicker" \
    ".build/$OTHER_ARCH-apple-macosx/release/ColorPicker" \
    -output "$APP_DIR/Contents/MacOS/ColorPicker"

cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_DIR/Contents/Info.plist" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_DIR/Contents/Info.plist"
if [ -f "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.icns" ]; then
    cp Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_DIR/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_DIR/Contents/Info.plist"
fi
# Copy icon
ICON_SRC=""
for src in "Sources/AppIcon.png" "Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png" "Resources/AppIcon.png"; do
    if [ -f "$src" ]; then ICON_SRC="$src"; break; fi
done
if [ -n "$ICON_SRC" ]; then
    # Create icns from png
    ICONSET="build/tmp.iconset"
    mkdir -p "$ICONSET"
    sips -z 16 16 "$ICON_SRC" --out "$ICONSET/icon_16x16.png" 2>/dev/null
    sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png" 2>/dev/null
    sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_32x32.png" 2>/dev/null
    sips -z 64 64 "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png" 2>/dev/null
    sips -z 128 128 "$ICON_SRC" --out "$ICONSET/icon_128x128.png" 2>/dev/null
    sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" 2>/dev/null
    sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_256x256.png" 2>/dev/null
    sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" 2>/dev/null
    sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_512x512.png" 2>/dev/null
    sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" 2>/dev/null
    iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null
    rm -rf "$ICONSET"
fi

cp Resources/presets.json "$APP_DIR/Contents/Resources/presets.json" 2>/dev/null || true
cp Resources/menu-icon.svg "$APP_DIR/Contents/Resources/menu-icon.svg" 2>/dev/null || true

echo "Done: $APP_DIR (Universal: $NATIVE_ARCH + $OTHER_ARCH)"
echo "Run: open $APP_DIR"
