param(
    [Parameter(Mandatory = $true)]
    [string]$AppliedManifestPath
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

$manifestFull = Get-FullPathSafe $AppliedManifestPath
if (-not (Test-Path -LiteralPath $manifestFull -PathType Leaf)) {
    throw "Applied manifest not found: $manifestFull"
}

$applied = Get-Content -LiteralPath $manifestFull -Raw | ConvertFrom-Json
$items = @($applied.items)
if ($items.Count -eq 0) {
    throw "Applied manifest has no items."
}

foreach ($item in $items) {
    if (Test-PathUnder $item.rollback_destination "D:\Research") {
        throw "Refusing rollback into D:\Research: $($item.rollback_destination)"
    }
    if (-not (Test-Path -LiteralPath $item.rollback_source -PathType Leaf)) {
        throw "Rollback source missing: $($item.rollback_source)"
    }
    if (Test-Path -LiteralPath $item.rollback_destination) {
        throw "Rollback destination already exists: $($item.rollback_destination)"
    }
}

$rolledBack = [System.Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    $destDir = Split-Path -Parent $item.rollback_destination
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Move-Item -LiteralPath $item.rollback_source -Destination $item.rollback_destination
    $rolledBack.Add([pscustomobject][ordered]@{
        id = $item.id
        restored_to = $item.rollback_destination
    })
}

[pscustomobject]@{
    applied_manifest = $manifestFull
    rolled_back_count = $rolledBack.Count
    items = $rolledBack
} | ConvertTo-Json -Depth 4
