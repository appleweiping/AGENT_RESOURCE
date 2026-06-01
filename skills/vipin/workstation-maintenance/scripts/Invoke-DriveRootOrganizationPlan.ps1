param(
    [Parameter(Mandatory = $true)]
    [string]$PlanPath,
    [switch]$Approved,
    [switch]$PreflightOnly,
    [string[]]$SkipIds = @(),
    [string]$RollbackManifestPath = "",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
$HardProtectedRootNames = @("Research", "agent-resources", "devtools", "devtools-public", "_Organized")

function Get-FullPathSafe {
    param([string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) } catch { return $Path }
}

function Test-PathUnder {
    param([string]$Path, [string]$Root)
    if (-not $Path) { return $false }
    $full = (Get-FullPathSafe $Path).TrimEnd('\')
    $base = (Get-FullPathSafe $Root).TrimEnd('\')
    return $full.Equals($base, [System.StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($base + "\", [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-ImmediateChild {
    param([string]$Path, [string]$Root)
    $parent = (Split-Path -Parent (Get-FullPathSafe $Path)).TrimEnd('\') + "\"
    $rootFull = (Get-FullPathSafe $Root).TrimEnd('\') + "\"
    return $parent.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ReparseTargetSafe {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSObject.Properties.Name -contains "Target") {
        if ($item.Target -is [array]) {
            return [string]($item.Target -join ";")
        }
        return [string]$item.Target
    }
    return ""
}

function Test-SamePath {
    param([string]$Left, [string]$Right)
    if (-not $Left -or -not $Right) { return $false }
    $leftFull = (Get-FullPathSafe $Left).TrimEnd('\')
    $rightFull = (Get-FullPathSafe $Right).TrimEnd('\')
    return $leftFull.Equals($rightFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-HardProtectedRoot {
    param([string]$Path, [string]$DriveRoot)
    if (-not (Test-ImmediateChild $Path $DriveRoot)) { return $false }
    $leaf = Split-Path -Leaf (Get-FullPathSafe $Path).TrimEnd('\')
    return [bool]($HardProtectedRootNames | Where-Object { $_.Equals($leaf, [System.StringComparison]::OrdinalIgnoreCase) })
}

function Test-ReparsePoint {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force
    return (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}

if ($RollbackManifestPath) {
    $rollbackFull = Get-FullPathSafe $RollbackManifestPath
    if (-not (Test-Path -LiteralPath $rollbackFull -PathType Leaf)) {
        throw "Rollback manifest not found: $rollbackFull"
    }
    $applied = Get-Content -LiteralPath $rollbackFull -Raw | ConvertFrom-Json
    $rollbackDriveRoot = [string]$applied.drive_root
    $rollbackTargetRoot = [string]$applied.target_root
    if (-not $rollbackDriveRoot -or -not $rollbackTargetRoot) {
        throw "Rollback manifest missing drive_root or target_root."
    }
    $rolledBack = [System.Collections.Generic.List[object]]::new()
    foreach ($item in @($applied.items | Sort-Object id -Descending)) {
        if (-not (Test-ImmediateChild $item.original_source $rollbackDriveRoot)) {
            throw "Rollback source is not an immediate child of drive root: $($item.original_source)"
        }
        if (Test-HardProtectedRoot $item.original_source $rollbackDriveRoot) {
            throw "Refusing rollback into protected root: $($item.original_source)"
        }
        if (-not (Test-PathUnder $item.moved_destination $rollbackTargetRoot)) {
            throw "Rollback moved destination is outside target root: $($item.moved_destination)"
        }
        if (Test-PathUnder $item.original_source "D:\Research" -or Test-PathUnder $item.moved_destination "D:\Research") {
            throw "Refusing rollback involving Research path: $($item.original_source)"
        }
        if (-not (Test-Path -LiteralPath $item.moved_destination -PathType Container)) {
            throw "Rollback target missing: $($item.moved_destination)"
        }
        if (Test-Path -LiteralPath $item.original_source) {
            $existing = Get-Item -LiteralPath $item.original_source -Force
            if (($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) {
                throw "Rollback source path exists and is not a junction: $($item.original_source)"
            }
            $actualTarget = Get-ReparseTargetSafe $item.original_source
            if (-not $actualTarget -or -not (Test-SamePath $actualTarget $item.moved_destination)) {
                throw "Rollback source junction target mismatch for $($item.original_source): $actualTarget"
            }
            [System.IO.Directory]::Delete($item.original_source, $false)
        }
        [System.IO.Directory]::Move($item.moved_destination, $item.original_source)
        $rolledBack.Add($item)
    }
    [pscustomobject]@{
        rollback_manifest = $rollbackFull
        rolled_back_count = $rolledBack.Count
    } | ConvertTo-Json -Depth 4
    return
}

if (-not $Approved -and -not $PreflightOnly) {
    throw "Refusing drive-root organization without -Approved."
}

$planFull = Get-FullPathSafe $PlanPath
if (-not (Test-Path -LiteralPath $planFull -PathType Leaf)) {
    throw "Plan not found: $planFull"
}
$plan = Get-Content -LiteralPath $planFull -Raw | ConvertFrom-Json
if (-not $OutputDir) {
    $OutputDir = Split-Path -Parent $planFull
}
$out = Get-FullPathSafe $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

$driveRoot = [string]$plan.drive_root
$targetRoot = [string]$plan.target_root
if (-not (Test-ImmediateChild $targetRoot $driveRoot) -or -not ((Split-Path -Leaf (Get-FullPathSafe $targetRoot).TrimEnd('\')).Equals("_Organized", [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "Target root must be the drive-root _Organized directory: $targetRoot"
}
if (Test-ReparsePoint $targetRoot) {
    throw "Target root must not be a reparse point: $targetRoot"
}
$items = @($plan.items | Where-Object {
    $_.action -eq "move-with-junction" -and $SkipIds -notcontains $_.id
})
if ($items.Count -eq 0) {
    throw "Plan contains no move-with-junction items."
}

$duplicateTargets = @($items | Group-Object target_path | Where-Object { $_.Count -gt 1 })
if ($duplicateTargets.Count -gt 0) {
    throw "Duplicate target path in drive-root plan: $($duplicateTargets[0].Name)"
}

$completed = @{}
foreach ($item in $items) {
    if (-not (Test-ImmediateChild $item.source_path $driveRoot)) {
        throw "Source is not an immediate child of drive root: $($item.source_path)"
    }
    if (Test-HardProtectedRoot $item.source_path $driveRoot) {
        throw "Refusing protected root from drive-root plan: $($item.source_path)"
    }
    if (-not (Test-PathUnder $item.target_path $targetRoot)) {
        throw "Target is outside target root: $($item.target_path)"
    }
    if (Test-PathUnder $item.source_path "D:\Research" -or Test-PathUnder $item.target_path "D:\Research") {
        throw "Refusing Research path: $($item.source_path)"
    }
    $sourceExists = Test-Path -LiteralPath $item.source_path -PathType Container
    $targetExists = Test-Path -LiteralPath $item.target_path -PathType Container
    if (-not $sourceExists -and $targetExists) {
        $completed[$item.id] = "needs-junction"
        continue
    }
    if (-not $sourceExists) {
        throw "Source directory missing: $($item.source_path)"
    }
    $sourceItem = Get-Item -LiteralPath $item.source_path -Force
    $sourceIsReparse = (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
    if ($sourceIsReparse -and $targetExists) {
        $actualTarget = Get-ReparseTargetSafe $item.source_path
        if (-not $actualTarget -or -not (Test-SamePath $actualTarget $item.target_path)) {
            throw "Existing junction target mismatch for $($item.source_path): $actualTarget"
        }
        $completed[$item.id] = "completed"
        continue
    }
    if ($sourceIsReparse) {
        throw "Refusing to move existing reparse point: $($item.source_path)"
    }
    if ($targetExists) {
        throw "Target already exists: $($item.target_path)"
    }
}

if ($PreflightOnly) {
    [pscustomobject]@{
        plan = $planFull
        preflight_ok = $true
        checked_count = $items.Count
        drive_root = $driveRoot
        target_root = $targetRoot
    } | ConvertTo-Json -Depth 4
    return
}

$moved = [System.Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    if ($completed.ContainsKey($item.id)) {
        $state = [string]$completed[$item.id]
        if ($state -eq "needs-junction") {
            New-Item -ItemType Junction -Path $item.source_path -Target $item.target_path | Out-Null
        }
        $moved.Add([pscustomobject][ordered]@{
            id = $item.id
            name = $item.name
            original_source = $item.source_path
            moved_destination = $item.target_path
            junction_path = $item.source_path
            category = $item.category
            reason = $item.reason
            already_completed = ($state -eq "completed")
            repaired_missing_junction = ($state -eq "needs-junction")
            junction_target = Get-ReparseTargetSafe $item.source_path
        })
        continue
    }
    $targetParent = Split-Path -Parent $item.target_path
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
    [System.IO.Directory]::Move($item.source_path, $item.target_path)
    New-Item -ItemType Junction -Path $item.source_path -Target $item.target_path | Out-Null
    $moved.Add([pscustomobject][ordered]@{
        id = $item.id
        name = $item.name
        original_source = $item.source_path
        moved_destination = $item.target_path
        junction_path = $item.source_path
        category = $item.category
        reason = $item.reason
        already_completed = $false
        junction_target = Get-ReparseTargetSafe $item.source_path
    })
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$appliedPath = Join-Path $out "d-drive-root-organization-applied-$stamp.json"
$applied = [ordered]@{
    schema_version = "1.0"
    applied_at = (Get-Date).ToString("o")
    plan_path = $planFull
    drive_root = $driveRoot
    target_root = $targetRoot
    moved_count = $moved.Count
    items = $moved
    rollback_command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-DriveRootOrganizationPlan.ps1`" -PlanPath `"$planFull`" -RollbackManifestPath `"$appliedPath`""
}
$applied | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $appliedPath -Encoding UTF8

[pscustomobject]@{
    applied_manifest = $appliedPath
    moved_count = $moved.Count
    rollback_command = $applied.rollback_command
} | ConvertTo-Json -Depth 4
