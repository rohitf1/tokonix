#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ROOT_DEFAULT="$CODEX_HOME_DIR/skill-workspaces/video-artifacts"
ROOT="${1:-$ROOT_DEFAULT}"
SLUG="${2:-}" 
COMP_ID="${3:-Demo}"
OUT_PATH="${4:-out.mp4}"

if [[ -z "$SLUG" ]]; then
  echo "Usage: render_video.sh <root> <slug> [composition_id] [out_path] [extra_remotion_args...]" >&2
  exit 1
fi

WORKSPACE="$ROOT/$SLUG"
if [[ ! -d "$WORKSPACE" ]]; then
  echo "Workspace not found: $WORKSPACE" >&2
  exit 1
fi

shift 4 || true

pushd "$WORKSPACE" >/dev/null
npm install
npx remotion render src/index.jsx "$COMP_ID" "$OUT_PATH" "$@"
popd >/dev/null

echo "Rendered video: $WORKSPACE/$OUT_PATH"
