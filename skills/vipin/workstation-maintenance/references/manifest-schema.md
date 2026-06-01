# Manifest Schema

Inventory manifests are JSON files with a top-level object:

```json
{
  "schema_version": "1.0",
  "generated_at": "2026-06-01T18:54:07.0000000+02:00",
  "roots": ["C:\\", "D:\\"],
  "target_root": "D:\\_Organized",
  "items": []
}
```

Each item uses these fields:

- `id`: stable manifest-local ID, e.g. `wm_000001`.
- `path`: original literal path.
- `resolved_path`: canonical path used for boundary checks.
- `drive`: drive name such as `C:` or `D:`.
- `kind`: `file`, `directory`, `reparse`, `missing`, or `other`.
- `size`: file size in bytes when available.
- `mtime`: last write time in ISO format.
- `attributes`: Windows attributes string.
- `reparse_target`: junction or symlink target when available.
- `git_root`: nearest git worktree root when detected.
- `category`: one of the skill categories.
- `risk_tier`: `protected`, `high`, `medium`, `low`, or `review`.
- `move_eligible`: Boolean.
- `proposed_destination`: destination under `D:\_Organized` when eligible.
- `reason`: short classification reason.
- `rollback_source`: destination path after a move.
- `rollback_destination`: original source path for rollback.

Move plans group eligible items into batches:

- `batch_id`
- `category`
- `subcategory`
- `part_index`
- `part_count`
- `item_count`
- `total_size_bytes`
- `total_size_human`
- `risk_tier`
- `minimum_age_days`
- `max_items_per_batch`
- `requires_user_approval`
- `destination_root`
- `destination_dirs`
- `item_ids`
- `items`

Move plans also include:

- `minimum_age_days`: default `30` for live manifests.
- `max_items_per_batch`: default `100` for approval-friendly batches.
- `deferred_count`
- `deferred_reasons`
- `deferred_items`: local-only review records for recent candidates. Do not publish these filenames.

Applied manifests record:

- `applied_at`
- `move_plan_path`
- `batch_id`
- `target_root`
- `items`
- `rollback_command`

Preflight manifests record:

- `checked_at`
- `move_plan_path`
- `batch_id`
- `target_root`
- `item_count`
- `status`
- `moves_executed`: always `false`
- `items`
- `approved_command`

Preflight summary manifests record:

- `checked_at`
- `move_plan_path`
- `batch_count`
- `passed_count`
- `failed_count`
- `checked_item_count`
- `moves_executed`: should be `false`
- `results`

Do not commit `.wiki-tmp/workstation-maintenance` manifests unless the user explicitly requests a local evidence archive. They can contain private filenames.
