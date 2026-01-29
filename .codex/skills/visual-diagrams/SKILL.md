---
name: visual-diagrams
description: Create visual diagrams or sketchpad panels for the Tokonix overlay using an embedded web canvas (Excalidraw by default).
---

# Visual Diagrams (Sketchpad)

## Default stack (recommended)

- WKWebView host inside the overlay.
- Excalidraw (React) for the sketchpad UI.

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Setup (one-time)

- Requires Node.js 18+ and npm.
- The workspace uses a pinned template in `assets/visual-diagrams-template` to keep Excalidraw stable.
- Run:
  - `scripts/setup_visual_diagrams_workspace.sh $CODEX_HOME/skill-workspaces/visual-diagrams <slug>`

## Open the sketchpad (recommended)

- Use the launcher script:
  - `scripts/open_visual_diagrams_window.sh $CODEX_HOME/skill-workspaces/visual-diagrams <slug>`
- This starts the dev server (if needed) and opens a native WebView window.
- If you edit `assets/web-viewer/WebViewer.swift`, keep the window setup minimal and avoid `NSWindow.collectionBehavior` (it can crash before the window shows).

## Manual run (advanced)

- Start dev mode:
  - `cd $CODEX_HOME/skill-workspaces/visual-diagrams/<slug> && npm run dev -- --host 127.0.0.1 --port 5173`
- Open:
  - `http://127.0.0.1:5173`

## Agent guidance

- Prefer Excalidraw unless the user asks for a native-only solution.
- Use a JS bridge to create or update shapes and text.
- Save drawings as Excalidraw JSON in `$CODEX_HOME/skill-workspaces/visual-diagrams/<slug>/data`.
- Export to SVG or PNG for sharing or archiving.
- Create a fresh workspace per new request to avoid stale canvases.

## Alternatives

- PencilKit for native macOS drawing.
- Konva.js for a custom canvas UI.
