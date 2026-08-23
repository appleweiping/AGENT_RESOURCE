# Skill Library Quality Gate — 2026-08-23

## Outcome

AGENT_RESOURCE now has one dependency-free command for cataloging, intent search, and structural validation across every `skills/**/SKILL.md` manifest:

```powershell
python tools/skill_catalog.py catalog
python tools/skill_catalog.py search "debug failing tests"
python tools/skill_catalog.py validate
```

The initial catalog contains 1,362 manifests. Required frontmatter failures block the compatibility gate. Existing vendor-pack naming, duplication, encoding, and progressive-disclosure debt remains visible as warnings; strict validation applies to every changed manifest in local pre-push checks, pull requests, and direct pushes.

## Upstream Patterns Reviewed

- [Agent Skills specification](https://agentskills.io/specification): required metadata, field limits, directory naming, and portable skill layout.
- [agentskills/agentskills `skills-ref`](https://github.com/agentskills/agentskills/tree/main/skills-ref): reference validation behavior. Its own documentation describes it as a demonstration, so AGENT_RESOURCE does not take a production dependency on it.
- [OpenAI skill creator](https://github.com/openai/skills/tree/main/skills/.system/skill-creator): concise metadata, progressive disclosure, and scenario-based validation.
- [Microsoft Agent Skills](https://github.com/MicrosoftDocs/Agent-Skills): large curated collections, deterministic discovery, and continuously regenerated content.

No upstream implementation code was copied. The local CLI is a clean, repository-specific implementation using only the Python standard library.

## Design Decisions

- **Compatibility first:** inherited non-conformance remains usable and measurable instead of breaking the complete library overnight.
- **No new debt:** `--changed-from` makes every committed, staged, unstaged, or newly added manifest strict, including non-ASCII and untracked paths. New remote refs compare against the default branch; a first default-branch push with no baseline validates the complete library strictly.
- **Portable pointers:** Windows text representations of relative symlinks are resolved only when the target stays inside the repository; broken and escaping pointers fail validation.
- **Search without a service:** weighted name, description, and path matching works in a fresh checkout. Conservative Chinese intent aliases and CJK bigrams route common bilingual requests into English-language skills.
- **Safe CI:** GitHub Actions has read-only permissions, SHA-pinned actions, no persisted checkout credential, full-history comparison, and strict gates for both pull requests and direct pushes. The public-safety scan uses ripgrep when available and a Git/.NET fallback otherwise, so Ubuntu runners do not depend on an undeclared image tool.
- **Auditable legacy debt:** duplicate names, invalid names, directory mismatches, field limits, invalid UTF-8, and oversized manifests have stable issue codes and JSON output.

## Verification

```powershell
powershell tools/Test-SkillLibrary.ps1
powershell tools/Test-PrePushSafety.ps1
python -m ruff check tools/skill_catalog.py tools/tests
python -m ruff format --check tools/skill_catalog.py tools/tests
git diff --check
```

Representative integration tests cover debugging, documentation, frontend, agent architecture, research evidence, and Chinese debugging intents against the real repository catalog. Fixture tests cover folded YAML descriptions, pointer compatibility, repository-escape rejection, untracked manifests, field constraints, invalid UTF-8, and legacy warning behavior.
