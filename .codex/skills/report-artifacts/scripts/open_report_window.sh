#!/usr/bin/env bash
set -euo pipefail

REPORT_PATH=${1:-""}
WINDOW_TITLE=${2:-"AI Report"}
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"

if [[ -z "$REPORT_PATH" ]]; then
  echo "Usage: open_report_window.sh /path/to/report.html [window-title]"
  exit 1
fi

REPORT_PATH=$(python3 - <<PY
from pathlib import Path
print(Path("$REPORT_PATH").expanduser().resolve())
PY
)

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VIEWER_SRC="$SCRIPT_DIR/../assets/report-viewer/ReportViewer.swift"
BUILD_DIR="$CODEX_HOME_DIR/skill-workspaces/artifacts/report-viewer"
APP_DIR="$BUILD_DIR/ReportViewer.app"
BIN_PATH="$APP_DIR/Contents/MacOS/ReportViewer"
PLIST_PATH="$APP_DIR/Contents/Info.plist"

mkdir -p "$APP_DIR/Contents/MacOS"

if [[ ! -f "$PLIST_PATH" || "$VIEWER_SRC" -nt "$PLIST_PATH" ]]; then
  cat <<PLIST > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>ReportViewer</string>
  <key>CFBundleIdentifier</key>
  <string>com.tokonix.ReportViewer</string>
  <key>CFBundleName</key>
  <string>ReportViewer</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
</dict>
</plist>
PLIST
fi

if [[ ! -f "$BIN_PATH" || "$VIEWER_SRC" -nt "$BIN_PATH" ]]; then
  echo "Building report viewer..."
  swiftc -framework AppKit -framework WebKit "$VIEWER_SRC" -o "$BIN_PATH"
fi

LOG_PATH="$BUILD_DIR/ReportViewer.log"
REPORT_VIEWER_LOG="$LOG_PATH" open -n "$APP_DIR" --args "$REPORT_PATH" "$WINDOW_TITLE" >/dev/null 2>&1 &
echo "Report window launched. Logs: $LOG_PATH"
