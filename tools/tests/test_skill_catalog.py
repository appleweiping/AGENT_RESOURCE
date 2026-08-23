from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path

from tools.skill_catalog import _changed_skill_paths, discover, main, search, validate


class SkillCatalogTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "skills" / "curated" / "systematic-debugging").mkdir(parents=True)
        (
            self.root / "skills" / "curated" / "systematic-debugging" / "SKILL.md"
        ).write_text(
            "---\n"
            "name: systematic-debugging\n"
            "description: >\n"
            "  Diagnose root causes before fixing failing tests, crashes,\n"
            "  regressions, or unexpected behavior. 用于排查异常行为的根因。\n"
            "---\n\n# Systematic Debugging\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _init_repository(self) -> None:
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(
            [
                "git",
                "-C",
                str(self.root),
                "config",
                "user.email",
                "tests@example.invalid",
            ],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(self.root), "config", "user.name", "Skill Catalog Tests"],
            check=True,
        )

    def _commit_all(self, message: str) -> str:
        subprocess.run(["git", "-C", str(self.root), "add", "--all"], check=True)
        subprocess.run(
            ["git", "-C", str(self.root), "commit", "-q", "-m", message], check=True
        )
        return subprocess.run(
            ["git", "-C", str(self.root), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

    def _write_skill(self, folder: str, *, name: str | None = None) -> Path:
        destination = self.root / "skills" / "curated" / folder / "SKILL.md"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(
            f"---\nname: {name or folder}\ndescription: useful test skill\n---\n",
            encoding="utf-8",
        )
        return destination

    def test_discovers_folded_description_and_searches_by_intent(self) -> None:
        skills = discover(self.root)
        self.assertEqual(1, len(skills))
        self.assertIn("root causes", skills[0].description)
        results = search(skills, "debug failing tests")
        self.assertEqual("systematic-debugging", results[0][1].name)
        chinese_results = search(skills, "排查异常根因")
        self.assertEqual("systematic-debugging", chinese_results[0][1].name)

    def test_resolves_portable_relative_pointer(self) -> None:
        alias = self.root / "skills" / "curated" / "alias"
        alias.mkdir()
        (alias / "SKILL.md").write_text(
            "../systematic-debugging/SKILL.md\n", encoding="utf-8"
        )
        skills = {item.path: item for item in discover(self.root)}
        pointer = skills["skills/curated/alias/SKILL.md"]
        self.assertTrue(pointer.pointer)
        self.assertEqual("systematic-debugging", pointer.name)

    def test_resolves_bom_prefixed_windows_relative_pointer(self) -> None:
        alias = self.root / "skills" / "curated" / "windows-alias"
        alias.mkdir()
        (alias / "SKILL.md").write_bytes(
            b"\xef\xbb\xbf..\\systematic-debugging\\SKILL.md\r\n"
        )

        skills = {item.path: item for item in discover(self.root)}
        pointer = skills["skills/curated/windows-alias/SKILL.md"]

        self.assertTrue(pointer.pointer)
        self.assertEqual("systematic-debugging", pointer.name)

    def test_resolves_windows_path_pointer_without_a_bom(self) -> None:
        windows_alias = self.root / "skills" / "curated" / "windows-alias"
        windows_alias.mkdir()
        (windows_alias / "SKILL.md").write_text(
            "..\\systematic-debugging\\SKILL.md\n", encoding="utf-8"
        )

        skills = {item.path: item for item in discover(self.root)}
        pointer = skills["skills/curated/windows-alias/SKILL.md"]

        self.assertTrue(pointer.pointer)
        self.assertEqual("systematic-debugging", pointer.name)

    def test_frontmatter_delimiter_inside_literal_block_is_not_the_boundary(
        self,
    ) -> None:
        manifest = (
            self.root / "skills" / "curated" / "systematic-debugging" / "SKILL.md"
        )
        manifest.write_text(
            "---\n"
            "name: systematic-debugging\n"
            "description: |2-\n"
            "  first line\n"
            "  ---\n"
            "  second line\n"
            "---\n\n# Body\n",
            encoding="utf-8",
        )

        skill = discover(self.root)[0]

        self.assertEqual("first line\n---\nsecond line", skill.description)
        self.assertFalse(skill.parse_error)

    def test_required_scalar_that_is_only_a_yaml_comment_is_empty(self) -> None:
        manifest = (
            self.root / "skills" / "curated" / "systematic-debugging" / "SKILL.md"
        )
        manifest.write_text(
            "---\nname: systematic-debugging\ndescription: # TODO\n---\n",
            encoding="utf-8",
        )

        issues = validate(discover(self.root))

        self.assertTrue(any(item.code == "description-missing" for item in issues))

    def test_reports_spec_errors_and_compatibility_warnings(self) -> None:
        invalid = self.root / "skills" / "curated" / "bad-name"
        invalid.mkdir()
        (invalid / "SKILL.md").write_text(
            "---\nname: Bad_Name\ndescription: useful\n"
            f"compatibility: {'x' * 501}\n---\n# Bad\n",
            encoding="utf-8",
        )
        issues = validate(discover(self.root))
        codes = {item.code for item in issues if "bad-name" in item.path}
        self.assertIn("name-format", codes)
        self.assertIn("name-folder", codes)
        self.assertIn("compatibility-length", codes)

        oversized = self.root / "skills" / "curated" / "oversized"
        oversized.mkdir()
        body = "\n".join(["instruction"] * 501)
        (oversized / "SKILL.md").write_text(
            f"---\nname: oversized\ndescription: useful\n---\n# Oversized\n{body}\n",
            encoding="utf-8",
        )
        oversized_issues = validate(discover(self.root))
        self.assertTrue(
            any(
                item.code == "progressive-disclosure" and "oversized" in item.path
                for item in oversized_issues
            )
        )

    def test_broken_pointer_is_an_error(self) -> None:
        broken = self.root / "skills" / "curated" / "broken"
        broken.mkdir()
        (broken / "SKILL.md").write_text("../missing/SKILL.md\n", encoding="utf-8")
        issues = validate(discover(self.root))
        self.assertTrue(
            any(
                item.severity == "error" and item.path.endswith("broken/SKILL.md")
                for item in issues
            )
        )

    def test_pointer_cannot_escape_repository(self) -> None:
        escaping = self.root / "skills" / "curated" / "escaping"
        escaping.mkdir()
        (escaping / "SKILL.md").write_text(
            "../../../../outside/SKILL.md\n", encoding="utf-8"
        )
        issues = validate(discover(self.root))
        self.assertTrue(
            any(
                item.severity == "error"
                and item.path.endswith("escaping/SKILL.md")
                and "escapes repository root" in item.message
                for item in issues
            )
        )

    def test_symlink_cannot_escape_repository(self) -> None:
        outside = self.root.parent / f"{self.root.name}-outside-SKILL.md"
        outside.write_text(
            "---\nname: escaped\ndescription: outside\n---\n", encoding="utf-8"
        )
        link = self.root / "skills" / "curated" / "linked-outside" / "SKILL.md"
        link.parent.mkdir()
        try:
            try:
                link.symlink_to(outside)
            except OSError as exc:
                self.skipTest(f"file symlinks are unavailable: {exc}")

            issues = validate(discover(self.root))

            self.assertTrue(
                any(
                    item.severity == "error"
                    and item.path.endswith("linked-outside/SKILL.md")
                    and "escapes repository root" in item.message
                    for item in issues
                )
            )
        finally:
            outside.unlink(missing_ok=True)

    def test_changed_paths_include_untracked_skill_manifests(self) -> None:
        self._init_repository()
        marker = self.root / "README.md"
        marker.write_text("fixture\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "README.md"], check=True)
        subprocess.run(
            ["git", "-C", str(self.root), "commit", "-q", "-m", "fixture"],
            check=True,
        )

        changed = _changed_skill_paths(self.root, "HEAD")
        self.assertIn("skills/curated/systematic-debugging/SKILL.md", changed)

    def test_changed_paths_cover_committed_staged_unstaged_and_unicode_untracked(
        self,
    ) -> None:
        self._init_repository()
        self._commit_all("baseline")
        base = subprocess.run(
            ["git", "-C", str(self.root), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

        self._write_skill("committed")
        self._commit_all("committed manifest")
        staged = self._write_skill("staged")
        subprocess.run(
            ["git", "-C", str(self.root), "add", str(staged.relative_to(self.root))],
            check=True,
        )
        existing = (
            self.root / "skills" / "curated" / "systematic-debugging" / "SKILL.md"
        )
        existing.write_text(
            existing.read_text(encoding="utf-8") + "\nupdated\n", encoding="utf-8"
        )
        self._write_skill("中文目录", name="unicode-path")

        changed = _changed_skill_paths(self.root, base)

        self.assertTrue(
            {
                "skills/curated/committed/SKILL.md",
                "skills/curated/staged/SKILL.md",
                "skills/curated/systematic-debugging/SKILL.md",
                "skills/curated/中文目录/SKILL.md",
            }.issubset(changed)
        )

    @unittest.skipIf(os.name == "nt", "POSIX-only filename characters")
    def test_changed_paths_are_nul_safe_and_preserve_literal_backslashes(self) -> None:
        self._init_repository()
        self._commit_all("baseline")
        self._write_skill("backslash\\folder", name="backslash-folder")
        self._write_skill("line\nbreak", name="line-break")

        changed = _changed_skill_paths(self.root, "HEAD")

        self.assertIn("skills/curated/backslash\\folder/SKILL.md", changed)
        self.assertIn("skills/curated/line\nbreak/SKILL.md", changed)

    def test_changed_from_is_strict_while_compatibility_mode_allows_warnings(
        self,
    ) -> None:
        self._init_repository()
        self._commit_all("baseline")
        manifest = (
            self.root / "skills" / "curated" / "systematic-debugging" / "SKILL.md"
        )
        manifest.write_text(
            "---\nname: Bad_Name\ndescription: useful\n---\n", encoding="utf-8"
        )

        with redirect_stdout(StringIO()):
            compatibility_exit = main(
                ["--root", str(self.root), "validate", "--max-issues", "0"]
            )
            changed_exit = main(
                [
                    "--root",
                    str(self.root),
                    "validate",
                    "--changed-from",
                    "HEAD",
                    "--max-issues",
                    "0",
                ]
            )

        self.assertEqual(0, compatibility_exit)
        self.assertEqual(1, changed_exit)

    def test_empty_search_does_not_return_arbitrary_skills(self) -> None:
        self.assertEqual([], search(discover(self.root), " \t "))

    def test_invalid_utf8_is_visible_as_compatibility_debt(self) -> None:
        invalid = self.root / "skills" / "curated" / "invalid-encoding"
        invalid.mkdir()
        (invalid / "SKILL.md").write_bytes(
            b"---\nname: invalid-encoding\ndescription: useful\n---\n\xff\n"
        )
        issues = validate(discover(self.root))
        self.assertTrue(
            any(
                item.severity == "warning"
                and item.code == "encoding"
                and item.path.endswith("invalid-encoding/SKILL.md")
                for item in issues
            )
        )

    def test_changed_invalid_utf8_fails_the_strict_gate(self) -> None:
        self._init_repository()
        self._commit_all("baseline")
        manifest = (
            self.root / "skills" / "curated" / "systematic-debugging" / "SKILL.md"
        )
        manifest.write_bytes(
            b"---\nname: systematic-debugging\ndescription: useful\n---\n\xff\n"
        )

        with redirect_stdout(StringIO()):
            compatibility_exit = main(
                ["--root", str(self.root), "validate", "--max-issues", "0"]
            )
            changed_exit = main(
                [
                    "--root",
                    str(self.root),
                    "validate",
                    "--changed-from",
                    "HEAD",
                    "--max-issues",
                    "0",
                ]
            )

        self.assertEqual(0, compatibility_exit)
        self.assertEqual(1, changed_exit)


if __name__ == "__main__":
    unittest.main()
