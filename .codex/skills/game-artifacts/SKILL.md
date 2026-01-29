---
name: game-artifacts
description: Build fully fledged games using Phaser + Electron.
---

# Game Artifacts

Use this skill when the agent needs to build a complete, playable full game experience.

Paths below use `$CODEX_HOME` (defaults to `~/.codex`).

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Quality bar

- Research what makes this genre great before building.
- Ship a complete, polished game (start screen, pause, restart, win/lose state, instructions).
- Add feedback (sound + VFX) and progression when appropriate.
- The game must be fully playable end-to-end with all core features implemented.
- Do not ship partial mechanics, placeholder art, or missing gameplay loops.
- First step: write a plan. Summarize the game concept, list required features and systems, and research what “complete” looks like for the genre.
- Create `plan.md` in the game workspace and capture the full feature list plus how each feature should behave.
- Build from the plan and keep it aligned as you implement.
- No feature should be incomplete. Each item in the plan must be robust, fully implemented, and make sense end-to-end.
- Research why each feature matters, how it’s used, and what makes it effective in great games.
- Always create a fresh workspace per request. Do not reuse older builds or code.

## Build + launch expectations

- Ensure the dev port is free. If 5173 is taken, pick a free port and pass it to the dev command.
- Launch with `nohup` so the game stays open.
- Confirm the correct new build opens as a desktop app (Electron), not a browser.

## Quick start

1) Create a workspace:
   - `$CODEX_HOME/skills/game-artifacts/scripts/setup_games_workspace.sh $CODEX_HOME/skill-workspaces/artifacts/games <game_slug>`
2) Launch dev:
   - `cd $CODEX_HOME/skill-workspaces/artifacts/games/<game_slug> && npm run dev`

## References

- `references/games.md`: Phaser template usage.
- `references/game-template-spec.md`: layout/motion rules.

## Notes

- The setup script shares an Electron cache and retries if Electron fails to download.
