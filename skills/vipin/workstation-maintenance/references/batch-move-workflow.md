# Batch Move Workflow

## Dry Run

1. Generate inventory.
2. Generate move plan.
   - Default executable batches require candidates to be older than 30 days.
   - Recent candidates are recorded as deferred review items, not executable batches.
   - Executable candidates are grouped by file type and split into parts of at most 100 items by default.
3. Verify protected counts:
   - `D:\Research` entries: 0.
   - move-eligible reparse points: 0.
   - move-eligible directories: 0.
   - move-eligible git worktrees: 0.
   - recent items in executable batches: 0, unless the user explicitly requested a lower age gate.

## Approval

Present only batch summaries:

- batch ID
- category
- subcategory
- part number
- item count
- total size
- destination root
- risk tier
- minimum age gate
- maximum items per batch
- deferred recent item count

Do not show private filenames in public wiki pages. The user may inspect the local JSON/Markdown manifest directly.

## Execution

Optional non-moving preflight for a specific batch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-ApprovedMoveBatch.ps1" -MovePlanPath "<move-plan.json>" -BatchId "<batch-id>" -PreflightOnly
```

Preflight writes a local `workstation-preflight-*.json` manifest and does not create destination directories or move files.

To preflight every batch in a move plan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Test-MovePlanBatches.ps1" -MovePlanPath "<move-plan.json>"
```

This writes `workstation-preflight-summary-*.json` plus per-batch preflight manifests under the output directory.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-ApprovedMoveBatch.ps1" -MovePlanPath "<move-plan.json>" -BatchId "<batch-id>" -Approved
```

The script preflights all items before moving. It stops if any destination already exists, a source is missing, a source is under `D:\Research`, a source is a reparse point, a source is a directory, or a source belongs to a git worktree.

## Rollback

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-RollbackBatch.ps1" -AppliedManifestPath "<applied-batch.json>"
```

Rollback is also preflighted. If a rollback destination already exists, the script stops instead of overwriting.
