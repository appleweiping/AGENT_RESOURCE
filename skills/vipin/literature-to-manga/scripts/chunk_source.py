#!/usr/bin/env python3
"""Split extracted source text into adaptation-sized chunks."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def read_text(path: Path) -> str:
    for encoding in ("utf-8-sig", "utf-8", "gb18030", "big5", "cp1252", "latin-1"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    return path.read_text(encoding="utf-8", errors="replace")


def paragraph_units(text: str) -> list[str]:
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    chunks = [part.strip() for part in re.split(r"\n\s*\n+", normalized) if part.strip()]
    if len(chunks) <= 1:
        chunks = [part.strip() for part in normalized.split("\n") if part.strip()]
    return chunks


def split_unit(unit: str, chunk_chars: int) -> list[str]:
    if len(unit) <= chunk_chars:
        return [unit]
    pieces: list[str] = []
    start = 0
    while start < len(unit):
        end = min(start + chunk_chars, len(unit))
        if end < len(unit):
            window = unit[start:end]
            break_at = max(window.rfind("。"), window.rfind("."), window.rfind("!"), window.rfind("?"))
            if break_at > chunk_chars * 0.5:
                end = start + break_at + 1
        pieces.append(unit[start:end].strip())
        start = end
    return [piece for piece in pieces if piece]


def chunk_text(text: str, chunk_chars: int, overlap_chars: int) -> list[str]:
    units = []
    for unit in paragraph_units(text):
        units.extend(split_unit(unit, chunk_chars))
    chunks: list[str] = []
    current: list[str] = []
    current_len = 0

    for unit in units:
        unit_len = len(unit)
        separator_len = 2 if current else 0
        if current and current_len + separator_len + unit_len > chunk_chars:
            chunk = "\n\n".join(current).strip()
            chunks.append(chunk)
            if overlap_chars > 0:
                overlap = chunk[-overlap_chars:]
                current = [overlap, unit]
                current_len = len(overlap) + 2 + unit_len
            else:
                current = [unit]
                current_len = unit_len
        else:
            current.append(unit)
            current_len += separator_len + unit_len

    if current:
        chunks.append("\n\n".join(current).strip())
    return chunks


def write_jsonl(chunks: list[str], source: Path, output_dir: Path | None) -> None:
    rows = []
    for index, text in enumerate(chunks, 1):
        rows.append(
            {
                "chunk_id": f"{source.stem}-{index:04d}",
                "source": str(source),
                "index": index,
                "char_count": len(text),
                "text": text,
            }
        )
    if output_dir:
        output_dir.mkdir(parents=True, exist_ok=True)
        output = output_dir / f"{source.stem}.chunks.jsonl"
        with output.open("w", encoding="utf-8", newline="\n") as handle:
            for row in rows:
                handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    else:
        for row in rows:
            print(json.dumps(row, ensure_ascii=False))


def write_markdown(chunks: list[str], source: Path, output_dir: Path | None) -> None:
    if output_dir:
        output_dir.mkdir(parents=True, exist_ok=True)
        for index, text in enumerate(chunks, 1):
            output = output_dir / f"{source.stem}.chunk-{index:04d}.md"
            output.write_text(f"# Chunk {index:04d}\n\n{text}\n", encoding="utf-8")
    else:
        for index, text in enumerate(chunks, 1):
            print(f"# Chunk {index:04d}")
            print()
            print(text)
            print()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="Plain text source file.")
    parser.add_argument("--output-dir", help="Directory for chunk files. Defaults to stdout.")
    parser.add_argument("--chunk-chars", type=int, default=6000)
    parser.add_argument("--overlap-chars", type=int, default=300)
    parser.add_argument("--format", choices=("jsonl", "markdown"), default="jsonl")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = Path(args.source).expanduser().resolve()
    if not source.exists():
        print(f"error: source does not exist: {source}", file=sys.stderr)
        return 2
    if args.chunk_chars <= 0:
        print("error: --chunk-chars must be positive", file=sys.stderr)
        return 2
    if args.overlap_chars < 0 or args.overlap_chars >= args.chunk_chars:
        print("error: --overlap-chars must be >= 0 and smaller than --chunk-chars", file=sys.stderr)
        return 2

    text = read_text(source)
    chunks = chunk_text(text, args.chunk_chars, args.overlap_chars)
    output_dir = Path(args.output_dir).expanduser().resolve() if args.output_dir else None
    if args.format == "jsonl":
        write_jsonl(chunks, source, output_dir)
    else:
        write_markdown(chunks, source, output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
