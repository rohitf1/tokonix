#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path
from typing import Any, Dict
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


def render_report(data: Dict[str, Any], template_dir: Path, output_path: Path) -> None:
    env = Environment(loader=FileSystemLoader(template_dir), autoescape=True)
    template = env.get_template("report.html")

    report_json = json.dumps(data, ensure_ascii=True, indent=2)
    html = template.render(
        title=data.get("title"),
        subtitle=data.get("subtitle"),
        summary=data.get("summary"),
        report_json=report_json,
    )

    output_path.write_text(html, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render an AI report HTML file.")
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
