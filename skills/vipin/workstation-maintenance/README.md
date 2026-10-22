# workstation-maintenance

Inventories my Windows drives, plans file moves in small approval batches, and only
moves anything after I approve a batch ID. Every applied batch writes a manifest that
can be rolled back.

The protected folders and drive letters in `SKILL.md` and `references/` are my own
layout (`D:\Research`, `D:\devtools`, ...). Change them before using this anywhere else.

Needs: Windows, PowerShell 5.1 or newer. No modules to install.

## Example

Self-test on throwaway folders under `%TEMP%` (prints `"ok": true`):

```powershell
.\scripts\Test-WorkstationMaintenance.ps1
```

Inventory one folder and build a move plan from it. Nothing is moved; the plan lists
batch IDs that `Invoke-ApprovedMoveBatch.ps1 -Approved` would apply later.

```powershell
.\scripts\New-WorkstationInventory.ps1 -Roots "D:\Downloads" -OutputDir .\out
.\scripts\New-MovePlan.ps1 -ManifestPath .\out\<inventory manifest>.json -OutputDir .\out
```

In an agent session I just ask: "Organize my D: drive, but don't move anything yet."
The agent follows `SKILL.md`: inventory, plan, approval packet, then waits for a batch ID.
