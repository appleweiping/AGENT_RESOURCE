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

Generate a local approval packet:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\New-ApprovalPacket.ps1" -MovePlanPath "<move-plan.json>" -PreflightSummaryPath "<preflight-summary.json>"
```

The packet writes Markdown and JSON summaries with batch IDs, bucket-level counts, safety checks, and execution templates. It intentionally omits private filenames.

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

If the user grants broad approval for the current low-risk plan, do not ask for per-batch confirmation. Rerun the full non-moving preflight and execute every passing batch, stopping immediately on the first failure.

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

For broad approval, repeat the approved command for each preflight-passing batch in the move plan and write a local applied summary with the per-batch applied manifest paths. Do not skip the post-move verification: moved destinations must exist, original sources should be absent, and applied paths must not include `D:\Research`.

Move plans must produce unique destination paths. If two source files would land on the same target path, `New-MovePlan.ps1` appends a stable manifest item suffix before execution. `Invoke-ApprovedMoveBatch.ps1` also rejects duplicate destinations before moving anything.

## Rollback

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-RollbackBatch.ps1" -AppliedManifestPath "<applied-batch.json>"
```

Rollback is also preflighted. If a rollback destination already exists, the script stops instead of overwriting.
