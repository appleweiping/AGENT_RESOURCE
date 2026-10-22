param(
    [Parameter(Mandatory = $true)]
    [string]$MovePlanPath,
    [string]$PreflightSummaryPath = "",
    [string]$OutputDir = "",
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "WorkstationConfig.ps1")

function Format-ByteSize {
    param([double]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "{0:N0} B" -f $Bytes
}

function Escape-MarkdownCell {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Replace("|", "\|").Replace([string][char]96, "'")
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

$plan = Get-Content -LiteralPath $planFull -Raw | ConvertFrom-Json
$batches = @($plan.batches)
if ($batches.Count -eq 0) {
    throw "Move plan contains no batches: $planFull"
}

if (-not $PreflightSummaryPath) {
    $latestSummary = Get-ChildItem -LiteralPath $out -Filter "workstation-preflight-summary-*.json" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latestSummary) {
        $PreflightSummaryPath = $latestSummary.FullName
    }
}

$preflight = $null
if ($PreflightSummaryPath) {
    $preflightFull = Get-FullPathSafe $PreflightSummaryPath
    if (Test-Path -LiteralPath $preflightFull -PathType Leaf) {
        $preflight = Get-Content -LiteralPath $preflightFull -Raw | ConvertFrom-Json
        $PreflightSummaryPath = $preflightFull
    } else {
        throw "Preflight summary not found: $preflightFull"
    }
}

$config = Get-WorkstationConfig -ConfigPath $ConfigPath
$ProtectedRoots = @(@(Get-PlanList $plan "protected_roots") + @($config.protected_roots) | Sort-Object -Unique)
$items = @($batches | ForEach-Object { @($_.items) })
$protectedHits = @($items | Where-Object {
    (Test-PathUnderAny ([string]$_.path) $ProtectedRoots) -or
    (Test-PathUnderAny ([string]$_.resolved_path) $ProtectedRoots)
}).Count
$reparseHits = @($items | Where-Object { ([string]$_.attributes) -match "ReparsePoint" -or $_.kind -eq "reparse" }).Count
$directoryHits = @($items | Where-Object { $_.kind -eq "directory" }).Count
$gitHits = @($items | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.git_root) }).Count
$recentHits = @($items | Where-Object {
    if (-not $_.mtime) {
        $false
    } else {
        $mtime = [DateTimeOffset]::Parse([string]$_.mtime)
        $ageDays = ((Get-Date) - $mtime.LocalDateTime).TotalDays
        $minAge = [double]($_.minimum_age_days)
        if (-not $minAge -and $plan.minimum_age_days) { $minAge = [double]$plan.minimum_age_days }
        $ageDays -lt $minAge
    }
}).Count

