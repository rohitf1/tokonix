---
name: music-generation
description: Generate procedural music with Python + NumPy and render WAV files.
---

# Music Generation

## Default stack (recommended)

- Python 3.10+
- NumPy
- Pure math-based synthesis (no external audio tools required)

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Setup (one-time)

- Create a workspace:
  - `scripts/setup_music_generation_workspace.sh $CODEX_HOME/skill-workspaces/music-generation <slug>`
- Create a venv and install NumPy:
  - `scripts/setup_music_generation_env.sh $CODEX_HOME/skill-workspaces/music-generation <slug>`

## Run (recommended)

- Use the launcher:
  - `scripts/run_music_generation.sh $CODEX_HOME/skill-workspaces/music-generation <slug>`

## Output

- The script writes a WAV file in the workspace (default: `lofi.wav`).

## Agent guidance

- Keep everything math-based and deterministic unless the user asks for randomness.
- Prefer editing constants at the top of `music_gen.py` (tempo, bars, key) instead of rewriting core DSP.
- If the user wants a different style, edit the progression, melody, and synthesis parameters.
- Create a fresh workspace per new request to avoid overwriting older outputs.

## Alternatives

- `pydub` or `librosa` for audio processing (not required).
