#!/usr/bin/env python3
"""Extract readable text from txt, md, pdf, and zip files when supported."""

from __future__ import annotations

import argparse
import io
import sys
import zipfile
from pathlib import Path


TEXT_ENCODINGS = ("utf-8-sig", "utf-8", "gb18030", "big5", "cp1252", "latin-1")
TEXT_SUFFIXES = {".txt", ".md", ".markdown", ".csv", ".json", ".srt"}


def read_bytes_as_text(data: bytes, encoding: str | None = None) -> tuple[str, str]:
    encodings = (encoding,) if encoding else TEXT_ENCODINGS
    last_error: Exception | None = None
    for candidate in encodings:
        if not candidate:
            continue
        try:
            return data.decode(candidate), candidate
        except UnicodeDecodeError as exc:
            last_error = exc
    if last_error:
        raise last_error
    raise UnicodeDecodeError("unknown", b"", 0, 1, "no encoding candidates")


def extract_text_file(path: Path, encoding: str | None) -> tuple[str, str]:
    text, used_encoding = read_bytes_as_text(path.read_bytes(), encoding)
    return text, f"text:{used_encoding}"


def extract_pdf(path: Path) -> tuple[str, str]:
    try:
        from pypdf import PdfReader  # type: ignore

        parser = "pypdf"
    except ImportError:
        try:
            from PyPDF2 import PdfReader  # type: ignore

            parser = "PyPDF2"
        except ImportError as exc:
            raise RuntimeError("PDF extraction requires optional package pypdf or PyPDF2") from exc

    reader = PdfReader(str(path))
    pages: list[str] = []
    for index, page in enumerate(reader.pages, 1):
        text = page.extract_text() or ""
        pages.append(f"\n\n[Page {index}]\n{text.strip()}")
    return "\n".join(pages).strip(), f"pdf:{parser}"


def extract_zip(path: Path, encoding: str | None) -> tuple[str, str]:
    parts: list[str] = []
    with zipfile.ZipFile(path) as archive:
        for info in archive.infolist():
            member_path = Path(info.filename)
            if info.is_dir() or member_path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            data = archive.read(info)
            try:
                text, used_encoding = read_bytes_as_text(data, encoding)
            except UnicodeDecodeError:
                continue
            parts.append(f"\n\n===== ZIP MEMBER: {info.filename} ({used_encoding}) =====\n{text.strip()}")
    if not parts:
        raise RuntimeError("No readable text-like members found in zip archive")
    return "\n".join(parts).strip(), "zip:text-members"


def extract(path: Path, encoding: str | None) -> tuple[str, str]:
    suffix = path.suffix.lower()
    if suffix in TEXT_SUFFIXES:
        return extract_text_file(path, encoding)
    if suffix == ".pdf":
        return extract_pdf(path)
    if suffix == ".zip":
        return extract_zip(path, encoding)
    if suffix == ".mobi":
        raise RuntimeError("MOBI extraction is not supported by this script; use a local ebook converter first")
    if suffix == ".rar":
        raise RuntimeError("RAR extraction is not supported by this script; extract the archive first")
    raise RuntimeError(f"Unsupported file type: {suffix or '(none)'}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", help="Source file to extract.")
    parser.add_argument("--output", help="Write extracted text to this path. Defaults to stdout.")
    parser.add_argument("--encoding", help="Force a text encoding for txt/zip members.")
    parser.add_argument("--max-chars", type=int, default=0, help="Limit output characters. 0 means no limit.")
    parser.add_argument("--metadata", action="store_true", help="Prefix output with extraction metadata.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    path = Path(args.source).expanduser().resolve()
    if not path.exists():
        print(f"error: source does not exist: {path}", file=sys.stderr)
        return 2
    if not path.is_file():
        print(f"error: source is not a file: {path}", file=sys.stderr)
        return 2

    try:
        text, method = extract(path, args.encoding)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.max_chars > 0:
        text = text[: args.max_chars]

    if args.metadata:
        header = (
            f"Source: {path}\n"
            f"Method: {method}\n"
            f"Size bytes: {path.stat().st_size}\n"
            f"Characters: {len(text)}\n"
            "\n"
        )
        text = header + text

    if args.output:
        output = Path(args.output).expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding="utf-8")
    else:
        stream = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace", newline="")
        stream.write(text)
        if not text.endswith("\n"):
            stream.write("\n")
        stream.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
