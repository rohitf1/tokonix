---
name: report-artifacts
description: Generate visual HTML reports (charts/tables) and open them in a native WebView window.
---

# Report Artifacts

Use this skill when the agent needs to present structured data in a report format (dashboards, tables, charts).

Paths below use `$CODEX_HOME` (defaults to `~/.codex`).

## Output rules (Tokonix)

- Keep spoken responses short, friendly, and natural.
- Do not speak commands, file paths, URLs, or code. Put exact details in Simple Notes and only summarize verbally.
- Use Simple Notes only when it helps (commands, configs, long text, structured data).

## Quality bar

- Present data clearly with readable typography and strong visual hierarchy.
- Open the report in the native viewer and confirm it is visible.
- Create a new workspace for new report requests to avoid stale output.

## Quick start

1) Run `scripts/setup_report_env.sh` and `scripts/setup_report_workspace.sh`.
2) Render HTML with `scripts/render_report.py`.
3) Open the report with `scripts/open_report_window.sh`.

## Scripts

- `scripts/setup_report_env.sh`: prepares the Python virtualenv.
- `scripts/setup_report_workspace.sh`: creates a report workspace.
- `scripts/render_report.py`: renders the report HTML.
- `scripts/render_report_static.py`: renders a static HTML report.
- `scripts/open_report_window.sh`: opens the report in a native WebView.

## References

- `references/report.md`: schema + render steps.
- `references/report-template-spec.md`: layout/colors/motion rules.

## Notes

- If you edit `assets/report-viewer/ReportViewer.swift`, keep the window setup minimal and avoid `NSWindow.collectionBehavior` (it can crash before the window shows).
