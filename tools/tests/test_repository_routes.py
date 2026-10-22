from __future__ import annotations

import unittest
from pathlib import Path

from tools.skill_catalog import discover, search

ROOT = Path(__file__).resolve().parents[2]


class RepositoryRoutingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.skills = discover(ROOT)

    def test_plain_requests_find_the_matching_skill_first(self) -> None:
        cases = {
            "organize old files on my drives": "workstation-maintenance",
            "turn a novel into a manga script": "literature-to-manga",
            "harden a vague requirement before editing a large project": "project-hardness",
            "draft email replies in gmail": "email-assistant",
            "summarize a Feishu document link": "feishu-bridge",
            "triage unread wechat messages and prefill a reply": "communication-assistant",
            "upload a video to wechat channels": "wechat-video-channel-publish",
            "career advice from lidang perspective": "lidang-perspective",
        }
        for query, expected in cases.items():
            with self.subTest(query=query):
                results = search(self.skills, query, limit=3)
                self.assertTrue(results, f"{query!r} returned nothing")
                self.assertEqual(expected, results[0][1].name)

    def test_every_skill_folder_explains_itself(self) -> None:
        for skill in self.skills:
            folder = ROOT / Path(skill.manifest_path).parent
            with self.subTest(skill=skill.name):
                self.assertTrue(
                    (folder / "README.md").is_file(),
                    f"{folder} needs a README.md with a usage example",
                )

    def test_skill_names_are_unique(self) -> None:
        names = [skill.name for skill in self.skills]
        self.assertEqual(len(names), len(set(names)))


if __name__ == "__main__":
    unittest.main()
