# Skill Provenance Audit - 2026-06-30

This audit records the intake of the `huashu-design` skill into the public-routable tree.

## Current Decision

Commit the curated `huashu-design` subset (code + docs + functional source assets) and
route it implicitly. Heavy binary media (BGM/SFX audio, showcase screenshots) is kept
local-only via `.gitignore` and can be re-fetched from upstream when needed.

## Findings

| Path | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `skills/standalone/huashu-design/` | Curated for public intake | Upstream `github.com/alchaincyf/huashu-design` (branch `master`, shallow-cloned 2026-06-30 into the gitignored `repos/`). `LICENSE` is MIT, copyright (c) 2026 alchaincyf (花叔 · 花生). Strict secret scan (ripgrep, same regex as `tools/Test-PublicSafety.ps1`) returned no matches; `.env.example` holds placeholders only. Nested `.git` and the upstream skill `.gitignore` were excluded from the copy. | Commit the curated subset (~1.4 MB, 82 files: `SKILL.md`, `LICENSE`, `README*.md`, `references/`, `scripts/`, `demos/`, functional `assets/` code, `package*.json`, `test-prompts.json`, `.env.example`). Keep audio (`assets/bgm-*.mp3`, `assets/sfx/`) and the screenshot gallery (`assets/showcases/`) local-only via `.gitignore`. |

## Public Routing Rule

Implicit routing may reference only committed, provenance-cleared skills. The committed
`huashu-design` subset is provenance-cleared (MIT, attributed). The local-only media under
`assets/bgm-*.mp3`, `assets/sfx/`, and `assets/showcases/` is available for local skill
execution but is not part of the published, redistributed subset. The MIT `LICENSE` is
retained in the committed subset to satisfy the attribution requirement.
