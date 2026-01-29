#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR=${1:-"$CODEX_HOME_DIR/skill-workspaces/artifacts/report"}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../assets/report-template"

if [[ -d "$DEST_DIR" ]]; then
  echo "Report workspace already exists: $DEST_DIR"
  exit 0
fi

mkdir -p "$DEST_DIR"
cp -R "$TEMPLATE_DIR/"* "$DEST_DIR"

echo "Report workspace created at $DEST_DIR"
