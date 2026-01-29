#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/video-artifacts"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-}"

if [[ -z "$SLUG" ]]; then
  echo "Usage: open_video_studio.sh <root> <slug>" >&2
  exit 1
fi

WORKSPACE="$ROOT/$SLUG"
if [[ ! -d "$WORKSPACE" ]]; then
  echo "Workspace not found: $WORKSPACE" >&2
  exit 1
fi

pushd "$WORKSPACE" >/dev/null
npm install
nohup npx remotion studio src/index.jsx > remotion-studio.log 2>&1 &
popd >/dev/null

if command -v open >/dev/null 2>&1; then
  open http://localhost:3000/ || true
fi

echo "Remotion Studio launched. Logs: $WORKSPACE/remotion-studio.log"
