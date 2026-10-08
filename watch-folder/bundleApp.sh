
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Watch Folder"
EXECUTABLE="watch-folder"
BUNDLE_ID="com.liyh.watchfolder"
VERSION="1.0.0"
MACOS_TARGET="14.0"

BUILD_DIR="build"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"

echo "==> Cleaning build directories"
rm -rf "$BUILD_DIR" "$APP_DIR"
mkdir -p "$BUILD_DIR" "$CONTENTS/MacOS" "$CONTENTS/Resources"

echo "==> Compiling Objective-C bridges"

clang \
  -target "arm64-apple-macosx${MACOS_TARGET}" \
  -fobjc-arc \
  -O2 \
  -c audio.m \
  -o "$BUILD_DIR/audio.o"

clang \
  -target "arm64-apple-macosx${MACOS_TARGET}" \
  -fobjc-arc \
  -O2 \
  -c menu.m \
  -o "$BUILD_DIR/menu.o"

echo "==> Creating native static library"

ar rcs \
  "$BUILD_DIR/libnative.a" \
  "$BUILD_DIR/audio.o" \
  "$BUILD_DIR/menu.o"

# The FFI manifest uses ./libnative.a, relative to
# the project directory.
cp "$BUILD_DIR/libnative.a" ./libnative.a

echo "==> Compiling TypeScript with scriptc"

npx scriptc build watch-folder.ts \
  --ffi ffi.json \
  -o "$CONTENTS/MacOS/$EXECUTABLE"

chmod +x "$CONTENTS/MacOS/$EXECUTABLE"

echo "==> Creating Info.plist"

cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>

    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>

    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>

    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleVersion</key>
    <string>1</string>

    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>

    <key>LSMinimumSystemVersion</key>
    <string>$MACOS_TARGET</string>

    <!-- Menu bar application: hide Dock icon -->
    <key>LSUIElement</key>
    <true/>

    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Optional application icon
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$CONTENTS/Resources/"
    /usr/libexec/PlistBuddy \
      -c "Add :CFBundleIconFile string AppIcon" \
      "$CONTENTS/Info.plist"
fi

echo "==> Ad-hoc code signing"

codesign \
  --force \
  --sign - \
  "$APP_DIR"

echo "==> Validating application"

/usr/libexec/PlistBuddy \
  -c "Print :CFBundleExecutable" \
  "$CONTENTS/Info.plist"

codesign --verify --verbose=2 "$APP_DIR"

echo ""
echo "Build complete!"
echo "Application: $APP_DIR"
echo ""
echo "Launch with:"
echo "open \"$APP_DIR\""
