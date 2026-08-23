from __future__ import annotations

import configparser
import subprocess
import unittest
from pathlib import Path


class RepositoryIntegrityTests(unittest.TestCase):
    def test_every_gitlink_has_a_portable_submodule_mapping(self) -> None:
        root = Path(__file__).resolve().parents[2]
        result = subprocess.run(
            ["git", "-C", str(root), "ls-files", "--stage", "-z"],
            check=True,
            capture_output=True,
        )
        gitlinks = {
            record.split(b"\t", 1)[1].decode("utf-8")
            for record in result.stdout.split(b"\0")
            if record and record.split(None, 1)[0] == b"160000"
        }
        if not gitlinks:
            return

        manifest = root / ".gitmodules"
        self.assertTrue(manifest.is_file(), "gitlinks require a committed .gitmodules file")

        parser = configparser.ConfigParser(interpolation=None)
        parser.read(manifest, encoding="utf-8")
        mappings: dict[str, str] = {}
        for section in parser.sections():
            if not section.startswith('submodule "'):
                continue
            path = parser.get(section, "path", fallback="").strip()
            url = parser.get(section, "url", fallback="").strip()
            if path:
                mappings[path] = url

        self.assertEqual(gitlinks, set(mappings), "gitlink and .gitmodules paths differ")
        for path, url in mappings.items():
            with self.subTest(path=path):
                self.assertRegex(url, r"^https://github\.com/[^/]+/[^/]+\.git$")


if __name__ == "__main__":
    unittest.main()
