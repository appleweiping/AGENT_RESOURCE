$ErrorActionPreference = "Stop"

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$inventoryScript = Join-Path $skillRoot "scripts\New-WorkstationInventory.ps1"
$movePlanScript = Join-Path $skillRoot "scripts\New-MovePlan.ps1"
$moveScript = Join-Path $skillRoot "scripts\Invoke-ApprovedMoveBatch.ps1"
$rollbackScript = Join-Path $skillRoot "scripts\Invoke-RollbackBatch.ps1"
$allPreflightScript = Join-Path $skillRoot "scripts\Test-MovePlanBatches.ps1"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$root = Join-Path ([IO.Path]::GetTempPath()) ("wm-fixture-" + [guid]::NewGuid().ToString("N"))
$target = Join-Path ([IO.Path]::GetTempPath()) ("wm-target-" + [guid]::NewGuid().ToString("N"))
$out = Join-Path $root "out"

try {
    New-Item -ItemType Directory -Force -Path $root, $target, $out | Out-Null
    $downloads = Join-Path $root "Downloads"
    $repo = Join-Path $root "repo"
    $tmp = Join-Path $root "tmp"
    New-Item -ItemType Directory -Force -Path $downloads, $repo, $tmp, (Join-Path $repo ".git") | Out-Null
    Set-Content -LiteralPath (Join-Path $downloads "paper.pdf") -Value "pdf"
    Set-Content -LiteralPath (Join-Path $downloads "image.jpg") -Value "jpg"
    Set-Content -LiteralPath (Join-Path $downloads "bank-private.pdf") -Value "private"
    Set-Content -LiteralPath (Join-Path $repo "active.txt") -Value "repo"
    Set-Content -LiteralPath (Join-Path $tmp "cache.tmp") -Value "tmp"

    $inventoryRaw = & $inventoryScript -Roots @($root, "D:\Research") -OutputDir $out -TargetRoot $target -Mode Fixture
    $inventoryResult = $inventoryRaw | ConvertFrom-Json
    $manifestPath = [string]$inventoryResult.manifest
    Assert-True (Test-Path -LiteralPath $manifestPath -PathType Leaf) "Inventory manifest was not created."

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Assert-True (@($manifest.items | Where-Object { $_.resolved_path -like "D:\Research*" -or $_.path -like "D:\Research*" }).Count -eq 0) "D:\Research appeared in manifest."
    Assert-True (@($manifest.items | Where-Object { $_.move_eligible -and $_.kind -eq "reparse" }).Count -eq 0) "Reparse item was move eligible."
    Assert-True (@($manifest.items | Where-Object { $_.move_eligible -and $_.git_root }).Count -eq 0) "Git worktree item was move eligible."
    Assert-True (@($manifest.items | Where-Object { $_.category -eq "PersonalSensitive" }).Count -ge 1) "Sensitive file was not classified."

    $planRaw = & $movePlanScript -ManifestPath $manifestPath -TargetRoot $target
    $planResult = $planRaw | ConvertFrom-Json
    $planPath = [string]$planResult.move_plan
    Assert-True (Test-Path -LiteralPath $planPath -PathType Leaf) "Move plan was not created."
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    $testBatchId = [string](@($plan.batches | Select-Object -First 1).batch_id)
    Assert-True ([bool]$testBatchId) "Move plan did not contain a batch ID."

    $failedWithoutApproval = $false
    try {
        & $moveScript -MovePlanPath $planPath -BatchId $testBatchId
    } catch {
        $failedWithoutApproval = $true
    }
    Assert-True $failedWithoutApproval "Move script ran without approval."

    $preflightRaw = & $moveScript -MovePlanPath $planPath -BatchId $testBatchId -PreflightOnly
    $preflightResult = $preflightRaw | ConvertFrom-Json
    Assert-True ($preflightResult.status -eq "passed") "Preflight did not pass."
    Assert-True (-not $preflightResult.moves_executed) "Preflight unexpectedly executed moves."
    Assert-True (Test-Path -LiteralPath $preflightResult.preflight_manifest -PathType Leaf) "Preflight manifest was not created."
    Assert-True (Test-Path -LiteralPath (Join-Path $downloads "paper.pdf") -PathType Leaf) "Preflight moved source file."

    $allPreflightRaw = & $allPreflightScript -MovePlanPath $planPath
    $allPreflightResult = $allPreflightRaw | ConvertFrom-Json
    Assert-True ($allPreflightResult.failed_count -eq 0) "All-batch preflight reported failures."
    Assert-True ($allPreflightResult.batch_count -ge 1) "All-batch preflight did not check batches."
    Assert-True (-not $allPreflightResult.moves_executed) "All-batch preflight unexpectedly executed moves."
    Assert-True (Test-Path -LiteralPath $allPreflightResult.preflight_summary -PathType Leaf) "All-batch preflight summary was not created."

    $appliedRaw = & $moveScript -MovePlanPath $planPath -BatchId $testBatchId -Approved
    $appliedResult = $appliedRaw | ConvertFrom-Json
    Assert-True ($appliedResult.moved_count -ge 1) "Approved batch did not move items."
    Assert-True (Test-Path -LiteralPath $appliedResult.applied_manifest -PathType Leaf) "Applied manifest was not created."

    $rollbackRaw = & $rollbackScript -AppliedManifestPath ([string]$appliedResult.applied_manifest)
    $rollbackResult = $rollbackRaw | ConvertFrom-Json
    Assert-True ($rollbackResult.rolled_back_count -eq $appliedResult.moved_count) "Rollback count did not match moved count."
    Assert-True (Test-Path -LiteralPath (Join-Path $downloads "paper.pdf") -PathType Leaf) "Rollback did not restore source file."

    [pscustomobject]@{
        ok = $true
        fixture_root = $root
        target_root = $target
    } | ConvertTo-Json -Depth 4
} finally {
    foreach ($path in @($root, $target)) {
        if (Test-Path -LiteralPath $path) {
            $resolved = Resolve-Path -LiteralPath $path
            $tempRoot = [IO.Path]::GetTempPath()
            if ($resolved.Path.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                Remove-Item -LiteralPath $resolved.Path -Recurse -Force
            }
        }
    }
}
