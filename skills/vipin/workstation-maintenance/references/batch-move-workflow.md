# Batch Move Workflow

This covers file-level cleanup batches. Drive-root folder organization is at the end.
Commands run from the skill folder.

## Dry run

1. Generate the inventory.
2. Generate the move plan.
   - Executable batches only contain files older than 30 days by default.
   - Newer candidates are recorded as deferred review items, not executable batches.
   - Candidates are grouped by file type and split into parts of at most 100 items.
3. Check the counts:
   - entries under protected roots: 0
   - move-eligible reparse points: 0
   - move-eligible directories: 0
   - move-eligible git worktree files: 0
   - recent items in executable batches: 0, unless the user asked for a lower age gate

## Approval

Write a local approval packet:

```powershell
.\scripts\New-ApprovalPacket.ps1 -MovePlanPath "<move-plan.json>" -PreflightSummaryPath "<preflight-summary.json>"
```

The packet has Markdown and JSON summaries with batch IDs, bucket-level counts, safety
checks, and ready-to-paste commands. It leaves out filenames.

Show the user only batch summaries:

- batch ID, category, subcategory and part number
- item count and total size
- destination root
- risk tier, minimum age gate and maximum items per batch
- deferred recent item count

The user can open the local JSON/Markdown plan to see individual files.

If the user approves the whole current low-risk plan, do not ask again for each batch.
Rerun the full preflight and execute every passing batch, stopping at the first failure.

## Execution

Preflight one batch without moving anything:

```powershell
.\scripts\Invoke-ApprovedMoveBatch.ps1 -MovePlanPath "<move-plan.json>" -BatchId "<batch-id>" -PreflightOnly
```

This writes `workstation-preflight-*.json` and does not create folders or move files.

Preflight every batch in a plan:

```powershell
.\scripts\Test-MovePlanBatches.ps1 -MovePlanPath "<move-plan.json>"
```

This writes `workstation-preflight-summary-*.json` plus one preflight manifest per batch.

Move an approved batch:

```powershell
.\scripts\Invoke-ApprovedMoveBatch.ps1 -MovePlanPath "<move-plan.json>" -BatchId "<batch-id>" -Approved
```

The script checks every item before moving any. It stops if a destination already
exists, a source is missing, a source or destination is under a protected root, a
source is a reparse point or a directory, or a source belongs to a git worktree.

After a broad approval, run the approved command for each passing batch and keep a
local list of the applied manifest paths. Then check that moved files exist at their
destinations and are gone from their sources.

Move plans always have unique destinations. If two files would land on the same path,
`New-MovePlan.ps1` appends the item ID; `Invoke-ApprovedMoveBatch.ps1` also rejects
duplicate destinations before moving anything.

## Rollback

```powershell
.\scripts\Invoke-RollbackBatch.ps1 -AppliedManifestPath "<applied-batch.json>"
```

Rollback is checked first too. If a file already exists at the original path, it stops
instead of overwriting.

## Drive-root folder plan

Use this to sort the top-level folders of one drive into buckets without breaking
existing absolute paths.

```powershell
$out = Join-Path $env:TEMP "workstation-maintenance"
.\scripts\New-DriveRootOrganizationPlan.ps1 -DriveRoot "<drive>" -OutputDir $out
.\scripts\Invoke-DriveRootOrganizationPlan.ps1 -PlanPath "<drive-root-plan.json>" -PreflightOnly
.\scripts\Invoke-DriveRootOrganizationPlan.ps1 -PlanPath "<drive-root-plan.json>" -Approved -SkipIds @("dr_0016","dr_0041")
```

The executor moves each folder into `<drive>\_Organized\<Bucket>\_RootDirs\` and creates
an NTFS junction at the old path. If a folder is locked or access is denied, do not force
a partial move; rerun with its ID in `-SkipIds` and report it.

Rollback:

```powershell
.\scripts\Invoke-DriveRootOrganizationPlan.ps1 -PlanPath "<drive-root-plan.json>" -RollbackManifestPath "<drive-root-applied.json>"
```
