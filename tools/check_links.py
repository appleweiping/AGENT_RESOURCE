#!/usr/bin/env python3
"""Fail if a relative Markdown link in a tracked .md file points at a missing path.

Usage: python tools/check_links.py [--root PATH]

Only relative links are checked (http, mailto and in-page #anchors are skipped);
"file.md#section" is checked as "file.md". Code blocks are ignored.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

LINK_RE = re.compile(r"!?\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#", "data:")


def tracked_markdown(root: Path) -> list[Path]:
    out = subprocess.run(
        ["git", "-C", str(root), "-c", "core.quotePath=false", "ls-files", "-z", "*.md"],
        check=True,
        capture_output=True,
    ).stdout.decode("utf-8")
    return [root / p for p in out.split("\0") if p]


def broken_links(path: Path, root: Path) -> list[str]:
    problems = []
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        line = re.sub(r"`[^`]*`", "", line)  # inline code is not a link
        for target in LINK_RE.findall(line):
            if target.startswith(SKIP_PREFIXES):
                continue
            relative = unquote(target.split("#", 1)[0])
            if not relative:
                continue
            resolved = (path.parent / relative).resolve()
            if not resolved.exists():
                problems.append(f"{path.relative_to(root)}:{number}: {target}")
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", default=Path(__file__).resolve().parents[1], type=Path)
    args = parser.parse_args(argv)
    root = args.root.resolve()
    files = tracked_markdown(root)
    problems = [p for f in files for p in broken_links(f, root)]
    for problem in problems:
        print(problem)
    print(f"Checked {len(files)} Markdown files: {len(problems)} broken relative link(s).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
