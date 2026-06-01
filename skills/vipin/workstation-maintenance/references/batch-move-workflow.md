# Batch Move Workflow

## Dry Run

1. Generate inventory.
2. Generate move plan.
3. Verify protected counts:
   - `D:\Research` entries: 0.
   - move-eligible reparse points: 0.
   - move-eligible directories: 0.
   - move-eligible git worktrees: 0.

## Approval

Present only batch summaries:

- batch ID
- category
- item count
- total size
- destination root
- risk tier

Do not show private filenames in public wiki pages. The user may inspect the local JSON/Markdown manifest directly.

## Execution

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
