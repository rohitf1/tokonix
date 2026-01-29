# App artifacts (Electron + Vite + React)

## Quick start

1) Create a per-app workspace and install deps:
   `$CODEX_HOME/skills/app-artifacts/scripts/setup_apps_workspace.sh $CODEX_HOME/skill-workspaces/artifacts/apps <app_slug>`

2) Run the app:
   `cd $CODEX_HOME/skill-workspaces/artifacts/apps/<app_slug> && npm run dev`

## Default workspace path

- App root: `$CODEX_HOME/skill-workspaces/artifacts/apps`
- Each app lives in its own folder under the root (for example: `$CODEX_HOME/skill-workspaces/artifacts/apps/ops-dashboard`).

## Template structure

- `main.js`: Electron main process and window options
- `preload.js`: safe bridge for minimal app APIs
- `index.html`: Vite entrypoint
- `src/main.jsx`: React bootstrapping
- `src/App.jsx`: main UI layout
- `src/app.css`: base theme tokens + layout

## Recommended libraries (optional)

- UI primitives: Radix UI
- Icons: Lucide
- State: Zustand (already included)
- Data table: TanStack Table
- Charts: ECharts or Chart.js
- Local storage: better-sqlite3 or Dexie (if you need IndexedDB)

Keep the template lightweight; add only what the app needs.
