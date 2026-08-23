#!/usr/bin/env python3
"""Discover, search, and validate the repository's Agent Skills manifests.

The implementation is dependency-free so it can run in a fresh checkout.  It
supports the small relative-path pointer files used by a few vendored packs on
Windows, where Git symlinks are intentionally materialized as text files.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Sequence


NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FIELD_RE = re.compile(r"^([A-Za-z0-9_-]+):(?:[ \t]*(.*))?$")
TOKEN_RE = re.compile(r"[a-z0-9]+|[\u3400-\u9fff]+", re.IGNORECASE)
CJK_RE = re.compile(r"[\u3400-\u9fff]")
POINTER_RE = re.compile(r"^(?:\.\.?[/\\])+.*SKILL\.md$", re.IGNORECASE)
BLOCK_SCALAR_RE = re.compile(r"^([|>])(?:[+-]?[1-9]|[1-9][+-]?)?$")
QUERY_ALIASES = {
    "调试": {"debug", "debugging"},
    "排查": {"debug", "debugging", "diagnose", "troubleshooting"},
    "故障": {"failure", "troubleshooting"},
    "根因": {"root", "cause"},
    "根本原因": {"root", "cause"},
    "测试": {"test", "testing", "tests"},
    "失败": {"failure", "failing", "failed", "broken"},
    "报错": {"error", "debug"},
    "异常": {"unexpected", "error"},
    "文档": {"documentation", "docs", "readme"},
    "前端": {"frontend", "ui"},
    "界面": {"frontend", "ui", "design"},
    "智能体": {"agent"},
    "架构": {"architecture"},
    "研究": {"research"},
    "证据": {"evidence", "citation"},
    "论文": {"paper", "research"},
    "引用": {"citation", "evidence"},
}


@dataclass(frozen=True)
class Skill:
    path: str
    manifest_path: str
    collection: str
    name: str
    description: str
    compatibility: str
    replacement_characters: int
    line_count: int
    pointer: bool = False
    parse_error: str = ""


@dataclass(frozen=True)
class Issue:
    severity: str
    code: str
    path: str
    message: str


def _repo_root(value: str | Path | None = None) -> Path:
    return Path(value).resolve() if value else Path(__file__).resolve().parents[1]


def _repo_path(path: Path, root: Path) -> str:
    absolute = path.absolute()
    try:
        return absolute.relative_to(root.resolve()).as_posix()
    except ValueError:
        return absolute.as_posix()


def _decode_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("''", "'")
    if len(value) >= 2 and value[0] == value[-1] == '"':
        try:
            decoded = json.loads(value)
            return decoded if isinstance(decoded, str) else str(decoded)
        except json.JSONDecodeError:
            return value[1:-1]
    for index, character in enumerate(value):
        if character == "#" and (index == 0 or value[index - 1].isspace()):
            value = value[:index].rstrip()
            break
    if value.casefold() in {"null", "~"}:
        return ""
    return value


def _positive_int(value: str) -> int:
    parsed = int(value)
    if parsed < 1:
        raise argparse.ArgumentTypeError("value must be at least 1")
    return parsed


def _issue_limit(value: str) -> int:
    parsed = int(value)
    if parsed < -1:
        raise argparse.ArgumentTypeError("value must be -1 or greater")
    return parsed


def _parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    lines = text.lstrip("\ufeff").splitlines()
    if not lines or lines[0] != "---":
        return {}, "missing YAML frontmatter"

    try:
        end = next(i for i in range(1, len(lines)) if lines[i] == "---")
    except StopIteration:
        return {}, "unterminated YAML frontmatter"

    fields: dict[str, str] = {}
    frontmatter = lines[1:end]
    index = 0
    while index < len(frontmatter):
        line = frontmatter[index]
        match = FIELD_RE.match(line)
        if not match:
            index += 1
            continue
        key, raw_value = match.group(1), (match.group(2) or "").strip()
        block_scalar = BLOCK_SCALAR_RE.fullmatch(raw_value)
        if block_scalar:
            block: list[str] = []
            index += 1
            while index < len(frontmatter):
                candidate = frontmatter[index]
                if candidate and not candidate[0].isspace():
                    break
                block.append(candidate.strip())
                index += 1
            separator = "\n" if block_scalar.group(1) == "|" else " "
            fields[key] = separator.join(part for part in block if part).strip()
            continue
        fields[key] = _decode_scalar(raw_value)
        index += 1
    return fields, ""


def _resolve_manifest(source: Path, root: Path) -> tuple[Path, str]:
    try:
        source.resolve().relative_to(root.resolve())
    except ValueError:
        return source, "manifest path escapes repository root"
    except (OSError, RuntimeError) as exc:
        return source, f"cannot resolve manifest: {exc}"
    try:
        text = source.read_text(encoding="utf-8-sig", errors="replace")
    except OSError as exc:
        return source, f"cannot read manifest: {exc}"
    decoded = text.lstrip("\ufeff")
    pointer = decoded.strip()
    if decoded.startswith("---") or not POINTER_RE.fullmatch(pointer):
        return source, ""
    try:
        target = (source.parent / pointer.replace("\\", "/")).resolve()
    except (OSError, RuntimeError, ValueError) as exc:
        return source, f"cannot resolve pointer target: {exc}"
    try:
        target.relative_to(root.resolve())
    except ValueError:
        return source, "pointer target escapes repository root"
    if not target.is_file():
        return source, f"pointer target does not exist: {_repo_path(target, root)}"
    return target, ""


def read_skill(source: Path, root: Path) -> Skill:
    manifest, pointer_error = _resolve_manifest(source, root)
    pointer = source.is_symlink()
    if not pointer_error:
        try:
            pointer = pointer or manifest.resolve() != source.resolve()
        except (OSError, RuntimeError):
            pointer = True
    relative = _repo_path(source, root)
    parts = Path(relative).parts
    collection = parts[1] if len(parts) > 2 and parts[0] == "skills" else ""
    if pointer_error:
        return Skill(
            path=relative,
            manifest_path=relative,
            collection=collection,
            name="",
            description="",
            compatibility="",
            replacement_characters=0,
            line_count=0,
            pointer=pointer,
            parse_error=pointer_error,
        )
    try:
        raw = manifest.read_bytes()
    except OSError as exc:
        return Skill(
            path=relative,
            manifest_path=_repo_path(manifest, root),
            collection=collection,
            name="",
            description="",
            compatibility="",
            replacement_characters=0,
            line_count=0,
            pointer=pointer,
            parse_error=str(exc),
        )
    try:
        text = raw.decode("utf-8-sig")
        replacement_characters = 0
    except UnicodeDecodeError:
        text = raw.decode("utf-8-sig", errors="replace")
        replacement_characters = text.count("\ufffd")
    fields, parse_error = _parse_frontmatter(text)
    return Skill(
        path=relative,
        manifest_path=_repo_path(manifest, root),
        collection=collection,
        name=fields.get("name", "").strip(),
        description=fields.get("description", "").strip(),
        compatibility=fields.get("compatibility", "").strip(),
        replacement_characters=replacement_characters,
        line_count=len(text.splitlines()),
        pointer=pointer,
        parse_error=parse_error,
    )


def discover(root: Path) -> list[Skill]:
    root = root.resolve()
    skills_root = root / "skills"
    if not skills_root.is_dir():
        raise FileNotFoundError(f"missing skills directory: {skills_root}")
    return [read_skill(path, root) for path in sorted(skills_root.rglob("SKILL.md"))]


def validate(skills: Sequence[Skill]) -> list[Issue]:
    issues: list[Issue] = []
    by_name: dict[str, list[Skill]] = defaultdict(list)
    for skill in skills:
        if skill.replacement_characters:
            issues.append(
                Issue(
                    "warning",
                    "encoding",
                    skill.path,
                    f"manifest contains {skill.replacement_characters} invalid UTF-8 replacement character(s)",
                )
            )
        if skill.parse_error:
            issues.append(Issue("error", "frontmatter", skill.path, skill.parse_error))
            continue
        if not skill.name:
            issues.append(
                Issue("error", "name-missing", skill.path, "required name is empty")
            )
        else:
            by_name[skill.name.casefold()].append(skill)
            if len(skill.name) > 64:
                issues.append(
                    Issue(
                        "warning",
                        "name-length",
                        skill.path,
                        "name exceeds 64 characters",
                    )
                )
            if not NAME_RE.fullmatch(skill.name):
                issues.append(
                    Issue(
                        "warning",
                        "name-format",
                        skill.path,
                        "name is not lowercase kebab-case",
                    )
                )
            folder = Path(skill.path).parent.name
            if skill.name != folder:
                issues.append(
                    Issue(
                        "warning",
                        "name-folder",
                        skill.path,
                        f"name '{skill.name}' does not match folder '{folder}'",
                    )
                )
        if not skill.description:
            issues.append(
                Issue(
                    "error",
                    "description-missing",
                    skill.path,
                    "required description is empty",
                )
            )
        elif len(skill.description) > 1024:
            issues.append(
                Issue(
                    "warning",
                    "description-length",
                    skill.path,
                    "description exceeds 1024 characters",
                )
            )
        if len(skill.compatibility) > 500:
            issues.append(
                Issue(
                    "warning",
                    "compatibility-length",
                    skill.path,
                    "compatibility exceeds 500 characters",
                )
            )
        if skill.line_count > 500:
            issues.append(
                Issue(
                    "warning",
                    "progressive-disclosure",
                    skill.path,
                    f"manifest has {skill.line_count} lines (recommended maximum: 500)",
                )
            )

    for name, duplicates in by_name.items():
        if len(duplicates) < 2:
            continue
        paths = ", ".join(item.path for item in duplicates)
        for item in duplicates:
            issues.append(
                Issue(
                    "warning",
                    "duplicate-name",
                    item.path,
                    f"name '{name}' is also used by: {paths}",
                )
            )
    return sorted(
        issues, key=lambda item: (item.severity != "error", item.path, item.code)
    )


def _tokens(text: str) -> set[str]:
    normalized = text.casefold().replace("_", "-")
    tokens: set[str] = set()
    for token in TOKEN_RE.findall(normalized):
        tokens.add(token)
        if CJK_RE.search(token):
            characters = [
                character for character in token if CJK_RE.fullmatch(character)
            ]
            tokens.update(
                "".join(characters[index : index + 2])
                for index in range(len(characters) - 1)
            )
    return tokens


def _query_tokens(text: str) -> set[str]:
    return _tokens(text.casefold())


def _query_alias_groups(text: str) -> list[set[str]]:
    normalized = text.casefold()
    groups: list[set[str]] = []
    for phrase, aliases in QUERY_ALIASES.items():
        if phrase in normalized:
            groups.append(aliases)
    return groups


def _match_count(
    field_tokens: set[str],
    query_tokens: set[str],
    alias_groups: Sequence[set[str]],
    *,
    count_alias_terms: bool = False,
) -> int:
    alias_matches = (
        sum(len(group & field_tokens) for group in alias_groups)
        if count_alias_terms
        else sum(bool(group & field_tokens) for group in alias_groups)
    )
    return len(query_tokens & field_tokens) + alias_matches


def search(
    skills: Sequence[Skill], query: str, limit: int = 10, collection: str = ""
) -> list[tuple[int, Skill]]:
    query_normalized = " ".join(query.casefold().split())
    if not query_normalized:
        return []
    query_tokens = _query_tokens(query_normalized)
    alias_groups = _query_alias_groups(query_normalized)
    results: list[tuple[int, Skill]] = []
    for skill in skills:
        if (
            skill.parse_error
            or not skill.name
            or (collection and skill.collection != collection)
        ):
            continue
        name = skill.name.casefold().replace("_", "-")
        description = skill.description.casefold()
        path = skill.path.casefold().replace("_", "-")
        name_tokens = _tokens(name)
        description_tokens = _tokens(description)
        path_tokens = _tokens(path)
        score = 0
        if query_normalized in name:
            score += 40
        if query_normalized in description:
            score += 18
        if query_normalized in path:
            score += 10
        score += 10 * _match_count(
            name_tokens, query_tokens, alias_groups, count_alias_terms=True
        )
        score += 5 * _match_count(description_tokens, query_tokens, alias_groups)
        score += 3 * _match_count(path_tokens, query_tokens, alias_groups)
        if score:
            results.append((score, skill))
    results.sort(key=lambda item: (-item[0], item[1].name.casefold(), item[1].path))
    return results[: max(0, limit)]


def _changed_skill_paths(root: Path, ref: str) -> set[str]:
    commands = [
        [
            "diff",
            "--name-only",
            "-z",
            "--diff-filter=ACMR",
            f"{ref}...HEAD",
        ],
        ["diff", "--name-only", "-z", "--diff-filter=ACMR", "HEAD"],
        [
            "diff",
            "--cached",
            "--name-only",
            "-z",
            "--diff-filter=ACMR",
        ],
        ["ls-files", "--others", "--exclude-standard", "-z"],
    ]
    paths: set[str] = set()
    for arguments in commands:
        command = [
            "git",
            "-C",
            str(root),
            "-c",
            "core.quotePath=false",
            *arguments,
        ]
        result = subprocess.run(command, check=False, capture_output=True)
        if result.returncode:
            stderr = result.stderr.decode("utf-8", errors="replace").strip()
            raise RuntimeError(stderr or f"failed: {' '.join(command)}")
        paths.update(
            path
            for path in result.stdout.decode("utf-8", errors="surrogateescape").split(
                "\0"
            )
            if path
        )
    return {path for path in paths if path.endswith("/SKILL.md") or path == "SKILL.md"}


def _print_search(results: Sequence[tuple[int, Skill]], as_json: bool) -> None:
    if as_json:
        print(
            json.dumps(
                [{"score": score, **asdict(skill)} for score, skill in results],
                ensure_ascii=False,
                indent=2,
            )
        )
        return
    for score, skill in results:
        summary = " ".join(skill.description.split())
        if len(summary) > 120:
            summary = summary[:117] + "..."
        print(f"{score:>3}  {skill.name:<36} {skill.path}")
        print(f"     {summary}")


def _print_issues(issues: Sequence[Issue], as_json: bool, max_issues: int) -> None:
    if as_json:
        counts = Counter(item.severity for item in issues)
        print(
            json.dumps(
                {"summary": dict(counts), "issues": [asdict(item) for item in issues]},
                ensure_ascii=False,
                indent=2,
            )
        )
        return
    visible = issues if max_issues < 0 else issues[:max_issues]
    for item in visible:
        print(f"{item.severity.upper():7} {item.code:<24} {item.path}: {item.message}")
    if len(visible) < len(issues):
        print(
            f"... {len(issues) - len(visible)} additional issue(s) omitted; use --max-issues -1 or --json for all details."
        )
    counts = Counter(item.severity for item in issues)
    print(
        f"Validated with {counts['error']} error(s) and {counts['warning']} warning(s)."
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", help="repository root (defaults to the parent of tools/)"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    search_parser = subparsers.add_parser(
        "search", help="rank skills for a natural-language intent"
    )
    search_parser.add_argument("query", nargs="+", help="intent to search for")
    search_parser.add_argument("--limit", type=_positive_int, default=10)
    search_parser.add_argument("--collection", default="")
    search_parser.add_argument("--json", action="store_true")

    catalog_parser = subparsers.add_parser(
        "catalog", help="emit the discovered skill catalog"
    )
    catalog_parser.add_argument("--collection", default="")
    catalog_parser.add_argument("--json", action="store_true")

    validate_parser = subparsers.add_parser(
        "validate", help="validate Agent Skills metadata"
    )
    validate_parser.add_argument(
        "--strict", action="store_true", help="treat compatibility warnings as failures"
    )
    validate_parser.add_argument(
        "--changed-from",
        help="strictly validate only SKILL.md files changed from this Git ref",
    )
    validate_parser.add_argument(
        "--max-issues",
        type=_issue_limit,
        default=50,
        help="maximum text issues to print; -1 prints all",
    )
    validate_parser.add_argument("--json", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    root = _repo_root(args.root)
    try:
        skills = discover(root)
    except (FileNotFoundError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.command == "search":
        _print_search(
            search(skills, " ".join(args.query), args.limit, args.collection), args.json
        )
        return 0
    if args.command == "catalog":
        selected = [
            item
            for item in skills
            if not args.collection or item.collection == args.collection
        ]
        if args.json:
            print(
                json.dumps(
                    [asdict(item) for item in selected], ensure_ascii=False, indent=2
                )
            )
        else:
            counts = Counter(item.collection for item in selected)
            print(f"Discovered {len(selected)} skill manifest(s).")
            for collection, count in sorted(
                counts.items(), key=lambda item: (-item[1], item[0])
            ):
                print(f"{count:>5}  {collection or '(root)'}")
        return 0

    issues = validate(skills)
    if args.changed_from:
        try:
            changed = _changed_skill_paths(root, args.changed_from)
        except RuntimeError as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 2
        issues = [item for item in issues if item.path in changed]
        args.strict = True
    _print_issues(issues, args.json, args.max_issues)
    errors = sum(item.severity == "error" for item in issues)
    warnings = sum(item.severity == "warning" for item in issues)
    return 1 if errors or (args.strict and warnings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
