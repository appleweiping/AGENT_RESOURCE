# Implicit Skill Routing E2E - 2026-06-01

This note records the real no-explicit-skill-name routing check requested for Codex and CC.

## Codex Evidence

In the implementation session, Codex was not given the exact skill names as the user request. The task intent matched agent infrastructure, memory/tool routing, public hygiene, and wiki maintenance. Codex then opened and followed:

- `D:\devtools\codex\home\skills\ecc\skills\agent-architecture-audit\SKILL.md`
- `D:\Research\vipin's knowledgebase\.codex\skills\vipin-wiki\SKILL.md`

The selected workflow bodies were read before edits.

## CC Evidence

CC was called with a read-only prompt that did not name any skill. The prompt described stale memory leaks, skipped required tools, hidden repair loops, and obsolete queue coordination.

Command shape:

```powershell
$prompt | D:\devtools\cc.cmd -p --model claude-haiku-4-5 --output-format text --permission-mode dontAsk --allowedTools "Read,Grep,Glob" --add-dir "D:\devtools\codex\home\skills" --max-budget-usd 0.50 --no-session-persistence
```

Result:

```text
SELECTED_PATH: D:\agent-resources\skills\obra-superpowers\systematic-debugging\SKILL.md
TRIGGER_REASON: Wrapper layer regressions causing multi-symptom failures require root-cause investigation before fixes.
FIRST_HEADING: # Systematic Debugging
```

This proves a no-explicit-name CC route can select and read a local workflow file. It selected `systematic-debugging`, which is reasonable for the symptom prompt. For stricter agent-architecture routing, future tests should compare the selected path against an allowlist that includes both `systematic-debugging` and agent architecture audit workflows.

## Runtime Repair During Test

The first CC attempt failed because `D:\devtools\npm-global\node_modules\@anthropic-ai\claude-code\bin\claude.exe` was missing and only `.old.*` backups remained. The newest backup was restored to `claude.exe`, after which `scripts\Test-LocalCcPartner.ps1` reported Claude Code `2.1.143`, PixelCat listening on `127.0.0.1:8990`, and API status `api_ok`.
