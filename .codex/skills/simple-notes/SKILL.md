---
name: simple-notes
description: Display concise notes in a lightweight native window so users can read, edit, and copy text easily.
---

# Simple Notes

Use this skill when the agent needs to show text that is easier to read or copy than spoken output.

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Stack

- Native AppKit window with an editable `NSTextView` (no web or Electron runtime).
- Lightweight script launcher that builds and opens the notes viewer.

## Setup (one-time)

- Requires macOS and Xcode Command Line Tools (for `swiftc`).
- Create a workspace:
  - `scripts/setup_simple_notes_workspace.sh $CODEX_HOME/skill-workspaces/simple-notes <slug>`

## Open the notes window

- `scripts/open_simple_notes_window.sh $CODEX_HOME/skill-workspaces/simple-notes <slug>`
- The viewer auto-loads (or creates) `notes.txt` inside the workspace and lets the user edit/copy text.
- Edits are saved back to `notes.txt` on close.
- Keep the window open and visible while referencing its content.

## Styling

- Notes are parsed with a minimal heading style (`#` and `##`) to add size and color accents.
- Keep the viewer window setup minimal and avoid `NSWindow.collectionBehavior` (it can crash before the window shows).

## Files

- Template: `assets/simple-notes-template/notes.txt`
- Viewer: `assets/notes-viewer/NotesViewer.swift`
- Scripts: `scripts/setup_simple_notes_workspace.sh`, `scripts/open_simple_notes_window.sh`
