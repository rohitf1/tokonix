#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/visual-diagrams"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-visual-diagrams}"
TITLE="${3:-${VISUAL_DIAGRAMS_TITLE:-${VISUAL_NOTES_TITLE:-Visual Diagrams}}}"
WORKSPACE="$ROOT/$SLUG"
PORT_FILE="$WORKSPACE/.visual-diagrams-port"
DEV_LOG="$WORKSPACE/visual-diagrams.dev.log"
LEGACY_PORT_FILE="$WORKSPACE/.visual-notes-port"
LEGACY_DEV_LOG="$WORKSPACE/visual-notes.dev.log"

if [[ ! -d "$WORKSPACE" ]]; then
  echo "Workspace not found: $WORKSPACE" >&2
  echo "Run setup_visual_diagrams_workspace.sh first." >&2
  exit 1
fi

if [[ ! -d "$WORKSPACE/node_modules" ]]; then
  (cd "$WORKSPACE" && npm install && npm install @excalidraw/excalidraw)
elif [[ ! -d "$WORKSPACE/node_modules/@excalidraw/excalidraw" ]]; then
  (cd "$WORKSPACE" && npm install @excalidraw/excalidraw)
fi

port_open() {
  python3 - "$1" <<'PY'
import socket
import sys

port = int(sys.argv[1])
with socket.socket() as s:
    s.settimeout(0.2)
    try:
        s.connect(("127.0.0.1", port))
    except Exception:
        sys.exit(1)
sys.exit(0)
PY
}

extract_port_from_log() {
  python3 - "$DEV_LOG" <<'PY'
import re
import sys

path = sys.argv[1]
try:
    text = open(path, "r", encoding="utf-8").read()
except Exception:
    sys.exit(1)
m = re.search(r"http://127\\.0\\.0\\.1:(\\d+)/", text)
if not m:
    sys.exit(1)
print(m.group(1))
PY
}

pick_free_port() {
  for p in 5173 5174 5175 5176 5177 5178 5179 5180 5181 5182 5183; do
    if ! port_open "$p"; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

PORT="${VISUAL_DIAGRAMS_PORT:-${VISUAL_NOTES_PORT:-}}"
if [[ -z "$PORT" && -f "$DEV_LOG" ]]; then
  PORT="$(extract_port_from_log || true)"
fi
if [[ -z "$PORT" && -f "$PORT_FILE" ]]; then
  PORT="$(tr -d '[:space:]' < "$PORT_FILE")"
fi
if [[ -z "$PORT" && -f "$LEGACY_DEV_LOG" ]]; then
  DEV_LOG="$LEGACY_DEV_LOG"
  PORT="$(extract_port_from_log || true)"
  DEV_LOG="$WORKSPACE/visual-diagrams.dev.log"
fi
if [[ -z "$PORT" && -f "$LEGACY_PORT_FILE" ]]; then
  PORT="$(tr -d '[:space:]' < "$LEGACY_PORT_FILE")"
fi
if [[ -z "$PORT" ]]; then
  PORT="5173"
fi

if ! port_open "$PORT"; then
  FREE_PORT="$PORT"
  if port_open "$FREE_PORT"; then
    FREE_PORT="$(pick_free_port || true)"
  fi
  if [[ -z "${FREE_PORT:-}" ]]; then
    echo "No free port found for visual notes." >&2
    exit 1
  fi
  PORT="$FREE_PORT"
  (cd "$WORKSPACE" && nohup npm run dev -- --host 127.0.0.1 --port "$PORT" --strictPort > "$DEV_LOG" 2>&1 &)
  printf '%s\n' "$PORT" > "$PORT_FILE"
  for _ in $(seq 1 40); do
    if port_open "$PORT"; then
      break
    fi
    sleep 0.2
  done
fi

URL="http://127.0.0.1:$PORT/"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VIEWER_SRC="$SCRIPT_DIR/../assets/web-viewer/WebViewer.swift"
BUILD_DIR="$CODEX_HOME_DIR/skill-workspaces/visual-diagrams/web-viewer"
BIN_PATH="$BUILD_DIR/WebViewer"

mkdir -p "$BUILD_DIR"

if [[ ! -f "$BIN_PATH" || "$VIEWER_SRC" -nt "$BIN_PATH" ]]; then
  swiftc -framework AppKit -framework WebKit "$VIEWER_SRC" -o "$BIN_PATH"
fi

LOG_PATH="$BUILD_DIR/WebViewer.log"
nohup "$BIN_PATH" "$URL" "$TITLE" > "$LOG_PATH" 2>&1 &

echo "Visual Diagrams window launched: $URL"
echo "Logs: $LOG_PATH"
