---
name: app-artifacts
description: Build complete desktop apps using Electron + Vite + React.
---

# App Artifacts

Use this skill when the agent needs to build a full application with a real UI and behavior.

Paths below use `$CODEX_HOME` (defaults to `~/.codex`).

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Quality bar

- Research real products and standards in the category before building.
- Deliver a production-ready result, not a demo.
- The app must be complete, functional, and polished with all expected features implemented.
- Do not ship partial flows, placeholder screens, or missing core functionality.
- First step: write a plan. Summarize what the user asked for, list required features, and research what “complete” looks like for each feature.
- Create `plan.md` in the app workspace and capture the full feature list plus how each feature should behave.
- Build from the plan and keep it aligned as you implement.
- No feature should be incomplete. Each item in the plan must be robust, fully implemented, and make sense end-to-end.
- Research why each feature matters, how it’s used, and what makes it effective in real products.
- Always create a fresh workspace per request. Do not reuse older builds or code.

## Build + launch expectations

- Ensure the dev port is free. If 5173 is taken, pick a free port and pass it to the dev command.
- Launch with `nohup` so the app stays open.
- Confirm the correct new build opens as a desktop app (Electron), not a browser.

## Quick start

1) Create a workspace:
   - `$CODEX_HOME/skills/app-artifacts/scripts/setup_apps_workspace.sh $CODEX_HOME/skill-workspaces/artifacts/apps <app_slug>`
2) Launch dev:
   - `cd $CODEX_HOME/skill-workspaces/artifacts/apps/<app_slug> && npm run dev`

## References

- `references/apps.md`: usage and workspace structure.
- `references/app-template-spec.md`: layout and styling rules.

## Notes

- The setup script shares an Electron cache and retries if Electron fails to download.
