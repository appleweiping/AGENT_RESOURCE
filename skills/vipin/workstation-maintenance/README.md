# workstation-maintenance

Inventories my Windows drives, plans file moves in small approval batches, and only
moves anything after I approve a batch ID. Every applied batch writes a manifest that
can be rolled back. It can also move cluttered top-level folders of a drive into
`<drive>\_Organized\<Bucket>\_RootDirs\` and leave a junction behind, so old paths
still work.

Needs: Windows, PowerShell 5.1 or newer. No modules to install.

## Setup

The folders that must never move are not in the scripts; they go in `config.json`
(git-ignored). Start from the example and edit it:

```powershell
Copy-Item config.example.json config.json
notepad config.json
```

`protected_roots` are never scanned or moved, `infrastructure_roots` and `project_roots`
are listed but kept in place, `organized_root` is where file moves go, and
`drive_root_rules` map top-level folder names to buckets. `SKILL.md` has the full list.
A live inventory and the drive-root scripts refuse to run without a config.

## Example

Self-test on throwaway folders under `%TEMP%` (prints `"ok": true`):

```powershell
.\scripts\Test-WorkstationMaintenance.ps1
```

Inventory a folder (plus the top level of your Downloads, Desktop, Documents, Pictures
and Videos) and build a move plan from it. Nothing is moved; the plan lists batch IDs
that `Invoke-ApprovedMoveBatch.ps1 -Approved` would apply later.

```powershell
.\scripts\New-WorkstationInventory.ps1 -Roots "$HOME\Downloads" -OutputDir .\out
.\scripts\New-MovePlan.ps1 -ManifestPath .\out\<inventory manifest>.json
```

In an agent session I just ask: "Organize my Downloads, but don't move anything yet."
The agent follows `SKILL.md`: inventory, plan, approval packet, then waits for a batch ID.
