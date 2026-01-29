# Report artifacts

## Quick start

1) Create the report workspace (copies the template):
   `$CODEX_HOME/skills/report-artifacts/scripts/setup_report_workspace.sh`

2) Create the report venv:
   `$CODEX_HOME/skills/report-artifacts/scripts/setup_report_env.sh`

3) Render a report from JSON (or CSV):
   `cd $CODEX_HOME/skill-workspaces/artifacts/report`
   `$CODEX_HOME/skills/report-artifacts/scripts/render_report.py --data sample-data.json --out report.html`

Open the generated HTML in a browser or a native WebView window.

## Fast-path template rules

Use the fixed layout and styling guidelines in `references/report-template-spec.md` to keep report generation fast and consistent.

## Native window (no browser)

Use the bundled viewer to open the interactive report in a native window:

`$CODEX_HOME/skills/report-artifacts/scripts/open_report_window.sh report.html "System Report"`

## Quick Look (static rendering)

Quick Look does not run JavaScript, so use the static renderer:

`$CODEX_HOME/skills/report-artifacts/scripts/render_report_static.py --data sample-data.json --out report-static.html`

Then open it with:

`qlmanage -p report-static.html`

## Default workspace paths

- Report workspace: `$CODEX_HOME/skill-workspaces/artifacts/report`
- Report venv: `$CODEX_HOME/skill-venvs/artifacts-report`

## Data schema (JSON)

```json
{
  "title": "Report title",
  "subtitle": "Optional subtitle",
  "summary": "Short executive summary",
  "metrics": [
    { "label": "Label", "value": "Value", "delta": "+3%" }
  ],
  "charts": [
    {
      "title": "Chart title",
      "type": "line",
      "labels": ["A", "B"],
      "series": [
        { "label": "Series", "data": [1, 2] }
      ]
    }
  ],
  "table": {
    "title": "Table title",
    "columns": ["Col A", "Col B"],
    "rows": [["a", "b"]]
  },
  "notes": ["Callout 1", "Callout 2"],
  "copyText": "Optional override for copy button"
}
```

## Template structure

- `report.html`: skeleton layout with action buttons
- `report.css`: styling, gradients, typography, layout
- `report.js`: renders metrics, charts, tables, notes

## UI integration

- Center the report window on screen.
- Allow native window controls (minimize/maximize/close).
- Use a WebView or browser window to render the report HTML.
