# Game template spec (fast path)

Use this spec to build Phaser + Electron games quickly and consistently. Do not redesign unless explicitly requested.

## Window & layout

- Window: 960x720 (default) with dark background `#05060b`.
- Canvas auto-resize with `Phaser.Scale.RESIZE` and `CENTER_BOTH`.
- Keep a centered playfield with generous padding (`52px`).

## Visual direction (next-level)

- Use layered backgrounds: a soft gradient base + neon grid or sweep overlay + glow frame.
- Add atmospheric depth using 2 particle layers:
  - Far layer: slow, low alpha, small scale, additive blend.
  - Near layer: faster, larger scale, slightly higher alpha, additive blend.
- Add a subtle sweep or scanline motion for energy.
- Use additive glows for the main actor and key effects.
- Primary actors should read clearly as their intended objects. Avoid simple blocks; build silhouettes with curves, wheels/panels, and layered details.

## Quality bar (make it look awesome)

- Silhouette: the main actor must read instantly (car looks like a car, ship looks like a ship).
- Layering: build each actor from shadow + body + highlight + accent (minimum 4 layers).
- Materials: use subtle gradients and rim glow; avoid flat single-color fills for primary actors.
- Depth: scale and alpha should subtly change with distance; far elements should feel lighter and dimmer.
- Accents: include small, crisp details (lights, vents, trim, or panels) for realism.

## Typography

- Font: "Space Grotesk", fallback "Segoe UI", sans-serif.
- HUD text sizes: title 18px, helper 13px.
- Use light text `#e6f3ff` and muted `#9bb0c9`.

## Color system

- Background: `#05060b`.
- Grid: `#162039` at 35% alpha.
- Border: `#4cc3ff` at 35% alpha.
- Accent palette: `#4cc3ff`, `#6aa9ff`, `#b44bff`, `#ff4fd8`.

## Motion

- Drive movement from `delta` (seconds) to keep motion stable on any frame rate.
- Maintain at least two rhythms: a steady baseline drift and a reactive burst when input/events occur.
- Use easing on glow pulses and UI feedback; avoid abrupt starts/stops.

## UI polish

- HUD panels: translucent rounded rectangles with thin neon strokes (no hard blocks).
- Keep HUD readable at a glance; avoid long helper text.
- Keep UI outside the core playfield; never occlude the main actor.

## Gameplay

- Controls: Arrow keys + WASD; `Space` or `Shift` for a special action; `R` resets.
- Keep a single clear loop (score, distance, survival, or timer).
- Provide minimal helper text (short hints only).
- Use responsive feedback (flash, pulse, particles) for every core action.

## Sound

- Use ZzFX (`zzfx.js`) for procedural SFX.
- Keep `ZZFX.volume = 0.20–0.30`.
- Default cues: action, impact, boost/special, reset.

## Performance guardrails

- Particle counts: keep under ~60 active combined emitters.
- Destroy or recycle bursts promptly.
- Avoid large texture assets; prefer Phaser shapes + gradients.

## Assets

- No external image assets by default.
- Use Phaser shapes + text for HUD and core visuals.
