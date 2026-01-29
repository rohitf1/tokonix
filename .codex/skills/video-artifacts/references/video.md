# Video artifacts

## Quick flow

1) Setup workspace:
   `$CODEX_HOME/skills/video-artifacts/scripts/setup_video_workspace.sh $CODEX_HOME/skill-workspaces/video-artifacts <slug>`
2) Preview:
   `$CODEX_HOME/skills/video-artifacts/scripts/open_video_studio.sh $CODEX_HOME/skill-workspaces/video-artifacts <slug>`
3) Render:
   `$CODEX_HOME/skills/video-artifacts/scripts/render_video.sh $CODEX_HOME/skill-workspaces/video-artifacts <slug> Demo out.mp4`

## Composition tips

- Set `width`, `height`, `fps`, `durationInFrames` in `src/Root.jsx`.
- Create multiple compositions to offer different sizes or variants.
- Pass props via `defaultProps` to make editing text/data easy.
