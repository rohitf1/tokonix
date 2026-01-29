#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/simple-notes"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-simple-notes}"
TITLE="${3:-Simple Notes}"
WORKSPACE="$ROOT/$SLUG"
NOTES_FILE="$WORKSPACE/notes.txt"

if [[ ! -d "$WORKSPACE" ]]; then
  mkdir -p "$WORKSPACE"
fi

if [[ ! -f "$NOTES_FILE" ]]; then
  SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  TEMPLATE_DIR="$SCRIPT_DIR/../assets/simple-notes-template"
  if [[ -f "$TEMPLATE_DIR/notes.txt" ]]; then
    cp "$TEMPLATE_DIR/notes.txt" "$NOTES_FILE"
  else
    printf '%s\n' "# Notes" "" "Add your notes here." > "$NOTES_FILE"
  fi
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VIEWER_SRC="$SCRIPT_DIR/../assets/notes-viewer/NotesViewer.swift"
BUILD_DIR="$CODEX_HOME_DIR/skill-workspaces/simple-notes/notes-viewer"
APP_DIR="$BUILD_DIR/NotesViewer.app"
BIN_PATH="$APP_DIR/Contents/MacOS/NotesViewer"
PLIST_PATH="$APP_DIR/Contents/Info.plist"

mkdir -p "$APP_DIR/Contents/MacOS"

if [[ ! -f "$PLIST_PATH" || "$VIEWER_SRC" -nt "$PLIST_PATH" ]]; then
  cat <<PLIST > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>NotesViewer</string>
  <key>CFBundleIdentifier</key>
  <string>com.tokonix.NotesViewer</string>
  <key>CFBundleName</key>
  <string>NotesViewer</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
</dict>
</plist>
PLIST
fi

if [[ ! -f "$BIN_PATH" || "$VIEWER_SRC" -nt "$BIN_PATH" ]]; then
  echo "Building notes viewer..."
  swiftc -framework AppKit "$VIEWER_SRC" -o "$BIN_PATH"
fi

LOG_PATH="$BUILD_DIR/NotesViewer.log"
NOTES_VIEWER_LOG="$LOG_PATH" open -n "$APP_DIR" --args "$NOTES_FILE" "$TITLE" >/dev/null 2>&1 &
echo "Simple notes window launched. Logs: $LOG_PATH"
