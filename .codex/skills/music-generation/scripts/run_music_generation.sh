#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.tokonix}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/music-generation"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-music-generation}"
WORKSPACE="$ROOT/$SLUG"

if [ ! -d "$WORKSPACE" ]; then
  echo "Workspace not found: $WORKSPACE" >&2
  exit 1
fi

PYTHON_BIN="python3"
if [ -x "$WORKSPACE/.venv/bin/python" ]; then
  PYTHON_BIN="$WORKSPACE/.venv/bin/python"
fi

"$PYTHON_BIN" "$WORKSPACE/music_gen.py"
