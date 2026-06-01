---
name: workstation-maintenance
description: Safely inventory and organize local C/D/G drives, protect research roots, perform file-level approved moves or D-drive root move-with-junction organization, and coordinate devtools, agent-resources, and vipinknowledge maintenance through manifests and rollback.
license: MIT
---

# Workstation Maintenance

Use this skill for whole-computer maintenance: C/D/G drive inventory, safe file organization, D-drive root directory organization with compatibility junctions, agent infrastructure routing, and coordinated updates between `D:\devtools`, `D:\agent-resources`, and `D:\Research\vipin's knowledgebase`.

This skill owns physical file organization. The `vipin-wiki` skill owns public-safe wiki updates after a dry run or an approved move changes state.

## Hard Boundaries

- Never move, delete, recurse into, or depend on contents under `D:\Research`.
- Treat any resolved path under `D:\Research` as protected even if reached through a junction, symlink, relative path, or different casing.
- C: is in scope for inventory and classification, but Windows, Program Files, ProgramData, AppData, package caches, browser profiles, auth/session/db/log directories, active repos, and reparse points are no-move by default.
- D: is in scope except `D:\Research`; important roots such as `D:\devtools`, `D:\agent-resources`, `D:\devtools-public`, `D:\Company`, `D:\Project`, `D:\Healthcare`, `D:\Game_develop`, `D:\frontend`, and `D:\WeipingYan_portfolio` are routing records by default, not move targets.
- Do not delete files. Deletion can only be a later candidate list with explicit user approval.
- Do not read sensitive file contents for classification; use path and filename patterns only.
- Do not execute a physical move without a manifest, a move plan, an explicit batch ID from the user, and rollback metadata.

## Workflow

1. Preflight
   - Check git status for `vipinknowledge`, `agent-resources`, `devtools`, and `devtools-public`.
   - Run `D:\devtools\health-check.ps1`, `agentmemory status`, and `python scripts/wiki.py maintain --scope whole-computer --json` from `vipinknowledge`.
   - Record unrelated dirty files and leave them untouched.

2. Inventory
   - Run `scripts/New-WorkstationInventory.ps1`.
   - Store generated JSON/Markdown under ignored `.wiki-tmp/workstation-maintenance/` when working from `vipinknowledge`.
   - Confirm there are zero entries under `D:\Research` and zero move-eligible reparse points, directories, or git worktrees.

3. Plan
   - Run `scripts/New-MovePlan.ps1` against the inventory manifest for file-level cleanup.
   - By default, executable batches include only low-risk candidates older than 30 days; recent candidates are deferred for review so normal use is not disrupted.
   - Batches are grouped by file type and capped at 100 items by default so the user can approve narrow, understandable units.
   - Destination paths are made unique before execution; duplicate source filenames receive stable manifest-item suffixes.
   - Review batch IDs, categories, subcategories, part numbers, item counts, size, target root, age gate, and risk tier.
   - Present only public-safe batch summaries in chat/wiki. Do not list sensitive filenames in public wiki pages.
   - For D-drive root directory organization, run `scripts/New-DriveRootOrganizationPlan.ps1` instead. It classifies immediate `D:\` children, proposes moving eligible root directories under `D:\_Organized\<Bucket>\_RootDirs\`, and preserves old absolute paths through junctions.

4. Approval Gate
   - Stop before moving files.
   - Run `scripts/New-ApprovalPacket.ps1` to create a public-safe local packet of file-level batch IDs, counts, safety checks, and approval/execution commands.
   - Optionally run a non-moving preflight for the exact batch ID with `Invoke-ApprovedMoveBatch.ps1 -PreflightOnly`.
   - For a full approval readiness pass, run `scripts/Test-MovePlanBatches.ps1` to preflight every batch without moving files.
   - For D-drive root directory organization, run `Invoke-DriveRootOrganizationPlan.ps1 -PreflightOnly`; use `-SkipIds` for roots that Windows locks or refuses after they have been classified.
   - Ask the user to approve one or more batch IDs unless they have already granted broad approval for all currently passing low-risk batches.
   - When broad approval exists, execute all currently passing low-risk batches without repeated trivial prompts.
   - Use `scripts/Invoke-ApprovedMoveBatch.ps1 -Approved` only after explicit approval.

5. Rollback And Validation
   - Every applied batch must write an applied manifest with rollback source/destination fields.
   - Use `scripts/Invoke-RollbackBatch.ps1` if the user asks to undo an applied batch.
   - Use `scripts/Invoke-DriveRootOrganizationPlan.ps1 -RollbackManifestPath <applied.json>` to undo a drive-root move-with-junction pass.
   - Run `scripts/Test-WorkstationMaintenance.ps1` after script changes.

6. Wiki Sync
   - After dry-run inventory or approved movement, update `vipinknowledge` through `vipin-wiki`.
   - Public wiki pages should record roots, buckets, policy, counts, and safety boundaries, not private document details.

7. Agent Infrastructure Sync
   - Keep shared skill source in `D:\agent-resources\skills\vipin\workstation-maintenance`.
   - Expose to Codex and Claude/OpenCode through junctions or symlinks under `D:\devtools`.
   - Update `D:\agent-resources\SKILL-INDEX.md`, `D:\agent-resources\README.md`, `D:\devtools\README.md`, and `vipinknowledge` agent docs together.

## Categories

- `Protected-NoMove`
- `AgentInfrastructure`
- `ActiveProject`
- `CourseworkArchive`
- `PersonalSensitive`
- `MediaAssets`
- `Downloads`
- `TempCache`
- `VendorSystemToolchain`
- `UnknownReview`
- `Documents-Private`
- `Games`

## Standard Commands

From `D:\Research\vipin's knowledgebase`:

```powershell
$out = "D:\Research\vipin's knowledgebase\.wiki-tmp\workstation-maintenance"
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\New-WorkstationInventory.ps1" -OutputDir $out
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\New-MovePlan.ps1" -ManifestPath "<manifest.json>"
```

`New-MovePlan.ps1` defaults to `-MinimumAgeDays 30 -MaxItemsPerBatch 100`. Lower the age gate only when the user explicitly accepts the higher risk of moving recent files.

Approved movement, only after the user names a batch ID:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\New-ApprovalPacket.ps1" -MovePlanPath "<move-plan.json>" -PreflightSummaryPath "<preflight-summary.json>"
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Test-MovePlanBatches.ps1" -MovePlanPath "<move-plan.json>"
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-ApprovedMoveBatch.ps1" -MovePlanPath "<move-plan.json>" -BatchId "batch-downloads-archives-old" -PreflightOnly
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-ApprovedMoveBatch.ps1" -MovePlanPath "<move-plan.json>" -BatchId "batch-downloads-archives-old" -Approved
```

Rollback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-RollbackBatch.ps1" -AppliedManifestPath "<applied-batch.json>"
```

D-drive root directory organization:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\New-DriveRootOrganizationPlan.ps1" -DriveRoot "D:\" -OutputDir $out
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-DriveRootOrganizationPlan.ps1" -PlanPath "<d-drive-root-plan.json>" -PreflightOnly
& "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-DriveRootOrganizationPlan.ps1" -PlanPath "<d-drive-root-plan.json>" -Approved -SkipIds @("dr_0016")
```

Directory roots that fail because of ACLs or active process locks should remain in place, be recorded as classified exceptions, and be retried only after the lock is resolved. Do not replace a locked root with a partial move.

## References

- `references/safety-boundaries.md`
- `references/manifest-schema.md`
- `references/batch-move-workflow.md`
- `references/agent-infrastructure-sync.md`
