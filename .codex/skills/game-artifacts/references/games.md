# Game artifacts (Phaser + Electron)

## Quick start

1) Create a per-game workspace and install deps:
   `$CODEX_HOME/skills/game-artifacts/scripts/setup_games_workspace.sh $CODEX_HOME/skill-workspaces/artifacts/games <game_slug>`

2) Run the game:
   `cd $CODEX_HOME/skill-workspaces/artifacts/games/<game_slug> && npm run dev`

## Fast-path template rules

Use the fixed layout and styling guidelines in `references/game-template-spec.md` to keep game generation fast and consistent. The quality bar is explicit: primary actors must read as real objects (no blocky primitives).

## Default workspace path

- Game root: `$CODEX_HOME/skill-workspaces/artifacts/games`
- Each game lives in its own folder under the root (for example: `$CODEX_HOME/skill-workspaces/artifacts/games/algorithm-academy`).

## Template structure

- `main.js`: Electron main process and window options
- `index.html`: renderer entrypoint
- `game.js`: Phaser scene, visuals, and interaction loop (per game folder)
- `zzfx.js`: procedural sound synth (optional SFX)

## Game scaffold

- The bundled `game.js` is a polished Phaser mini-game scaffold:
  - Pointer/keyboard input with a tight loop.
  - Neon gradient + glow framing + layered particles for depth.
  - Layered shapes with glow, rotation, and motion for core entities.
  - ZzFX cues for core actions via `ensureAudio`/`unlockAudio`.

## Sound effects (ZzFX)

- `zzfx.js` is bundled for procedural sound effects.
- `index.html` uses `type="module"` so `game.js` can `import { zzfx, ZZFX } from "./zzfx.js"`.
- Initialize audio on user input (first key press) to satisfy autoplay rules.

## Window behavior

- Change window size/behavior in `main.js` (width, height, backgroundColor).
- For always-on-top or frameless windows, update `BrowserWindow` options.
- Use `win.setAlwaysOnTop(true)` if needed after creation.

## Game editing tips

- The scene lives in `game.js` (visuals, input, update loop).
- Use Phaser particle emitters for depth: keep one far and one near emitter for parallax.
- Keep assets inline to avoid extra load steps unless needed.
