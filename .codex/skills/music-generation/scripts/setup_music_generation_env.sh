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

python3 -m venv "$WORKSPACE/.venv"
# shellcheck disable=SC1091
source "$WORKSPACE/.venv/bin/activate"

python -m pip install --upgrade pip
python -m pip install -r "$WORKSPACE/requirements.txt"

echo "Music generation venv ready at $WORKSPACE/.venv"
