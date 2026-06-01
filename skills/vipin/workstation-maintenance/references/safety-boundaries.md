# Safety Boundaries

## Absolute No-Move Roots

- `D:\Research` and every resolved path beneath it.
- Windows system roots: `C:\Windows`, `C:\Program Files`, `C:\Program Files (x86)`, `C:\ProgramData`.
- User runtime roots: `AppData`, browser profiles, package caches, auth/session/db/log directories.
- Active git worktrees.
- Reparse points, junctions, symlinks, and their targets.

## Default D-Drive No-Move Roots

These roots are important routing records. Keep them in place unless the user approves a dedicated project-specific migration:

- `D:\devtools`
- `D:\agent-resources`
- `D:\devtools-public`
- `D:\Company`
- `D:\Project`
- `D:\Healthcare`
- `D:\Game_develop`
- `D:\frontend`
- `D:\WeipingYan_portfolio`

## Sensitive Content

Classify sensitive candidates by path and filename only. Do not open document contents. In public wiki pages, record only bucket-level summaries and safety rules.

Sensitive patterns include medical, health, bank, finance, tax, passport, visa, insurance, application, contract, offer, resume, CV, identity, credential, secret, key, token, and private.

## Move Preconditions

File-level physical moves require all of the following:

1. A dry-run inventory manifest.
2. A move plan generated from that manifest.
3. A batch ID explicitly approved by the user.
4. A preflight check that sources still exist, destinations are under the approved target root, and no source is a protected path, reparse point, directory, or active git worktree.
5. A normal-use safety gate: live move plans default to candidates older than 30 days; recent files are deferred unless the user explicitly approves a lower age threshold.
6. An applied manifest with rollback source and destination for every moved item.

`Invoke-ApprovedMoveBatch.ps1 -PreflightOnly` may be run before approval because it performs checks and writes a preflight manifest without moving files.

## D-Drive Root Directory Organization

Directory-level root organization is a separate workflow from file-level cleanup.

- Use `New-DriveRootOrganizationPlan.ps1` to classify immediate `D:\` children only.
- Move eligible root directories under `D:\_Organized\<Bucket>\_RootDirs\`.
- Leave a junction at the original root path so existing absolute paths keep working.
- Do not recurse into or move `D:\Research`, `D:\agent-resources`, `D:\devtools`, `D:\devtools-public`, or `D:\_Organized`.
- Treat active roots such as `D:\Company`, `D:\Project`, `D:\Healthcare`, `D:\Game_develop`, `D:\frontend`, and `D:\WeipingYan_portfolio` as record-only unless the user explicitly requests a project-specific migration.
- Run `Invoke-DriveRootOrganizationPlan.ps1 -PreflightOnly` before approved execution.
- If Windows denies a root because of ACLs or active process locks, pass its manifest ID through `-SkipIds`, record it as a classified exception, and retry only after the lock is resolved.

## Delete Policy

This skill never deletes user files. Cleanup can produce deletion candidates, but deletion requires a separate explicit approval flow.
