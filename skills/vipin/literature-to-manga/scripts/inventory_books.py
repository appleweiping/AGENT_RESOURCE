#!/usr/bin/env python3
"""Inventory book-like files for manga adaptation triage."""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote


DEFAULT_EXTENSIONS = (".txt", ".pdf", ".mobi", ".zip")
SKIP_DIRS = {".git", "__pycache__", ".hg", ".svn", "node_modules"}


def normalize_title(path: Path) -> str:
    title = unquote(path.stem)
    title = re.sub(r"(?i)epubw\.com\s*[- ]*", "", title)
    title = re.sub(r"[_\-]+", " ", title)
    title = re.sub(r"\s+", " ", title).strip()
    title = re.sub(r"(?i)\b(txt|pdf|mobi|epubw|bookbao|shupengw|www|com)\b", "", title)
    title = re.sub(r"\s+", " ", title).strip(" -_[]().")
    return title or path.stem


def iter_files(root: Path, extensions: set[str]):
    for current_root, dir_names, file_names in os.walk(root):
        dir_names[:] = [name for name in dir_names if name not in SKIP_DIRS]
        base = Path(current_root)
        for file_name in file_names:
            path = base / file_name
            if path.suffix.lower() in extensions:
                yield path


def build_record(root: Path, path: Path) -> dict:
    stat = path.stat()
    suffix = path.suffix.lower().lstrip(".") or "unknown"
    return {
        "title": normalize_title(path),
        "relative_path": str(path.relative_to(root)),
        "format": suffix,
        "size_bytes": stat.st_size,
        "size_mb": round(stat.st_size / (1024 * 1024), 3),
        "modified_utc": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat(),
    }


def emit_json(records: list[dict]) -> None:
    json.dump(records, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


def emit_csv(records: list[dict]) -> None:
    fieldnames = ["title", "relative_path", "format", "size_bytes", "size_mb", "modified_utc"]
    writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(records)


def emit_markdown(records: list[dict], root: Path) -> None:
    print(f"# Book Inventory")
    print()
    print(f"- Root: `{root}`")
    print(f"- Count: {len(records)}")
    print()
    print("| # | Title | Format | Size MB | Relative path |")
    print("| ---: | --- | --- | ---: | --- |")
    for index, record in enumerate(records, 1):
        title = record["title"].replace("|", "\\|")
        rel = record["relative_path"].replace("|", "\\|")
        print(f"| {index} | {title} | {record['format']} | {record['size_mb']} | `{rel}` |")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        default=r"D:\Company\anime\literature-books",
        help="Archive root to scan.",
    )
    parser.add_argument(
        "--extensions",
        default=",".join(DEFAULT_EXTENSIONS),
        help="Comma-separated extensions to include.",
    )
    parser.add_argument("--format", choices=("json", "csv", "markdown"), default="json")
    parser.add_argument("--limit", type=int, default=0, help="Maximum records to print. 0 means no limit.")
    parser.add_argument(
        "--sort",
        choices=("path", "title", "size"),
        default="path",
        help="Sort field.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).expanduser().resolve()
    if not root.exists():
        print(f"error: root does not exist: {root}", file=sys.stderr)
        return 2
    if not root.is_dir():
        print(f"error: root is not a directory: {root}", file=sys.stderr)
        return 2

    extensions = {
        ext.strip().lower() if ext.strip().startswith(".") else f".{ext.strip().lower()}"
        for ext in args.extensions.split(",")
        if ext.strip()
    }
    records = [build_record(root, path) for path in iter_files(root, extensions)]
    if args.sort == "title":
        records.sort(key=lambda item: (item["title"].casefold(), item["relative_path"].casefold()))
    elif args.sort == "size":
        records.sort(key=lambda item: (-item["size_bytes"], item["relative_path"].casefold()))
    else:
        records.sort(key=lambda item: item["relative_path"].casefold())

    if args.limit > 0:
        records = records[: args.limit]

    if args.format == "json":
        emit_json(records)
    elif args.format == "csv":
        emit_csv(records)
    else:
        emit_markdown(records, root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
