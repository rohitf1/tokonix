# Report template spec (fast path)

Use this spec to generate reports quickly without redesigning. Do not change layout, spacing, or animation unless explicitly requested.

## Layout

- Page width: `980px` max, centered, `40px` top padding, `28px` horizontal padding.
- Sections order: Header -> Summary (metrics) -> Charts -> Tables -> Notes.
- Two columns where possible using responsive grids; single column on narrow windows.

## Typography

- Font: `"Space Grotesk", "Segoe UI", sans-serif`.
- Title size: `36px`, subtitle `15px`, metric values `22px`.
- Body copy: `16px`, tables `14px`.

## Color system

- Background: `#05060b` with three radial gradients.
- Panel: `rgba(12, 16, 28, 0.75)`.
- Panel soft: `rgba(20, 24, 40, 0.55)`.
- Accent: `#4cc3ff`, accent-2 `#b44bff`, accent-3 `#ff4fd8`.
- Text: `#e6f3ff`, muted: `rgba(230, 243, 255, 0.65)`.
- Borders: `rgba(76, 195, 255, 0.25)`.

## Motion

- Ambient background drift: `18s` infinite (subtle).
- Summary halo spin: `16s` infinite (subtle).
- No other animation.

## Charts

- Use Chart.js in interactive mode.
- Chart types: `line` and `bar` only.
- Legends visible, colored in `#e6f3ff`.
- Grid lines alpha `0.05`.

## Tables

- Use up to two tables in the `tables` array.
- Titles: `16px`, rows `14px`.
- Keep row counts reasonable (max ~15 rows per table).

## Data requirements

Minimum data (fast path):
- `title`, `subtitle`, `summary`, `metrics` (3-4 items), `charts` (2-3), `tables` (1-2), `notes` (2-4).

Avoid:
- Large tables with >20 rows.
- New chart types.
- Extra sections.

## Static (Quick Look)

- Use `render_report_static.py` to bake charts into PNG.
- Layout and styling must match the interactive report.
