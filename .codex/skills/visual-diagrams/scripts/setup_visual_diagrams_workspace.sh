#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/visual-diagrams"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-visual-diagrams}"
DEST="$ROOT/$SLUG"

if [ -e "$DEST" ]; then
  echo "Workspace already exists: $DEST" >&2
  exit 1
fi

mkdir -p "$DEST"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../assets/visual-diagrams-template"

cp -R "$TEMPLATE_DIR/"* "$DEST"

pushd "$DEST" >/dev/null
npm install
popd >/dev/null

echo "Visual diagrams workspace ready in $DEST"
