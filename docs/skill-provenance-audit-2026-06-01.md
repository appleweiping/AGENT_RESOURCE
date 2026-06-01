# Skill Provenance Audit - 2026-06-01

This audit records local skill additions that are present in the working tree but are not yet safe to publish or route implicitly.

## Current Decision

Do not commit newly discovered skill packs until each pack has:

- an upstream repository or author/provenance record
- a license compatible with public redistribution
- a strict secret scan
- a clear routing entry in `SKILL-INDEX.md`
- bulky/generated/cache artifacts excluded

## Findings

| Path | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `skills/game-studios/` | Local-only, not provenance-cleared | 73 `SKILL.md` files; no top-level README/LICENSE found in the local copy. | Ignored by Git and not public-routed until origin and license are confirmed. |
| `skills/godogen/` | Local-only, not provenance-cleared | Contains `godogen` and `godot-api` skills/scripts; no top-level README/LICENSE found in the local copy. | Ignored by Git and not public-routed until origin and license are confirmed. |
| `skills/standalone/nuwa-skill/` | Curated for public intake | Git remotes showed `appleweiping/nuwa-skill` and `alchaincyf/nuwa-skill`; `LICENSE` is MIT, copyright 2026 Huashu. Local nested `.git` and `scripts/__pycache__` were removed. | Commit the core skill only: `LICENSE`, `SKILL.md`, `references/`, `scripts/`, and small source assets. Keep examples, generated/person-specific research packs, QR codes, screenshots, and large media ignored. |

## Public Routing Rule

Implicit routing may reference only committed, provenance-cleared skills. Untracked or ignored local skill folders are available for local inspection but should not be treated as public-safe installed capabilities.

For the current game-development packs, future intake must first identify the upstream repository, license, and intended redistribution scope. Do not force-add `skills/game-studios/` or `skills/godogen/` until that review is complete.
