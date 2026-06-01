$ErrorActionPreference = "Stop"

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$inventoryScript = Join-Path $skillRoot "scripts\New-WorkstationInventory.ps1"
$movePlanScript = Join-Path $skillRoot "scripts\New-MovePlan.ps1"
$moveScript = Join-Path $skillRoot "scripts\Invoke-ApprovedMoveBatch.ps1"
$rollbackScript = Join-Path $skillRoot "scripts\Invoke-RollbackBatch.ps1"
$allPreflightScript = Join-Path $skillRoot "scripts\Test-MovePlanBatches.ps1"
$approvalPacketScript = Join-Path $skillRoot "scripts\New-ApprovalPacket.ps1"
$driveRootPlanScript = Join-Path $skillRoot "scripts\New-DriveRootOrganizationPlan.ps1"
$driveRootInvokeScript = Join-Path $skillRoot "scripts\Invoke-DriveRootOrganizationPlan.ps1"

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

    $packetRaw = & $approvalPacketScript -MovePlanPath $planPath -PreflightSummaryPath $allPreflightResult.preflight_summary
    $packetResult = $packetRaw | ConvertFrom-Json
    Assert-True (Test-Path -LiteralPath $packetResult.approval_packet -PathType Leaf) "Approval packet markdown was not created."
    Assert-True (Test-Path -LiteralPath $packetResult.approval_summary -PathType Leaf) "Approval packet JSON summary was not created."
    Assert-True ($packetResult.research_hits -eq 0) "Approval packet found Research hits."
    Assert-True (-not $packetResult.moves_executed) "Approval packet unexpectedly executed moves."

    $appliedRaw = & $moveScript -MovePlanPath $planPath -BatchId $testBatchId -Approved
    $appliedResult = $appliedRaw | ConvertFrom-Json
    Assert-True ($appliedResult.moved_count -ge 1) "Approved batch did not move items."
    Assert-True (Test-Path -LiteralPath $appliedResult.applied_manifest -PathType Leaf) "Applied manifest was not created."

    $rollbackRaw = & $rollbackScript -AppliedManifestPath ([string]$appliedResult.applied_manifest)
    $rollbackResult = $rollbackRaw | ConvertFrom-Json
    Assert-True ($rollbackResult.rolled_back_count -eq $appliedResult.moved_count) "Rollback count did not match moved count."
    Assert-True (Test-Path -LiteralPath (Join-Path $downloads "paper.pdf") -PathType Leaf) "Rollback did not restore source file."

    $driveRoot = Join-Path $root "drive-root"
    $driveTarget = Join-Path $driveRoot "_Organized"
    $driveDownloads = Join-Path $driveRoot "360Downloads"
    $driveResearch = Join-Path $driveRoot "Research"
    $driveDevtools = Join-Path $driveRoot "devtools"
    New-Item -ItemType Directory -Force -Path $driveRoot, $driveDownloads, $driveResearch, $driveDevtools | Out-Null
    Set-Content -LiteralPath (Join-Path $driveDownloads "download.txt") -Value "download"
    Set-Content -LiteralPath (Join-Path $driveResearch "research.txt") -Value "research"
    Set-Content -LiteralPath (Join-Path $driveDevtools "tool.txt") -Value "tool"

    $drivePlanRaw = & $driveRootPlanScript -DriveRoot $driveRoot -TargetRoot $driveTarget -OutputDir $out
    $drivePlanResult = $drivePlanRaw | ConvertFrom-Json
    $drivePlanPath = [string]$drivePlanResult.plan
    Assert-True (Test-Path -LiteralPath $drivePlanPath -PathType Leaf) "Drive-root plan was not created."
    Assert-True ($drivePlanResult.move_count -eq 1) "Drive-root plan should only move the download fixture."

    $drivePlan = Get-Content -LiteralPath $drivePlanPath -Raw | ConvertFrom-Json
    Assert-True (@($drivePlan.items | Where-Object { $_.name -eq "Research" -and $_.action -eq "record-only" }).Count -eq 1) "Drive-root plan did not protect Research."
    Assert-True (@($drivePlan.items | Where-Object { $_.name -eq "devtools" -and $_.action -eq "record-only" }).Count -eq 1) "Drive-root plan did not protect devtools."

    $driveFailedWithoutApproval = $false
    try {
        & $driveRootInvokeScript -PlanPath $drivePlanPath
    } catch {
        $driveFailedWithoutApproval = $true
    }
    Assert-True $driveFailedWithoutApproval "Drive-root invoke ran without approval."

    $drivePreflightRaw = & $driveRootInvokeScript -PlanPath $drivePlanPath -PreflightOnly
    $drivePreflightResult = $drivePreflightRaw | ConvertFrom-Json
    Assert-True ($drivePreflightResult.preflight_ok) "Drive-root preflight did not pass."
    Assert-True ($drivePreflightResult.checked_count -eq 1) "Drive-root preflight checked the wrong count."

    $driveAppliedRaw = & $driveRootInvokeScript -PlanPath $drivePlanPath -Approved
    $driveAppliedResult = $driveAppliedRaw | ConvertFrom-Json
    Assert-True ($driveAppliedResult.moved_count -eq 1) "Drive-root approved move did not report one moved item."
    Assert-True (Test-Path -LiteralPath $driveAppliedResult.applied_manifest -PathType Leaf) "Drive-root applied manifest was not created."
    $downloadItem = Get-Item -LiteralPath $driveDownloads -Force
    Assert-True ((($downloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) "Drive-root source was not converted to a junction."
    Assert-True (Test-Path -LiteralPath (Join-Path $driveTarget "Downloads\_RootDirs\360Downloads\download.txt") -PathType Leaf) "Drive-root target file missing."

    $driveRollbackRaw = & $driveRootInvokeScript -PlanPath $drivePlanPath -RollbackManifestPath ([string]$driveAppliedResult.applied_manifest)
    $driveRollbackResult = $driveRollbackRaw | ConvertFrom-Json
    Assert-True ($driveRollbackResult.rolled_back_count -eq 1) "Drive-root rollback count did not match."
    $rolledBackDownloadItem = Get-Item -LiteralPath $driveDownloads -Force
    Assert-True ((($rolledBackDownloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0)) "Drive-root rollback left a junction behind."
    Assert-True (Test-Path -LiteralPath (Join-Path $driveDownloads "download.txt") -PathType Leaf) "Drive-root rollback did not restore source file."

    $tampered = Get-Content -LiteralPath $drivePlanPath -Raw | ConvertFrom-Json
    $moveItem = @($tampered.items | Where-Object { $_.action -eq "move-with-junction" } | Select-Object -First 1)[0]
    $moveItem.id = "dr_bad_devtools"
    $moveItem.name = "devtools"
    $moveItem.source_path = $driveDevtools
    $moveItem.target_path = Join-Path $driveTarget "Tools-Review\_RootDirs\devtools"
    $moveItem.junction_path = $driveDevtools
    $tamperedPath = Join-Path $out "tampered-protected-root-plan.json"
    $tampered | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tamperedPath -Encoding UTF8
    $protectedRejected = $false
    try {
        & $driveRootInvokeScript -PlanPath $tamperedPath -PreflightOnly
    } catch {
        $protectedRejected = $true
    }
    Assert-True $protectedRejected "Drive-root preflight accepted a tampered protected root plan."

    $partialRoot = Join-Path $root "partial-drive-root"
    $partialTarget = Join-Path $partialRoot "_Organized"
    $partialDownloads = Join-Path $partialRoot "360Downloads"
    New-Item -ItemType Directory -Force -Path $partialRoot, $partialDownloads | Out-Null
    Set-Content -LiteralPath (Join-Path $partialDownloads "partial.txt") -Value "partial"
    $partialPlanPath = [string]((& $driveRootPlanScript -DriveRoot $partialRoot -TargetRoot $partialTarget -OutputDir $out | ConvertFrom-Json).plan)
    $partialPlan = Get-Content -LiteralPath $partialPlanPath -Raw | ConvertFrom-Json
    $partialItem = @($partialPlan.items | Where-Object { $_.action -eq "move-with-junction" } | Select-Object -First 1)[0]
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $partialItem.target_path) | Out-Null
    [System.IO.Directory]::Move($partialItem.source_path, $partialItem.target_path)
    Assert-True (-not (Test-Path -LiteralPath $partialItem.source_path)) "Partial fixture source still exists before repair."
    $partialApplied = & $driveRootInvokeScript -PlanPath $partialPlanPath -Approved | ConvertFrom-Json
    Assert-True ($partialApplied.moved_count -eq 1) "Partial repair did not produce one applied item."
    $partialSource = Get-Item -LiteralPath $partialItem.source_path -Force
    Assert-True ((($partialSource.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) "Partial repair did not recreate source junction."
    $partialAppliedManifest = Get-Content -LiteralPath $partialApplied.applied_manifest -Raw | ConvertFrom-Json
    Assert-True ([bool](@($partialAppliedManifest.items)[0].repaired_missing_junction)) "Partial repair was not recorded in applied manifest."

    $mismatchRoot = Join-Path $root "mismatch-drive-root"
    $mismatchTarget = Join-Path $mismatchRoot "_Organized"
    $mismatchDownloads = Join-Path $mismatchRoot "360Downloads"
    $wrongTarget = Join-Path $mismatchRoot "wrong-target"
    New-Item -ItemType Directory -Force -Path $mismatchRoot, $mismatchDownloads, $wrongTarget | Out-Null
    Set-Content -LiteralPath (Join-Path $mismatchDownloads "mismatch.txt") -Value "mismatch"
    $mismatchPlanPath = [string]((& $driveRootPlanScript -DriveRoot $mismatchRoot -TargetRoot $mismatchTarget -OutputDir $out | ConvertFrom-Json).plan)
    $mismatchPlan = Get-Content -LiteralPath $mismatchPlanPath -Raw | ConvertFrom-Json
    $mismatchItem = @($mismatchPlan.items | Where-Object { $_.action -eq "move-with-junction" } | Select-Object -First 1)[0]
    New-Item -ItemType Directory -Force -Path $mismatchItem.target_path | Out-Null
    Remove-Item -LiteralPath $mismatchDownloads -Recurse -Force
    New-Item -ItemType Junction -Path $mismatchDownloads -Target $wrongTarget | Out-Null
    $mismatchRejected = $false
    try {
        & $driveRootInvokeScript -PlanPath $mismatchPlanPath -PreflightOnly
    } catch {
        $mismatchRejected = $true
    }
    Assert-True $mismatchRejected "Drive-root preflight accepted a mismatched existing junction."

    $rollbackMismatchRoot = Join-Path $root "rollback-mismatch-drive-root"
    $rollbackMismatchTarget = Join-Path $rollbackMismatchRoot "_Organized"
    $rollbackMismatchSource = Join-Path $rollbackMismatchRoot "360Downloads"
    $rollbackMismatchMoved = Join-Path $rollbackMismatchTarget "Downloads\_RootDirs\360Downloads"
    $rollbackWrongTarget = Join-Path $rollbackMismatchRoot "wrong-target"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $rollbackMismatchMoved), $rollbackMismatchMoved, $rollbackWrongTarget | Out-Null
    Set-Content -LiteralPath (Join-Path $rollbackMismatchMoved "rollback.txt") -Value "rollback"
    New-Item -ItemType Junction -Path $rollbackMismatchSource -Target $rollbackWrongTarget | Out-Null
    $badAppliedPath = Join-Path $out "tampered-rollback-mismatch-applied.json"
    [ordered]@{
        schema_version = "1.0"
        applied_at = (Get-Date).ToString("o")
        plan_path = $drivePlanPath
        drive_root = $rollbackMismatchRoot.TrimEnd('\') + "\"
        target_root = $rollbackMismatchTarget
        moved_count = 1
        items = @([ordered]@{
            id = "dr_bad_rollback"
            name = "360Downloads"
            original_source = $rollbackMismatchSource
            moved_destination = $rollbackMismatchMoved
            junction_path = $rollbackMismatchSource
            category = "Downloads"
            reason = "test"
        })
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $badAppliedPath -Encoding UTF8
    $rollbackMismatchRejected = $false
    try {
        & $driveRootInvokeScript -PlanPath $drivePlanPath -RollbackManifestPath $badAppliedPath
    } catch {
        $rollbackMismatchRejected = $true
    }
    Assert-True $rollbackMismatchRejected "Drive-root rollback accepted a mismatched source junction."
    Assert-True (Test-Path -LiteralPath $rollbackMismatchSource) "Rollback mismatch test deleted the source junction."

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
