#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.tokonix}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/music-generation"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-music-generation}"
DEST="$ROOT/$SLUG"

if [ -e "$DEST" ]; then
  echo "Workspace already exists: $DEST" >&2
  exit 1
fi

mkdir -p "$DEST"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../assets/music-generation-template"

cp -R "$TEMPLATE_DIR/"* "$DEST"

echo "Music generation workspace ready in $DEST"
