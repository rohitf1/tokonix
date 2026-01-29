#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
OUT_DIR="$ROOT_DIR/dist"
APP_NAME="Tokonix"
APP_DIR="$OUT_DIR/${APP_NAME}.app"

mkdir -p "$OUT_DIR"

pushd "$ROOT_DIR" >/dev/null
swift build -c release
popd >/dev/null

BIN_PATH="$BUILD_DIR/release/tokonix"
if [[ ! -x "$BIN_PATH" ]]; then
  echo "Binary not found at $BIN_PATH"
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Tokonix</string>
    <key>CFBundleDisplayName</key>
    <string>Tokonix</string>
    <key>CFBundleIdentifier</key>
    <string>com.tokonix.overlay</string>
    <key>CFBundleVersion</key>
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleIconFile</key>
    <string>Tokonix.icns</string>
    <key>CFBundleExecutable</key>
    <string>tokonix</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Tokonix needs microphone access to capture your prompts.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Tokonix needs speech recognition to transcribe your voice.</string>
</dict>
</plist>
PLIST

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/tokonix"
chmod +x "$APP_DIR/Contents/MacOS/tokonix"

RESOURCE_BUNDLE="$BUILD_DIR/release/Tokonix_Tokonix.bundle"
if [[ -d "$RESOURCE_BUNDLE" ]]; then
  cp -R "$RESOURCE_BUNDLE" "$APP_DIR/Contents/Resources/"
fi

ICON_SOURCE="$ROOT_DIR/Resources/Tokonix.icns"
if [[ -f "$ICON_SOURCE" ]]; then
  cp "$ICON_SOURCE" "$APP_DIR/Contents/Resources/"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" || true
fi

echo "Built: $APP_DIR"
