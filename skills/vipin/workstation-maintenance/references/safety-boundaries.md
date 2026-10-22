# Safety Boundaries

## Never moved

- Every `protected_roots` entry in `config.json` and every resolved path beneath it.
  These are also left out of inventories entirely.
- The Windows folder, Program Files, Program Files (x86) and ProgramData.
- AppData, browser profiles, package caches, and auth/session/db/log folders.
- Active git worktrees.
- Reparse points (junctions, symlinks) and their targets.

## Kept in place by default

`infrastructure_roots` and `project_roots` from the config, plus the agent folders in
the user profile (`.codex`, `.claude`, `.openhands`, opencode state), are recorded in
inventories and plans but never moved. Move one only when the user asks for a
migration of that specific folder.

## Sensitive content

Classify sensitive candidates by path and filename only. Do not open documents. In
anything that leaves the machine (chat logs, notes, commits), record only bucket-level
counts and the rules that were applied.

Sensitive name patterns include medical, health, bank, finance, tax, passport, visa,
insurance, application, contract, offer, resume, CV, identity, credential, secret, key,
token, and private.

## Move preconditions

File-level moves need all of these:

1. A dry-run inventory manifest.
2. A move plan generated from that manifest.
3. A batch ID the user approved.
4. A preflight showing that sources still exist, destinations are under the target
   root, and no source or destination is under a protected root, a reparse point, a
   directory, or inside a git worktree. The executors check the protected roots recorded
   in the plan and the ones in the current config, so editing a plan cannot unprotect a folder.
5. An age gate: live plans default to files older than 30 days; newer files are deferred
   unless the user approves a lower threshold.
6. An applied manifest with rollback source and destination for every moved item.

`Invoke-ApprovedMoveBatch.ps1 -PreflightOnly` may run before approval; it checks and
writes a preflight manifest without moving anything.

## Drive-root organization

Directory-level root organization is a separate workflow from file-level cleanup.

- `New-DriveRootOrganizationPlan.ps1` classifies the immediate children of one drive root.
- Eligible folders move to `<drive>\_Organized\<Bucket>\_RootDirs\`, with a junction
  left at the original path.
- A folder that is, sits inside, or contains a protected, infrastructure or project root
  is never moved, and neither is `_Organized` itself.
- Run `Invoke-DriveRootOrganizationPlan.ps1 -PreflightOnly` before the approved run.
- If Windows denies a folder because of ACLs or open handles, pass its ID through
  `-SkipIds`, report it, and retry after the lock is gone.

## Delete policy

This skill never deletes user files. Cleanup can produce deletion candidates, but
deleting them needs a separate, explicit approval from the user.
