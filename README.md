<p align="center">
  <img src="banner.png" alt="agent-resources" width="100%">
</p>

<h1 align="center">agent-resources</h1>

<p align="center">
  <strong>Curated skills, workflows, references, and routing guidance for agentic development.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/skills-curated-orange" alt="Curated skills">
  <img src="https://img.shields.io/badge/routing-implicit-blue" alt="Implicit routing">
  <img src="https://img.shields.io/badge/memory-agentmemory-green" alt="agentmemory">
  <img src="https://img.shields.io/badge/license-Apache--2.0-lightgrey" alt="Apache-2.0">
</p>

---

## What This Is

`agent-resources` is a D-drive-first library of reusable agent skills, workflow templates, references, and source mirrors.

Its job is simple: before an agent improvises a complex workflow, it should check this repository, find the right skill by task intent, read that skill's `SKILL.md`, and use the existing method.

This repository is designed to be public-safe. It should contain reusable instructions, scripts, templates, and provenance notes; it must not contain local account state, API keys, runtime caches, private logs, or generated toolchain payloads.

## Start Here

| File or folder | Purpose |
| --- | --- |
| `SKILL-INDEX.md` | Main routing map: what each skill does, when to use it, and where it lives. |
| `skills/` | Curated installable skill collections. |
| `slash-commands/` | Reusable command workflows and checklists. |
| `references/` | Documentation, guides, and reusable source notes. |
| `templates/` | Project and README templates. |
| `tools/` | Small utility scripts. |

`repos/` is intentionally ignored by Git. Keep full upstream clones and bulky mirrors local unless a small curated subset is deliberately promoted into `skills/`, `references/`, or `templates/`.

## Implicit Skill Routing

Agents should trigger skills from user intent, not only from exact skill names.

1. Classify the task: debugging, README, research audit, frontend, MCP, security, browser, document, game, writing, etc.
2. Search `SKILL-INDEX.md` and relevant skill frontmatter.
3. Read the matched `SKILL.md`.
4. Use bundled scripts/references when the skill provides them.
5. Save useful routing lessons to agentmemory or durable docs.

Examples:

| User asks for | Use |
| --- | --- |
| "organize my C/D drives", "clean up workstation", "organize D root folders", "keep devtools and wiki in sync" | `vipin/workstation-maintenance`, then `vipin-wiki` for public-safe wiki updates. Live file move plans defer recent files, cap batch sizes by default, generate approval packets, and can preflight every batch without moving files. D-root plans can move eligible root directories into `D:\_Organized` while preserving old paths as junctions. Broad approval can cover all currently passing low-risk batches. |
| "review this paper", "citation check", "experiment audit" | Project ARIS skills first. |
| README polish, repo presentation, public onboarding | README/documentation skills. |
| Broken tests, flaky behavior, unfamiliar error | Systematic debugging skills. |
| Agent memory, MCP, tool routing, wrapper regressions | Agent architecture / MCP skills. |
| New or updated skill | Skill creator / skill evaluation skills. |

## Skill Collections

| Collection | Use |
| --- | --- |
| `vipin/` | Local custom skills for workstation maintenance, communication, Lark/Feishu, frontend, paper workflows, and publishing. |
| `anthropics/` | Anthropic-oriented skills for API, MCP, web app testing, frontend design, and documents. |
| `obra-superpowers/` | Engineering workflows such as debugging, TDD, code review, planning, and parallel work. |
| `context-engineering-kit/` | Context engineering, DDD/TDD/review/reflexion/kaizen workflows. |
| `trailofbits/` | Security, audit, static analysis, and protocol review skills. |
| `ecc/` | Large agent harness skill and agent collection. |
| `standalone/` | Independent skill packs and references. |

## Operating Rules

- Keep skills discoverable: `SKILL.md` frontmatter descriptions should say exactly when the skill should trigger.
- Preserve source and license provenance for imported skill packs.
- Prefer small curated skill folders over dumping whole upstream repositories.
- Do not commit `repos/`, caches, browser profiles, generated runtime state, auth files, `.env`, or secrets.
- Audit untracked additions before committing them.
- Use `agentmemory` for live memory and cross-agent signals; use this repo for reusable skill assets and routing documentation.
- Track provenance review notes for local skill additions, starting with [`docs/skill-provenance-audit-2026-06-01.md`](docs/skill-provenance-audit-2026-06-01.md).
- Treat `skills/game-studios/` and `skills/godogen/` as local-only until their upstream source and redistribution license are confirmed.
- Route `nuwa-skill` by intent only through the curated MIT-licensed core files committed in `skills/standalone/nuwa-skill/`.

## Public-Safety Checklist

Before changing repo visibility or publishing a release:

```powershell
git status --short
git ls-files
powershell .\tools\Test-PublicSafety.ps1
powershell .\tools\Test-HistorySafety.ps1
powershell .\tools\Test-PrePushSafety.ps1
powershell .\tools\Install-PrePushHook.ps1
```

Treat matches as findings until reviewed. The history scan permits a small allowlist of known documentation placeholders such as `ghp_your_new_github_token`; real credentials must be removed from current files, cleaned from public history, and rotated before publication.

## Smoke Tests

```powershell
powershell .\tools\Test-ImplicitSkillRouting.ps1
powershell .\tools\Test-PublicSafety.ps1
powershell .\tools\Test-HistorySafety.ps1
powershell .\tools\Test-PrePushSafety.ps1
```

This checks that `SKILL-INDEX.md` and committed `SKILL.md` frontmatter expose enough intent metadata for passive skill triggering.

## Related Projects

| Project | Role |
| --- | --- |
| [vipin-wiki](https://github.com/appleweiping/vipin-wiki) | Public knowledge base and canonical agent operating contract. |
| [devtools-public](https://github.com/appleweiping/devtools-public) | Clean public export of local Windows agent launchers and health checks. |
| [agentmemory](https://github.com/rohitg00/agentmemory) | Upstream memory and MCP collaboration substrate. |

## License

Apache-2.0. Imported skill packs may carry their own upstream licenses; preserve those notices where present.
