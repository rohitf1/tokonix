<p align="center">
  <img src=".github/tokonix-orb.gif" width="360" alt="Tokonix orb demo" />
</p>

<h1 align="center">Tokonix</h1>
<p align="center">Voice-native macOS AI experience</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-macOS-111111?logo=apple&logoColor=white" />
  <img alt="license" src="https://img.shields.io/badge/license-Apache--2.0-2F7DD7" />
  <img alt="overlay" src="https://img.shields.io/badge/voice--first-overlay-00B5AD" />
</p>

## Overview

Tokonix is a fork of the **OpenAI Codex CLI** that adds a macOS voice overlay. 

## Why I Built It

I believe the future of AI is hands-free. Codex is powerful but lives inside developer tools; Tokonix brings that power into a voice-first experience anyone can use.

## Features

- Floating voice orb with live audio reactivity and silence detection.
- Real-time captions for both you and the assistant.
- Reasoning stream + thinking timer for visible progress.
- Configuration panel for model, reasoning effort, voice, skills, instructions, history, and diagnostics.
- Skill tooling for apps, games, videos, reports, diagrams, notes, music, and IoT automations.

## Tech Stack

- Overlay UI: Swift 5.9 + SwiftUI + AppKit + WebKit
- Orb rendering: Three.js in a local WKWebView
- Voice: AVFoundation + Speech (native macOS)
- Agent backend: Codex CLI (codex-rs) via local app-server

## Quickstart (macOS)

### 1) Install Codex CLI

Use a system install **or** build from this repo.

```bash
# Option A: install using npm
npm install -g @openai/codex

# Option A: install using Homebrew
brew install --cask codex
```

```bash
# Option B: build from this repo
cd /path/to/tokonix/codex-rs
cargo build -p codex-cli
```

### 2) Install the Tokonix wrapper

```bash
cd /path/to/tokonix
./scripts/tokonix --help

# Optional: add to PATH
ln -s "$(pwd)/scripts/tokonix" /opt/homebrew/bin/tokonix
# or
ln -s "$(pwd)/scripts/tokonix" /usr/local/bin/tokonix
```

### 3) Authenticate

When the overlay starts, it automatically opens the browser login if you are not signed in.

You can also provide an API key for first-time login:

```bash
export TOKONIX_VOICE_OVERLAY_API_KEY=sk-...
```

### 4) Build and run the overlay

```bash
cd /path/to/tokonix/macos-tokonix
./build_app.sh
open dist/Tokonix.app
```

## Commands

```bash
# Start Codex CLI

tokonix

# Launch overlay

tokonix overlay

# Build overlay, then launch

tokonix overlay --build
```

## Environment Variables (Overlay)

- `TOKONIX_HOME` - profile directory (default: `~/.tokonix`)
- `TOKONIX_VOICE_OVERLAY_HOME` - override overlay profile directory
- `TOKONIX_VOICE_OVERLAY_BIN` - override the Codex/Tokonix binary the overlay uses
- `TOKONIX_VOICE_OVERLAY_API_KEY` - API key for first-time login
- `TOKONIX_VOICE_OVERLAY_CWD` - default working directory for the agent
- `TOKONIX_VOICE_OVERLAY_MODEL` - pin a model for new turns
- `TOKONIX_OVERLAY_APP` - path to Tokonix.app for `tokonix overlay`

## Repo Layout

- `codex-rs/` - the Codex CLI (Rust)
- `macos-tokonix/` - the macOS voice overlay app (Swift/SwiftUI + WebKit)
- `scripts/tokonix` - wrapper that sets `TOKONIX_HOME` and dispatches to Codex + overlay

## Safety Defaults (Overlay)

- `approvalPolicy=never` (auto-approve actions)
- `sandbox=danger-full-access`
- `features.exec_policy=false`

## License

Tokonix is a fork of OpenAI Codex CLI and remains licensed under the [Apache-2.0 License](LICENSE).
