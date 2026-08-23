from __future__ import annotations

import unittest
from pathlib import Path

from tools.skill_catalog import discover, search


class RepositoryRoutingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.skills = discover(Path(__file__).resolve().parents[2])

    def test_representative_intents_find_expected_skills(self) -> None:
        cases = {
            "root cause debugging unexpected behavior": {
                "root-cause-tracing",
                "systematic-debugging",
            },
            "write and improve repository README documentation": {
                "readme-blueprint-generator",
                "write-concisely",
            },
            "build polished frontend UI design": {
                "frontend-design",
                "frontend-design-direction",
            },
            "agent architecture MCP memory": {"agent-architecture-audit"},
            "audit research paper citations evidence": {
                "deep-research",
                "paper-orchestra",
            },
            "排查测试失败的根本原因": {"root-cause-tracing", "systematic-debugging"},
            "智能体架构 MCP 内存": {"agent-architecture-audit"},
            "审查论文引用证据": {"deep-research", "paper-orchestra"},
        }
        for query, expected in cases.items():
            with self.subTest(query=query):
                names = {skill.name for _, skill in search(self.skills, query, limit=5)}
                self.assertTrue(names & expected, f"{query!r} returned {sorted(names)}")

    def test_mixed_chinese_debugging_intent_is_not_mistaken_for_visual_design(
        self,
    ) -> None:
        names = [
            skill.name for _, skill in search(self.skills, "前端测试失败排查", limit=5)
        ]

        self.assertIn("webapp-testing", names)
        self.assertNotIn("frontend-design", names)

    def test_english_multi_intent_query_prioritizes_the_action(self) -> None:
        results = search(self.skills, "write frontend tests", limit=5)

        self.assertTrue(results)
        self.assertEqual("write-tests", results[0][1].name)
