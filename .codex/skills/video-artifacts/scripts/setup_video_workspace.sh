#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/video-artifacts"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-}"

if [[ -z "$SLUG" ]]; then
  echo "Usage: setup_video_workspace.sh <root> <slug>" >&2
  exit 1
fi

DEST="$ROOT/$SLUG"
if [[ -d "$DEST" ]]; then
  echo "Video workspace already exists: $DEST" >&2
  exit 0
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../assets/video-template"

mkdir -p "$DEST"
cp -R "$TEMPLATE_DIR/"* "$DEST"

pushd "$DEST" >/dev/null
npm install
popd >/dev/null

echo "Video workspace ready at $DEST"