$totalSizeBytes = [double](($batches | Measure-Object -Property total_size_bytes -Sum).Sum)
$batchRows = foreach ($batch in $batches) {
    [pscustomobject][ordered]@{
        batch_id = [string]$batch.batch_id
        bucket = ("{0}/{1}" -f $batch.category, $batch.subcategory)
        part = ("{0}/{1}" -f $batch.part_index, $batch.part_count)
        item_count = [int]$batch.item_count
        total_size = [string]$batch.total_size_human
        risk_tier = [string]$batch.risk_tier
        minimum_age_days = [int]$batch.minimum_age_days
        destination_root = [string]$batch.destination_root
    }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$packetPath = Join-Path $out "workstation-approval-packet-$stamp.md"
$summaryPath = Join-Path $out "workstation-approval-packet-$stamp.json"

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Workstation Move Approval Packet")
$lines.Add("")
$lines.Add("Generated: $((Get-Date).ToString('o'))")
$lines.Add("")
$lines.Add("Move plan: ``$planFull``")
if ($preflight) {
    $lines.Add("Preflight summary: ``$PreflightSummaryPath``")
} else {
    $lines.Add("Preflight summary: not attached")
}
$lines.Add("")
$lines.Add("This packet is public-safe by design: it lists batch IDs and bucket-level counts, not private filenames.")
$lines.Add("It is not approval to move files. Actual movement still requires an explicit user-approved batch ID.")
$lines.Add("")
$lines.Add("## Safety Snapshot")
$lines.Add("")
$lines.Add("| Check | Value |")
$lines.Add("| --- | ---: |")
$lines.Add("| Batch count | $($batches.Count) |")
$lines.Add("| Candidate item count | $($items.Count) |")
$lines.Add("| Total candidate size | $(Format-ByteSize $totalSizeBytes) |")
$lines.Add("| Deferred recent candidates | $($plan.deferred_count) |")
$lines.Add("| Protected-root hits in executable batches | $protectedHits |")
$lines.Add("| Reparse point hits in executable batches | $reparseHits |")
$lines.Add("| Directory hits in executable batches | $directoryHits |")
$lines.Add("| Git worktree hits in executable batches | $gitHits |")
$lines.Add("| Recent hits inside executable batches | $recentHits |")
if ($preflight) {
    $lines.Add("| Preflight passed batches | $($preflight.passed_count) |")
    $lines.Add("| Preflight failed batches | $($preflight.failed_count) |")
    $lines.Add("| Preflight checked items | $($preflight.checked_item_count) |")
    $lines.Add("| Preflight executed moves | $($preflight.moves_executed) |")
}
$lines.Add("")
$lines.Add("## Batch Summary")
$lines.Add("")
$lines.Add("| Batch ID | Bucket | Part | Items | Size | Risk | Age gate | Destination |")
$lines.Add("| --- | --- | ---: | ---: | ---: | --- | ---: | --- |")
foreach ($row in $batchRows) {
    $lines.Add("| ``$(Escape-MarkdownCell $row.batch_id)`` | $(Escape-MarkdownCell $row.bucket) | $(Escape-MarkdownCell $row.part) | $($row.item_count) | $(Escape-MarkdownCell $row.total_size) | $(Escape-MarkdownCell $row.risk_tier) | $($row.minimum_age_days)d | ``$(Escape-MarkdownCell $row.destination_root)`` |")
}
$lines.Add("")
$lines.Add("## Approval Format")
$lines.Add("")
$lines.Add("Approve one or more exact batch IDs, for example:")
$lines.Add("")
$lines.Add('```text')
$lines.Add("approve batch-downloads-installers-old")
$lines.Add("approve batch-downloads-archives-old, batch-downloads-code-old")
$lines.Add('```')
$lines.Add("")
$lines.Add('The executor must rerun or verify preflight before using `Invoke-ApprovedMoveBatch.ps1 -Approved`.')
$lines.Add("")
$lines.Add("## Execution Template")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add('$plan = ' + "'" + $planFull + "'")
$lines.Add((Get-ScriptCommand "Invoke-ApprovedMoveBatch.ps1" "-MovePlanPath `$plan -BatchId '<approved-batch-id>' -PreflightOnly"))
$lines.Add((Get-ScriptCommand "Invoke-ApprovedMoveBatch.ps1" "-MovePlanPath `$plan -BatchId '<approved-batch-id>' -Approved"))
$lines.Add('```')
$lines.Add("")
$lines.Add("Rollback uses the applied manifest generated by an approved move:")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add((Get-ScriptCommand "Invoke-RollbackBatch.ps1" "-AppliedManifestPath '<applied-batch.json>'"))
$lines.Add('```')

$lines | Set-Content -LiteralPath $packetPath -Encoding UTF8

$preflightSummary = $null
if ($preflight) {
    $preflightSummary = [ordered]@{
        batch_count = [int]$preflight.batch_count
        passed_count = [int]$preflight.passed_count
        failed_count = [int]$preflight.failed_count
        checked_item_count = [int]$preflight.checked_item_count
        moves_executed = [bool]$preflight.moves_executed
    }
}

$summary = [ordered]@{
    schema_version = "1.0"
    generated_at = (Get-Date).ToString("o")
    move_plan_path = $planFull
    preflight_summary_path = $PreflightSummaryPath
    approval_packet_path = $packetPath
    batch_count = $batches.Count
    candidate_item_count = $items.Count
    total_size_bytes = [int64]$totalSizeBytes
    total_size_human = Format-ByteSize $totalSizeBytes
    deferred_count = [int]$plan.deferred_count
    safety = [ordered]@{
        protected_hits = $protectedHits
        reparse_hits = $reparseHits
        directory_hits = $directoryHits
        git_hits = $gitHits
        recent_hits = $recentHits
    }
    preflight = $preflightSummary
    batches = $batchRows
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

[pscustomobject]@{
    approval_packet = $packetPath
    approval_summary = $summaryPath
    batch_count = $batches.Count
    candidate_item_count = $items.Count
    total_size_human = Format-ByteSize $totalSizeBytes
    deferred_count = [int]$plan.deferred_count
    protected_hits = $protectedHits
    reparse_hits = $reparseHits
    directory_hits = $directoryHits
    git_hits = $gitHits
    recent_hits = $recentHits
    preflight_failed_count = if ($preflight) { [int]$preflight.failed_count } else { $null }
    moves_executed = if ($preflight) { [bool]$preflight.moves_executed } else { $false }
} | ConvertTo-Json -Depth 4
