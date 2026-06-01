param(
    [Parameter(Mandatory = $true)]
    [string]$MovePlanPath,
    [Parameter(Mandatory = $true)]
    [string]$BatchId,
    [switch]$Approved,
    [switch]$PreflightOnly,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

function Get-FullPathSafe {
    param([string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) } catch { return $Path }
}

function Test-PathUnder {
    param([string]$Path, [string]$Root)
    $full = (Get-FullPathSafe $Path).TrimEnd('\')
    $base = (Get-FullPathSafe $Root).TrimEnd('\')
    return $full.Equals($base, [System.StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($base + "\", [System.StringComparison]::OrdinalIgnoreCase)
}

if ($Approved -and $PreflightOnly) {
    throw "Use either -Approved or -PreflightOnly, not both."
}

if (-not $Approved -and -not $PreflightOnly) {
    throw "Refusing to move files without -Approved. Use -PreflightOnly for a non-moving batch check."
}

$planFull = Get-FullPathSafe $MovePlanPath
if (-not (Test-Path -LiteralPath $planFull -PathType Leaf)) {
    throw "Move plan not found: $planFull"
}

$plan = Get-Content -LiteralPath $planFull -Raw | ConvertFrom-Json
$batch = @($plan.batches | Where-Object { $_.batch_id -eq $BatchId }) | Select-Object -First 1
if (-not $batch) {
    throw "Batch not found in move plan: $BatchId"
}

if (-not $OutputDir) {
    $OutputDir = Split-Path -Parent $planFull
}
$out = Get-FullPathSafe $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

$targetRoot = [string]$plan.target_root
$items = @($batch.items)
if ($items.Count -eq 0) {
    throw "Batch has no items: $BatchId"
}

$duplicateDestinations = @($items | Group-Object proposed_destination | Where-Object { $_.Count -gt 1 })
if ($duplicateDestinations.Count -gt 0) {
    $first = $duplicateDestinations | Select-Object -First 1
    throw "Batch contains duplicate destination path before moving: $($first.Name)"
}

$checked = [System.Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    if (-not $item.move_eligible) {
        throw "Item is not move eligible: $($item.id)"
    }
    if ($item.kind -ne "file") {
        throw "Refusing non-file item: $($item.id)"
    }
    if ($item.git_root) {
        throw "Refusing git worktree item: $($item.id)"
    }
    if (Test-PathUnder $item.resolved_path "D:\Research") {
        throw "Refusing D:\Research item: $($item.resolved_path)"
    }
    if (-not (Test-Path -LiteralPath $item.path -PathType Leaf)) {
        throw "Source file missing: $($item.path)"
    }
    $sourceInfo = Get-Item -LiteralPath $item.path -Force
    if (($sourceInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing reparse-point source: $($item.path)"
    }
    if (-not (Test-PathUnder $item.proposed_destination $targetRoot)) {
        throw "Destination outside target root: $($item.proposed_destination)"
    }
    if (Test-Path -LiteralPath $item.proposed_destination) {
        throw "Destination already exists: $($item.proposed_destination)"
    }
    $checked.Add([pscustomobject][ordered]@{
        id = $item.id
        source = $item.path
        destination = $item.proposed_destination
        rollback_source = $item.proposed_destination
        rollback_destination = $item.path
        size = $item.size
        category = $item.category
    })
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ($PreflightOnly) {
    $preflightPath = Join-Path $out "workstation-preflight-$BatchId-$stamp.json"
    $preflight = [ordered]@{
        schema_version = "1.0"
        checked_at = (Get-Date).ToString("o")
        move_plan_path = $planFull
        batch_id = $BatchId
        target_root = $targetRoot
        item_count = $checked.Count
        status = "passed"
        moves_executed = $false
        items = $checked
        approved_command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-ApprovedMoveBatch.ps1`" -MovePlanPath `"$planFull`" -BatchId `"$BatchId`" -Approved"
    }
    $preflight | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $preflightPath -Encoding UTF8
    [pscustomobject]@{
        preflight_manifest = $preflightPath
        batch_id = $BatchId
        checked_count = $checked.Count
        status = "passed"
        moves_executed = $false
    } | ConvertTo-Json -Depth 4
    return
}

$moved = [System.Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    $destDir = Split-Path -Parent $item.proposed_destination
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Move-Item -LiteralPath $item.path -Destination $item.proposed_destination
    $moved.Add([pscustomobject][ordered]@{
        id = $item.id
        original_source = $item.path
        moved_destination = $item.proposed_destination
        rollback_source = $item.proposed_destination
        rollback_destination = $item.path
        category = $item.category
        size = $item.size
    })
}

$appliedPath = Join-Path $out "workstation-applied-$BatchId-$stamp.json"
$applied = [ordered]@{
    schema_version = "1.0"
    applied_at = (Get-Date).ToString("o")
    move_plan_path = $planFull
    batch_id = $BatchId
    target_root = $targetRoot
    item_count = $moved.Count
    items = $moved
    rollback_command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"D:\agent-resources\skills\vipin\workstation-maintenance\scripts\Invoke-RollbackBatch.ps1`" -AppliedManifestPath `"$appliedPath`""
}
$applied | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $appliedPath -Encoding UTF8

[pscustomobject]@{
    applied_manifest = $appliedPath
    batch_id = $BatchId
    moved_count = $moved.Count
} | ConvertTo-Json -Depth 4
