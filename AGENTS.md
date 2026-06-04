# AGENT_RESOURCE Agent Instructions

`AGENT_RESOURCE` is the canonical shared skill and workflow library. `D:\agent-resources` is a compatibility junction to this repository.

## Source Of Truth

Read `README.md` and `SKILL-INDEX.md` first. For skill-specific work, read the target `SKILL.md` and only the relevant references/scripts.

## Boundaries

- Commit reusable skills, workflow docs, scripts, templates, and provenance-cleared references only.
- Do not commit upstream full clones under ignored `repos/`, caches, toolchains, browser profiles, account state, generated runtime artifacts, secrets, or private logs.
- Preserve source/license provenance for imported skills.
- Keep shared skill source here. Agent homes under `D:\devtools` should expose skills by junction or symlink rather than duplicate them.

## WEIPING Constellation

`WEIPING_WIKI` is the public route map; `AGENT_RESOURCE` is the shared method library. Link them through skill names, paths, trigger rules, validation commands, and provenance notes. Do not make skills require private wiki state, generated reports, local DBs, or credentials to be usable.

The shared `vipin/workstation-maintenance` skill owns physical C:/D:/G: organization workflows and protects `D:\Research`, `D:\AGENT_RESOURCE`, `D:\AGENTIC_SCIENCE`, `D:\devtools`, and public devtools exports during D-root planning.

## Validation

Before commit or push:

```powershell
powershell .\tools\Test-ImplicitSkillRouting.ps1
powershell .\tools\Test-PublicSafety.ps1
powershell .\tools\Test-HistorySafety.ps1
powershell .\tools\Test-PrePushSafety.ps1
git diff --check
```
