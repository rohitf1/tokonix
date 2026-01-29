#!/usr/bin/env bash
set -euo pipefail

VIDEO_PATH=${1:-""}
if [[ -z "$VIDEO_PATH" ]]; then
  echo "Usage: open_video_file.sh /path/to/video.mp4" >&2
  exit 1
fi

if command -v open >/dev/null 2>&1; then
  open "$VIDEO_PATH"
else
  echo "open command not available." >&2
  exit 1
fi
