#!/usr/bin/env python3
import argparse
import base64
import csv
import io
import json
from pathlib import Path
from typing import Any, Dict, List

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import requests
from jinja2 import Environment, FileSystemLoader


def load_json(source: str) -> Dict[str, Any]:
    if source.startswith("http://") or source.startswith("https://"):
        response = requests.get(source, timeout=30)
        response.raise_for_status()
        return response.json()

    with open(source, "r", encoding="utf-8") as handle:
        return json.load(handle)


def load_csv(source: str) -> Dict[str, Any]:
    if source.startswith("http://") or source.startswith("https://"):
        response = requests.get(source, timeout=30)
        response.raise_for_status()
        lines = response.text.splitlines()
        reader = csv.reader(lines)
    else:
        handle = open(source, "r", encoding="utf-8", newline="")
        reader = csv.reader(handle)

    rows = list(reader)
    if not rows:
        return {"title": "AI Report", "table": {"columns": [], "rows": []}}

    columns = rows[0]
    table_rows = rows[1:]

    return {
        "title": "AI Report",
        "summary": "Generated from CSV source.",
        "table": {
            "title": "Source data",
            "columns": columns,
            "rows": table_rows,
        },
    }


def resolve_data(source: str) -> Dict[str, Any]:
    if source.lower().endswith(".csv"):
        return load_csv(source)
    return load_json(source)


def chart_image(chart: Dict[str, Any]) -> str:
    labels = chart.get("labels", [])
    series = chart.get("series", [])
    chart_type = chart.get("type", "line")

    fig, ax = plt.subplots(figsize=(4.6, 2.8), dpi=160)
    fig.patch.set_alpha(0.0)
    ax.set_facecolor("#0c101c")
    ax.tick_params(colors="#9bb0c9")

    palette = ["#4cc3ff", "#b44bff", "#ff4fd8", "#2ee6c7", "#6aa9ff"]

    if chart_type == "bar":
        width = 0.75 / max(len(series), 1)
        x_positions = list(range(len(labels)))
        for idx, series_item in enumerate(series):
            offset = (idx - (len(series) - 1) / 2) * width
            data = series_item.get("data", [])
            ax.bar(
                [x + offset for x in x_positions],
                data,
                width=width,
                color=palette[idx % len(palette)],
                alpha=0.85,
                label=series_item.get("label", ""),
            )
        ax.set_xticks(x_positions)
        ax.set_xticklabels(labels)
    else:
        for idx, series_item in enumerate(series):
            data = series_item.get("data", [])
            ax.plot(
                labels,
                data,
                color=palette[idx % len(palette)],
                linewidth=2,
                label=series_item.get("label", ""),
            )

    ax.grid(color="white", alpha=0.08, linewidth=0.8)
    if any(item.get("label") for item in series):
        ax.legend(frameon=False, labelcolor="#e6f3ff", fontsize=7)

    buf = io.BytesIO()
    fig.tight_layout()
    fig.savefig(buf, format="png", transparent=True)
    plt.close(fig)

    return base64.b64encode(buf.getvalue()).decode("ascii")


def render_report(data: Dict[str, Any], template_dir: Path, output_path: Path) -> None:
    env = Environment(loader=FileSystemLoader(template_dir), autoescape=True)
    template = env.get_template("report-static.html")

    charts = data.get("charts", [])
    rendered_charts: List[Dict[str, Any]] = []
    for chart in charts:
        chart_copy = dict(chart)
        chart_copy["image"] = chart_image(chart_copy)
        rendered_charts.append(chart_copy)

    tables = data.get("tables")
    if tables is None and data.get("table"):
        tables = [data.get("table")]

    html = template.render(
        title=data.get("title"),
        subtitle=data.get("subtitle"),
        summary=data.get("summary"),
        metrics=data.get("metrics", []),
        charts=rendered_charts,
        table=data.get("table"),
        tables=tables,
        notes=data.get("notes", []),
        notes_title=data.get("notesTitle"),
    )

    output_path.write_text(html, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a static HTML report for Quick Look.")
    parser.add_argument("--data", required=True, help="Path or URL to JSON/CSV data.")
    parser.add_argument(
        "--template-dir",
        default=None,
        help="Path to report-template directory (defaults to skill assets).",
    )
    parser.add_argument("--out", required=True, help="Output HTML file path.")
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    default_template_dir = script_dir.parent / "assets" / "report-template"
    template_dir = Path(args.template_dir) if args.template_dir else default_template_dir

    data = resolve_data(args.data)
    render_report(data, template_dir, Path(args.out))


if __name__ == "__main__":
    main()
