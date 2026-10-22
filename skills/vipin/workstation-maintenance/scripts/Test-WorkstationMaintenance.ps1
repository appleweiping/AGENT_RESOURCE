# Self-test on throwaway folders under %TEMP%. Builds a fixture tree and a
# fixture config, then runs every script against it. Prints "ok": true.
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

function Assert-Throws {
    param([scriptblock]$Block, [string]$Message)
    $threw = $false
    try { & $Block | Out-Null } catch { $threw = $true }
    Assert-True $threw $Message
}

$root = Join-Path ([IO.Path]::GetTempPath()) ("wm-fixture-" + [guid]::NewGuid().ToString("N"))
$target = Join-Path ([IO.Path]::GetTempPath()) ("wm-target-" + [guid]::NewGuid().ToString("N"))
$out = Join-Path $root "out"

try {
    New-Item -ItemType Directory -Force -Path $root, $target, $out | Out-Null

    # File-level fixture.
    $downloads = Join-Path $root "Downloads"
    $repo = Join-Path $root "repo"
    $tmp = Join-Path $root "tmp"
    $private = Join-Path $root "private"
    New-Item -ItemType Directory -Force -Path $downloads, $repo, $tmp, $private, (Join-Path $repo ".git") | Out-Null
    Set-Content -LiteralPath (Join-Path $downloads "paper.pdf") -Value "pdf"
    Set-Content -LiteralPath (Join-Path $downloads "image.jpg") -Value "jpg"
    Set-Content -LiteralPath (Join-Path $downloads "bank-private.pdf") -Value "private"
    Set-Content -LiteralPath (Join-Path $repo "active.txt") -Value "repo"
    Set-Content -LiteralPath (Join-Path $tmp "cache.tmp") -Value "tmp"
    Set-Content -LiteralPath (Join-Path $private "notes.zip") -Value "never listed"

    # Drive-root fixture.
    $driveRoot = Join-Path $root "drive-root"
    $driveTarget = Join-Path $driveRoot "_Organized"
    $driveDownloads = Join-Path $driveRoot "360Downloads"
    $driveCourses = Join-Path $driveRoot "old-courses"
    $driveProtected = Join-Path $driveRoot "Private"
    $driveTools = Join-Path $driveRoot "tools"
    $driveSkills = Join-Path $driveRoot "agent-skills"
    $driveProject = Join-Path $driveRoot "Projects"
    $driveArchive = Join-Path $driveRoot "Archive"
    $driveNestedProtected = Join-Path $driveArchive "taxes"
    New-Item -ItemType Directory -Force -Path $driveRoot, $driveDownloads, $driveCourses, $driveProtected, $driveTools, $driveSkills, $driveProject, $driveNestedProtected | Out-Null
    Set-Content -LiteralPath (Join-Path $driveDownloads "download.txt") -Value "download"
    Set-Content -LiteralPath (Join-Path $driveCourses "week1.txt") -Value "course"
    Set-Content -LiteralPath (Join-Path $driveProtected "private.txt") -Value "private"
    Set-Content -LiteralPath (Join-Path $driveTools "tool.txt") -Value "tool"
    Set-Content -LiteralPath (Join-Path $driveSkills "skills.txt") -Value "skills"
    Set-Content -LiteralPath (Join-Path $driveProject "project.txt") -Value "project"
    Set-Content -LiteralPath (Join-Path $driveNestedProtected "2024.txt") -Value "taxes"

    $configPath = Join-Path $root "config.json"
    [ordered]@{
        protected_roots = @($private, $driveProtected, $driveNestedProtected)
        infrastructure_roots = @($driveTools, $driveSkills)
        project_roots = @($driveProject)
        organized_root = $target
        drive_root_rules = @(@{ pattern = "^old-courses$"; category = "Coursework" })
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding UTF8

    Assert-Throws { & $inventoryScript -Roots @($root) -OutputDir $out -ConfigPath (Join-Path $root "missing.json") } "Inventory ran with a missing config file."

    $inventoryRaw = & $inventoryScript -Roots @($root, $private) -OutputDir $out -ConfigPath $configPath -Mode Fixture
    $inventoryResult = $inventoryRaw | ConvertFrom-Json
    $manifestPath = [string]$inventoryResult.manifest
    Assert-True (Test-Path -LiteralPath $manifestPath -PathType Leaf) "Inventory manifest was not created."

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Assert-True ([string]$manifest.target_root -eq $target) "Inventory did not take organized_root from the config."
    Assert-True (@($manifest.items | Where-Object { $_.resolved_path -like "$private*" -or $_.path -like "$private*" }).Count -eq 0) "A protected root appeared in the manifest."
    Assert-True (@($manifest.protected_roots).Count -eq 3) "Manifest did not record the protected roots."
    Assert-True (@($manifest.items | Where-Object { $_.move_eligible -and $_.kind -eq "reparse" }).Count -eq 0) "Reparse item was move eligible."
    Assert-True (@($manifest.items | Where-Object { $_.move_eligible -and $_.git_root }).Count -eq 0) "Git worktree item was move eligible."
    Assert-True (@($manifest.items | Where-Object { $_.category -eq "PersonalSensitive" }).Count -ge 1) "Sensitive file was not classified."

    $planRaw = & $movePlanScript -ManifestPath $manifestPath
    $planResult = $planRaw | ConvertFrom-Json
    $planPath = [string]$planResult.move_plan
    Assert-True (Test-Path -LiteralPath $planPath -PathType Leaf) "Move plan was not created."
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    $testBatchId = [string](@($plan.batches | Select-Object -First 1).batch_id)
    Assert-True ([bool]$testBatchId) "Move plan did not contain a batch ID."

    Assert-Throws { & $moveScript -MovePlanPath $planPath -BatchId $testBatchId } "Move script ran without approval."

    # A plan edited to take a file from a protected root (and to forget its
    # protected_roots) must still be refused, because the config is checked too.
    $tamperedMove = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    $tamperedItem = @(@($tamperedMove.batches)[0].items)[0]
    $tamperedItem.path = Join-Path $private "notes.zip"
    $tamperedItem.resolved_path = $tamperedItem.path
    $tamperedMove.protected_roots = @()
    $tamperedMovePath = Join-Path $out "tampered-move-plan.json"
    $tamperedMove | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tamperedMovePath -Encoding UTF8
    Assert-Throws { & $moveScript -MovePlanPath $tamperedMovePath -BatchId $testBatchId -PreflightOnly -ConfigPath $configPath } "Move preflight accepted a source inside a protected root."

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
    Assert-True ($packetResult.protected_hits -eq 0) "Approval packet found protected-root hits."
    Assert-True (-not $packetResult.moves_executed) "Approval packet unexpectedly executed moves."

    $appliedRaw = & $moveScript -MovePlanPath $planPath -BatchId $testBatchId -Approved
    $appliedResult = $appliedRaw | ConvertFrom-Json
    Assert-True ($appliedResult.moved_count -ge 1) "Approved batch did not move items."
    Assert-True (Test-Path -LiteralPath $appliedResult.applied_manifest -PathType Leaf) "Applied manifest was not created."

    $rollbackRaw = & $rollbackScript -AppliedManifestPath ([string]$appliedResult.applied_manifest)
    $rollbackResult = $rollbackRaw | ConvertFrom-Json
    Assert-True ($rollbackResult.rolled_back_count -eq $appliedResult.moved_count) "Rollback count did not match moved count."
    Assert-True (Test-Path -LiteralPath (Join-Path $downloads "paper.pdf") -PathType Leaf) "Rollback did not restore source file."

    $drivePlanRaw = & $driveRootPlanScript -DriveRoot $driveRoot -OutputDir $out -ConfigPath $configPath
    $drivePlanResult = $drivePlanRaw | ConvertFrom-Json
    $drivePlanPath = [string]$drivePlanResult.plan
    Assert-True (Test-Path -LiteralPath $drivePlanPath -PathType Leaf) "Drive-root plan was not created."
    Assert-True ($drivePlanResult.move_count -eq 2) "Drive-root plan should move only the download and coursework fixtures."

    $drivePlan = Get-Content -LiteralPath $drivePlanPath -Raw | ConvertFrom-Json
    foreach ($name in @("Private", "tools", "agent-skills", "Projects", "Archive")) {
        Assert-True (@($drivePlan.items | Where-Object { $_.name -eq $name -and $_.action -eq "record-only" }).Count -eq 1) "Drive-root plan did not keep $name in place."
    }
    Assert-True (@($drivePlan.items | Where-Object { $_.name -eq "old-courses" -and $_.category -eq "Coursework" }).Count -eq 1) "Drive-root plan ignored the config rule."

    Assert-Throws { & $driveRootInvokeScript -PlanPath $drivePlanPath -ConfigPath $configPath } "Drive-root invoke ran without approval."

    $drivePreflightRaw = & $driveRootInvokeScript -PlanPath $drivePlanPath -PreflightOnly -ConfigPath $configPath
    $drivePreflightResult = $drivePreflightRaw | ConvertFrom-Json
    Assert-True ($drivePreflightResult.preflight_ok) "Drive-root preflight did not pass."
    Assert-True ($drivePreflightResult.checked_count -eq 2) "Drive-root preflight checked the wrong count."

    $driveAppliedRaw = & $driveRootInvokeScript -PlanPath $drivePlanPath -Approved -ConfigPath $configPath
    $driveAppliedResult = $driveAppliedRaw | ConvertFrom-Json
    Assert-True ($driveAppliedResult.moved_count -eq 2) "Drive-root approved move did not report two moved items."
    Assert-True (Test-Path -LiteralPath $driveAppliedResult.applied_manifest -PathType Leaf) "Drive-root applied manifest was not created."
    $downloadItem = Get-Item -LiteralPath $driveDownloads -Force
    Assert-True ((($downloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) "Drive-root source was not converted to a junction."
    Assert-True (Test-Path -LiteralPath (Join-Path $driveTarget "Downloads\_RootDirs\360Downloads\download.txt") -PathType Leaf) "Drive-root target file missing."
    Assert-True (Test-Path -LiteralPath (Join-Path $driveCourses "week1.txt") -PathType Leaf) "Old path does not resolve through the junction."

    $driveRollbackRaw = & $driveRootInvokeScript -PlanPath $drivePlanPath -RollbackManifestPath ([string]$driveAppliedResult.applied_manifest) -ConfigPath $configPath
    $driveRollbackResult = $driveRollbackRaw | ConvertFrom-Json
    Assert-True ($driveRollbackResult.rolled_back_count -eq 2) "Drive-root rollback count did not match."
    $rolledBackDownloadItem = Get-Item -LiteralPath $driveDownloads -Force
    Assert-True ((($rolledBackDownloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0)) "Drive-root rollback left a junction behind."
    Assert-True (Test-Path -LiteralPath (Join-Path $driveDownloads "download.txt") -PathType Leaf) "Drive-root rollback did not restore source file."

    # Hand-edited plans that try to move a folder the config keeps in place.
    $tamperCases = @(
        @{ name = "tools"; source = $driveTools; clearRoots = $false },
        @{ name = "Archive"; source = $driveArchive; clearRoots = $false },
        @{ name = "Private"; source = $driveProtected; clearRoots = $true }
    )
    foreach ($case in $tamperCases) {
        $tampered = Get-Content -LiteralPath $drivePlanPath -Raw | ConvertFrom-Json
        $moveItem = @($tampered.items | Where-Object { $_.action -eq "move-with-junction" } | Select-Object -First 1)[0]
        $moveItem.id = "dr_bad_$($case.name)"
        $moveItem.name = $case.name
        $moveItem.source_path = $case.source
        $moveItem.target_path = Join-Path $driveTarget "Tools-Review\_RootDirs\$($case.name)"
        $moveItem.junction_path = $case.source
        if ($case.clearRoots) {
            $tampered.protected_roots = @()
            $tampered.infrastructure_roots = @()
            $tampered.project_roots = @()
        }
        $tamperedPath = Join-Path $out "tampered-$($case.name)-plan.json"
        $tampered | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tamperedPath -Encoding UTF8
        Assert-Throws { & $driveRootInvokeScript -PlanPath $tamperedPath -PreflightOnly -ConfigPath $configPath } "Drive-root preflight accepted a tampered plan that moves $($case.name)."
    }

    $partialRoot = Join-Path $root "partial-drive-root"
    $partialDownloads = Join-Path $partialRoot "360Downloads"
    New-Item -ItemType Directory -Force -Path $partialRoot, $partialDownloads | Out-Null
    Set-Content -LiteralPath (Join-Path $partialDownloads "partial.txt") -Value "partial"
    $partialPlanPath = [string]((& $driveRootPlanScript -DriveRoot $partialRoot -OutputDir $out -ConfigPath $configPath | ConvertFrom-Json).plan)
    $partialPlan = Get-Content -LiteralPath $partialPlanPath -Raw | ConvertFrom-Json
    $partialItem = @($partialPlan.items | Where-Object { $_.action -eq "move-with-junction" } | Select-Object -First 1)[0]
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $partialItem.target_path) | Out-Null
    [System.IO.Directory]::Move($partialItem.source_path, $partialItem.target_path)
    Assert-True (-not (Test-Path -LiteralPath $partialItem.source_path)) "Partial fixture source still exists before repair."
    $partialApplied = & $driveRootInvokeScript -PlanPath $partialPlanPath -Approved -ConfigPath $configPath | ConvertFrom-Json
    Assert-True ($partialApplied.moved_count -eq 1) "Partial repair did not produce one applied item."
    $partialSource = Get-Item -LiteralPath $partialItem.source_path -Force
    Assert-True ((($partialSource.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) "Partial repair did not recreate source junction."
    $partialAppliedManifest = Get-Content -LiteralPath $partialApplied.applied_manifest -Raw | ConvertFrom-Json
    Assert-True ([bool](@($partialAppliedManifest.items)[0].repaired_missing_junction)) "Partial repair was not recorded in applied manifest."

    $mismatchRoot = Join-Path $root "mismatch-drive-root"
    $mismatchDownloads = Join-Path $mismatchRoot "360Downloads"
    $wrongTarget = Join-Path $mismatchRoot "wrong-target"
    New-Item -ItemType Directory -Force -Path $mismatchRoot, $mismatchDownloads, $wrongTarget | Out-Null
    Set-Content -LiteralPath (Join-Path $mismatchDownloads "mismatch.txt") -Value "mismatch"
    $mismatchPlanPath = [string]((& $driveRootPlanScript -DriveRoot $mismatchRoot -OutputDir $out -ConfigPath $configPath | ConvertFrom-Json).plan)
    $mismatchPlan = Get-Content -LiteralPath $mismatchPlanPath -Raw | ConvertFrom-Json
    $mismatchItem = @($mismatchPlan.items | Where-Object { $_.action -eq "move-with-junction" } | Select-Object -First 1)[0]
    New-Item -ItemType Directory -Force -Path $mismatchItem.target_path | Out-Null
    Remove-Item -LiteralPath $mismatchDownloads -Recurse -Force
    New-Item -ItemType Junction -Path $mismatchDownloads -Target $wrongTarget | Out-Null
    Assert-Throws { & $driveRootInvokeScript -PlanPath $mismatchPlanPath -PreflightOnly -ConfigPath $configPath } "Drive-root preflight accepted a mismatched existing junction."

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
    Assert-Throws { & $driveRootInvokeScript -PlanPath $drivePlanPath -RollbackManifestPath $badAppliedPath -ConfigPath $configPath } "Drive-root rollback accepted a mismatched source junction."
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
