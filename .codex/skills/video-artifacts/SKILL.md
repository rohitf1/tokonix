---
name: video-artifacts
description: Create high‑quality videos using Remotion (React + programmatic animation) and render to MP4.
---

# Video Artifacts

Use this skill when the agent needs to create polished explainer videos, animated charts, or motion pieces.

Paths below use `$CODEX_HOME` (defaults to `~/.codex`).

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Quality bar

- Do visual research and gather multiple high-quality assets before building.
- Use strong typography, clear layout, and professional motion.
- Default to a dark theme with muted colors (avoid bright/neon).
- Render at 1920x1080 with higher-quality encoding settings by default.
- Use high-contrast text panels and clearer typography.
- Use image grids per category so every slide has real images.
- Add light sweep, glow layers, vignette, and parallax motion for stronger emotion and energy.
- Validate that all assets load correctly.
- Use polished effects and rich motion; add as many media assets as needed to make the video look great.
- Check for broken image links and empty/blank slides before rendering.
- After rendering, open the newest video file and confirm it plays (do not reopen an older render).
- Always create a fresh workspace per request. Do not reuse older builds or timelines.
- Open the rendered video and confirm it plays correctly.

## Known bug to avoid

- Never allow empty slides. A common cause is double-offsetting timing:
  - Each slide in a `Sequence` is already offset by its `from` time.
  - Do not subtract the start time again inside the slide component (for example in `SlideCard`), or opacity can stay at zero.
  - Build slide timing so it is offset exactly once, then verify each slide renders visibly.

## Mandatory checklists

Image validation checklist
1. Verify every image file exists and has non zero size.
2. Open a quick preview of each image before rendering.
3. Render a still frame from each slide and visually confirm images are present.
4. Fail the build if any image is missing or cannot be loaded.
5. Keep a single source of truth for image paths and do not change them during fixes.

Empty slide prevention checklist
1. Use local frame time inside each slide component, do not subtract the Sequence start again.
2. Add a temporary debug overlay that shows current frame and slide index during preview.
3. Render still frames at the midpoint of each slide to confirm content appears.
4. Avoid changing animation math and layout in the same edit. Fix timing first, then visuals.
5. Keep a minimal smoke test that renders five sampled frames and checks they are not blank.

## Quick start

1) Create a workspace:
   - `$CODEX_HOME/skills/video-artifacts/scripts/setup_video_workspace.sh $CODEX_HOME/skill-workspaces/video-artifacts <slug>`
2) Preview the video:
   - `$CODEX_HOME/skills/video-artifacts/scripts/open_video_studio.sh $CODEX_HOME/skill-workspaces/video-artifacts <slug>`
3) Render to MP4:
   - `$CODEX_HOME/skills/video-artifacts/scripts/render_video.sh $CODEX_HOME/skill-workspaces/video-artifacts <slug> Demo out.mp4`
4) Open the rendered file:
   - `$CODEX_HOME/skills/video-artifacts/scripts/open_video_file.sh $CODEX_HOME/skill-workspaces/video-artifacts/<slug>/out.mp4`

## Scripts

- `scripts/setup_video_workspace.sh`: creates a Remotion workspace from the template.
- `scripts/open_video_studio.sh`: launches Remotion Studio preview.
- `scripts/render_video.sh`: renders a composition to a video file.
- `scripts/open_video_file.sh`: opens the rendered video in the default macOS player.

## Template

- `assets/video-template`: minimal Remotion project with a sample composition (`Demo`).

## References

- `references/video.md`: quick flow + composition tips.

## Notes

- Use Remotion compositions to control size, fps, and duration.
- Render options (codec, quality, fps, size) can be passed through `render_video.sh` as extra args.
