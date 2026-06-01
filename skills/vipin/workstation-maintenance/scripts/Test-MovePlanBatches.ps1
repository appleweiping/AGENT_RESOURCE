param(
    [Parameter(Mandatory = $true)]
    [string]$MovePlanPath,
    [string]$OutputDir = "",
    [switch]$StopOnFailure
)

$ErrorActionPreference = "Stop"

function Get-FullPathSafe {
    param([string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) } catch { return $Path }
}

$planFull = Get-FullPathSafe $MovePlanPath
if (-not (Test-Path -LiteralPath $planFull -PathType Leaf)) {
    throw "Move plan not found: $planFull"
}

if (-not $OutputDir) {
    $OutputDir = Split-Path -Parent $planFull
}
$out = Get-FullPathSafe $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

$scriptRoot = Split-Path -Parent $PSCommandPath
$moveScript = Join-Path $scriptRoot "Invoke-ApprovedMoveBatch.ps1"
$plan = Get-Content -LiteralPath $planFull -Raw | ConvertFrom-Json
$batches = @($plan.batches)
if ($batches.Count -eq 0) {
    throw "Move plan contains no batches: $planFull"
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($batch in $batches) {
    $batchId = [string]$batch.batch_id
    try {
        $raw = & $moveScript -MovePlanPath $planFull -BatchId $batchId -PreflightOnly -OutputDir $out
        $preflight = $raw | ConvertFrom-Json
        $results.Add([pscustomobject][ordered]@{
            batch_id = $batchId
            status = [string]$preflight.status
            checked_count = [int]$preflight.checked_count
            moves_executed = [bool]$preflight.moves_executed
            preflight_manifest = [string]$preflight.preflight_manifest
            error = $null
        })
    } catch {
        $results.Add([pscustomobject][ordered]@{
            batch_id = $batchId
            status = "failed"
            checked_count = 0
            moves_executed = $false
            preflight_manifest = $null
            error = $_.Exception.Message
        })
        if ($StopOnFailure) { throw }
    }
}

$failed = @($results | Where-Object { $_.status -ne "passed" })
$moved = @($results | Where-Object { $_.moves_executed })
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryPath = Join-Path $out "workstation-preflight-summary-$stamp.json"
$summary = [ordered]@{
    schema_version = "1.0"
    checked_at = (Get-Date).ToString("o")
    move_plan_path = $planFull
    batch_count = $batches.Count
    passed_count = $batches.Count - $failed.Count
    failed_count = $failed.Count
    checked_item_count = [int](($results | Measure-Object -Property checked_count -Sum).Sum)
    moves_executed = $moved.Count -gt 0
    results = $results
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

[pscustomobject]@{
    preflight_summary = $summaryPath
    batch_count = $batches.Count
    passed_count = $batches.Count - $failed.Count
    failed_count = $failed.Count
    checked_item_count = [int](($results | Measure-Object -Property checked_count -Sum).Sum)
    moves_executed = $moved.Count -gt 0
} | ConvertTo-Json -Depth 4
