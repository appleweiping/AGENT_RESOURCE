param(
    [Parameter(Mandatory = $true)]
    [string]$AppliedManifestPath,
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "WorkstationConfig.ps1")

$manifestFull = Get-FullPathSafe $AppliedManifestPath
if (-not (Test-Path -LiteralPath $manifestFull -PathType Leaf)) {
    throw "Applied manifest not found: $manifestFull"
}

$applied = Get-Content -LiteralPath $manifestFull -Raw | ConvertFrom-Json
$items = @($applied.items)
if ($items.Count -eq 0) {
    throw "Applied manifest has no items."
}

$config = Get-WorkstationConfig -ConfigPath $ConfigPath
$ProtectedRoots = @(@(Get-PlanList $applied "protected_roots") + @($config.protected_roots) | Sort-Object -Unique)

foreach ($item in $items) {
    if (Test-PathUnderAny $item.rollback_destination $ProtectedRoots) {
        throw "Refusing rollback into a protected root: $($item.rollback_destination)"
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
