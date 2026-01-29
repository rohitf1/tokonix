#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_ROOT=${1:-"$CODEX_HOME_DIR/skill-workspaces/artifacts/games"}
GAME_SLUG=${2:-""}
DEST_DIR="$DEST_ROOT"
ELECTRON_CACHE="${ELECTRON_CACHE:-$CODEX_HOME_DIR/skill-workspaces/artifacts/.electron-cache}"
ELECTRON_BUILDER_CACHE="${ELECTRON_BUILDER_CACHE:-$CODEX_HOME_DIR/skill-workspaces/artifacts/.electron-builder-cache}"

if [[ -n "$GAME_SLUG" ]]; then
  DEST_DIR="$DEST_ROOT/$GAME_SLUG"
fi
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../assets/games-template"

if [[ -d "$DEST_DIR" ]]; then
  echo "Games workspace already exists: $DEST_DIR"
  exit 0
fi

mkdir -p "$DEST_DIR"
cp -R "$TEMPLATE_DIR/"* "$DEST_DIR"

pushd "$DEST_DIR" >/dev/null
export ELECTRON_CACHE
export ELECTRON_BUILDER_CACHE
mkdir -p "$ELECTRON_CACHE" "$ELECTRON_BUILDER_CACHE"
npm install
if ! node -e "require('electron')" >/dev/null 2>&1; then
  echo "Electron install looks incomplete; retrying..." >&2
  rm -rf node_modules/electron
  npm install
  node -e "require('electron')" >/dev/null 2>&1 || {
    echo "Electron install failed. Try deleting node_modules and re-running." >&2
    exit 1
  }
fi
popd >/dev/null

echo "Games workspace ready at $DEST_DIR"
