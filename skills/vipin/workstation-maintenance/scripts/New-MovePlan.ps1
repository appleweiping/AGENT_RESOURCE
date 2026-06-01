param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,
    [string]$OutputDir = "",
    [string]$TargetRoot = "D:\_Organized"
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

function Get-SafeBatchName {
    param([string]$Text)
    return (($Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-') -replace '^-|-$', '')
}

function Format-ByteSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

$manifestFull = Get-FullPathSafe $ManifestPath
if (-not (Test-Path -LiteralPath $manifestFull -PathType Leaf)) {
    throw "Manifest not found: $manifestFull"
}

$manifest = Get-Content -LiteralPath $manifestFull -Raw | ConvertFrom-Json
if (-not $OutputDir) {
    $OutputDir = Split-Path -Parent $manifestFull
}
$out = Get-FullPathSafe $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

$eligible = @($manifest.items | Where-Object { $_.move_eligible -eq $true })
$batches = [System.Collections.Generic.List[object]]::new()

$eligible | Group-Object category | Sort-Object Name | ForEach-Object {
    $category = $_.Name
    $batchItems = @($_.Group | Sort-Object path)
    if ($batchItems.Count -eq 0) { return }
    foreach ($item in $batchItems) {
        if (Test-PathUnder $item.resolved_path "D:\Research") {
            throw "Move plan attempted to include D:\Research item: $($item.resolved_path)"
        }
        if ($item.kind -ne "file") {
            throw "Move plan attempted to include non-file item: $($item.id)"
        }
        if ($item.git_root) {
            throw "Move plan attempted to include git worktree item: $($item.id)"
        }
        if (-not (Test-PathUnder $item.proposed_destination $TargetRoot)) {
            throw "Destination outside target root for $($item.id): $($item.proposed_destination)"
        }
    }
    $batchId = "batch-" + (Get-SafeBatchName $category)
    $destRoots = @($batchItems | ForEach-Object { Split-Path -Parent $_.proposed_destination } | Sort-Object -Unique)
    $totalSize = [long](($batchItems | Measure-Object -Property size -Sum).Sum)
    $batches.Add([pscustomobject][ordered]@{
        batch_id = $batchId
        category = $category
        item_count = $batchItems.Count
        total_size_bytes = $totalSize
        total_size_human = (Format-ByteSize $totalSize)
        risk_tier = "low"
        requires_user_approval = $true
        destination_root = $TargetRoot
        destination_dirs = $destRoots
        item_ids = @($batchItems | ForEach-Object { $_.id })
        items = $batchItems
    })
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $out "workstation-move-plan-$stamp.json"
$mdPath = Join-Path $out "workstation-move-plan-$stamp.md"

$plan = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    manifest_path = $manifestFull
    target_root = $TargetRoot
    batch_count = $batches.Count
    item_count = $eligible.Count
    batches = $batches
}

$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Workstation Move Plan")
$lines.Add("")
$lines.Add("Generated: $((Get-Date).ToString('o'))")
$lines.Add("")
$lines.Add("This plan is not approval. Execute a batch only after the user names the batch ID and the move script is called with `-Approved`.")
$lines.Add("")
$lines.Add("| Batch ID | Category | Items | Size | Destination root |")
$lines.Add("| --- | --- | ---: | ---: | --- |")
foreach ($batch in $batches) {
    $lines.Add("| `$($batch.batch_id)` | $($batch.category) | $($batch.item_count) | $($batch.total_size_human) | `$($batch.destination_root)` |")
}
$lines.Add("")
$lines.Add("## Batch Details")
foreach ($batch in $batches) {
    $lines.Add("")
    $lines.Add("### $($batch.batch_id)")
    $lines.Add("")
    $lines.Add("| ID | Source | Destination |")
    $lines.Add("| --- | --- | --- |")
    foreach ($item in @($batch.items | Select-Object -First 30)) {
        $source = $item.path -replace '\|', '\|'
        $dest = $item.proposed_destination -replace '\|', '\|'
        $lines.Add("| $($item.id) | `$source` | `$dest` |")
    }
    if ($batch.item_count -gt 30) {
        $lines.Add("")
        $lines.Add("Only first 30 items shown for this batch; use JSON for full local list.")
    }
}
$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    move_plan = $jsonPath
    markdown = $mdPath
    batch_count = $batches.Count
    item_count = $eligible.Count
    batches = @($batches | Select-Object batch_id, category, item_count, total_size_human, risk_tier, destination_root)
} | ConvertTo-Json -Depth 4
