#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.tokonix}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/iot-automations"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-iot-automations}"
ACTION="${3:-status}"
WORKSPACE="$ROOT/$SLUG"

if [ ! -d "$WORKSPACE" ]; then
  echo "Workspace not found: $WORKSPACE" >&2
  exit 1
fi

if [ ! -f "$WORKSPACE/tuya_bulb.py" ]; then
  echo "tuya_bulb.py not found in $WORKSPACE" >&2
  exit 1
fi

if [ -f "$WORKSPACE/env.sh" ]; then
  # shellcheck disable=SC1091
  source "$WORKSPACE/env.sh"
fi

python3 "$WORKSPACE/tuya_bulb.py" "$ACTION"
