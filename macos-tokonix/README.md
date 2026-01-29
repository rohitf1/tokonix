# Tokonix (macOS)

Floating always-on-top voice button that transcribes speech, sends it to the Codex CLI (via the `tokonix` wrapper) using `app-server`, and speaks responses.
Tokonix Overlay is a UI wrapper around the Codex CLI.

This repo includes two pieces:
1) **Codex CLI** (the command-line app that talks to the service)
2) **Tokonix Overlay** (this macOS app). The overlay launches the CLI internally.

## Default safety mode
- This overlay runs in YOLO mode by default:
  - `approvalPolicy=never` (auto-approve actions)
  - `sandbox=dangerFullAccess`
  - `features.exec_policy=false`

## Overlay profile (default)
- The overlay uses its own home directory by default:
  - `~/Library/Application Support/Tokonix/overlay`
- A default `AGENTS.md` is created there on first launch for overlay-only instructions.
- To share sessions/instructions with the CLI, set `TOKONIX_VOICE_OVERLAY_HOME` to the CLI home.

## Instructions editor
- Open the overlay menu -> **Instructions** to edit overlay-only guidance.
- Click **Save** to persist changes, or **Apply & Restart** to reload instructions (restarts the app-server without closing the overlay).

## Tech stack
- Swift 5.9 + SwiftUI (macOS app UI)
- AppKit + WebKit (windowing + embedded webview)
- AVFoundation + Speech (microphone + transcription)
- Bundled Three.js (rendered inside a local `WKWebView`, no external JS package manager)

## Requirements
- macOS with microphone + speech recognition permissions available.
- Network access (the overlay talks to the Tokonix app-server).
- Xcode Command Line Tools (provides `swift`) to build the overlay.
- Rust toolchain to build the Codex CLI.
- Authentication: run `tokonix login` once or set `TOKONIX_VOICE_OVERLAY_API_KEY`.

## Quick start

### If you already use Codex CLI
```bash
# Optional: reuse your existing Codex auth profile
export TOKONIX_VOICE_OVERLAY_HOME="$HOME/.codex"

# Optional: ensure the overlay finds your Codex CLI
export TOKONIX_VOICE_OVERLAY_BIN=codex

cd /path/to/tokonix/macos-tokonix
./build_app.sh
open dist/Tokonix.app
```

### If you are new to Tokonix
1) Build the Codex CLI (follow the repo’s main README).
2) Enable the `tokonix` wrapper:
```bash
cd /path/to/tokonix
./scripts/tokonix --help
# Optional: add to PATH
ln -s "$(pwd)/scripts/tokonix" /opt/homebrew/bin/tokonix
```
3) Log in once:
```bash
tokonix login
```
4) Build and open the overlay app:
```bash
cd /path/to/tokonix/macos-tokonix
./build_app.sh
open dist/Tokonix.app
```

## Launch via CLI
```bash
tokonix overlay
```

To build before launching:
```bash
tokonix overlay --build
```

If `tokonix` is not on the default PATH for GUI apps, either set `TOKONIX_VOICE_OVERLAY_BIN` to the absolute path or ensure `tokonix` is in `/opt/homebrew/bin` or `/usr/local/bin`.
By default, the overlay will try to locate a repo-built Codex CLI binary if the app bundle lives inside this repo; otherwise it falls back to `tokonix` on PATH.

## Run from source (SwiftPM)
```bash
cd /path/to/tokonix/macos-tokonix
swift run tokonix
```

## Authentication and settings
- The overlay uses `TOKONIX_VOICE_OVERLAY_HOME` to find auth data.
- If you already have an authenticated Codex CLI, point `TOKONIX_VOICE_OVERLAY_HOME` to reuse it.
- You can also set `TOKONIX_VOICE_OVERLAY_API_KEY` for first-time login.
- The default overlay home is separate from the CLI, so it keeps its own login and sessions unless you override it.

### Optional environment overrides
```bash
# Use a different tokonix binary (ex: tokonix-beta)
export TOKONIX_VOICE_OVERLAY_BIN=tokonix-beta

# Provide an API key for first-time login
export TOKONIX_VOICE_OVERLAY_API_KEY=sk-...

# Use a separate settings/history location (default is the overlay profile path)
export TOKONIX_VOICE_OVERLAY_HOME=~/.tokonix-overlay

# Set a default working directory for the agent
export TOKONIX_VOICE_OVERLAY_CWD=~/Projects

# Pin a model (optional)
export TOKONIX_VOICE_OVERLAY_MODEL=your-model-id
```

## Troubleshooting
- "No active Tokonix thread is available": run `tokonix login`, set `TOKONIX_VOICE_OVERLAY_API_KEY`, or point `TOKONIX_VOICE_OVERLAY_HOME` at an existing authenticated profile.
- "Unable to find tokonix": set `TOKONIX_VOICE_OVERLAY_BIN` to the absolute path of the Codex CLI binary.
- Permissions prompts are tied to the app that requests them. When using `swift run`, the prompt is usually associated with Terminal.

## Common pitfalls
- The overlay runs as a GUI app, so it may not see your shell PATH. If `tokonix` works in Terminal but not in the overlay, set `TOKONIX_VOICE_OVERLAY_BIN`.
- If login keeps repeating, confirm `TOKONIX_VOICE_OVERLAY_HOME` points to the same profile you authenticated with.

## Notes
- This app spawns `tokonix app-server` and talks JSON-RPC over stdio.
- Hard YOLO mode: `approvalPolicy=never`, `sandbox=dangerFullAccess`, and `features.exec_policy=false`.
- The app-server is launched with `--config cli_auth_credentials_store=auto` so it can reuse `~/.tokonix/auth.json` if keychain auth is unavailable.
