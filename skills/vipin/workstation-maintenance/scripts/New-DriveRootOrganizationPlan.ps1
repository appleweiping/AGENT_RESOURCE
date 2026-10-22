param(
    [Parameter(Mandatory = $true)]
    [string]$DriveRoot,
    [string]$OutputDir = "",
    [string]$TargetRoot = "",
    [string[]]$ExcludeNames = @(),
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "WorkstationConfig.ps1")

$config = Get-WorkstationConfig -ConfigPath $ConfigPath -Required
$ProtectedRoots = @($config.protected_roots)
$InfrastructureRoots = @($config.infrastructure_roots)
$ProjectRoots = @($config.project_roots)
$SystemRoots = @(Get-SystemRoots)

function Test-OverlapsAny {
    # True when the folder is inside one of the roots or contains one of them.
    param([string]$Path, [string[]]$Roots)
    foreach ($root in @($Roots)) {
        if (-not $root) { continue }
        if ((Test-PathUnder $Path $root) -or (Test-PathUnder $root $Path)) { return $true }
    }
    return $false
}

function Get-SafeName {
    param([string]$Name)
    $safe = (($Name -replace '[<>:"/\\|?*]+', '-') -replace '\s+', ' ').Trim()
    if (-not $safe) { return "unnamed" }
    return $safe
}

function New-StringFromCodePoints {
    param([int[]]$CodePoints)
    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

$HiFormatRecording = New-StringFromCodePoints @(0x55E8, 0x683C, 0x5F0F, 0x5F55, 0x5C4F, 0x6587, 0x4EF6)
$Browser360Download = "360" + (New-StringFromCodePoints @(0x5B89, 0x5168, 0x6D4F, 0x89C8, 0x5668, 0x4E0B, 0x8F7D))
$XunleiDownload = New-StringFromCodePoints @(0x8FC5, 0x96F7, 0x4E0B, 0x8F7D)
$XunleiCloud = New-StringFromCodePoints @(0x8FC5, 0x96F7, 0x4E91, 0x76D8)
$TencentMigration = New-StringFromCodePoints @(0x7535, 0x8111, 0x7BA1, 0x5BB6, 0x8FC1, 0x79FB, 0x6587, 0x4EF6)
$WeChatRoot = New-StringFromCodePoints @(0x5FAE, 0x4FE1)

function Get-UniqueDirectory {
    param(
        [string]$DesiredPath,
        [hashtable]$Used
    )
    $candidate = Get-FullPathSafe $DesiredPath
    $key = $candidate.ToLowerInvariant()
    if (-not $Used.ContainsKey($key) -and -not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }
    $parent = Split-Path -Parent $candidate
    $leaf = Split-Path -Leaf $candidate
    $i = 2
    while ($true) {
        $next = Join-Path $parent "$leaf-$i"
        $nextFull = Get-FullPathSafe $next
        $nextKey = $nextFull.ToLowerInvariant()
        if (-not $Used.ContainsKey($nextKey) -and -not (Test-Path -LiteralPath $nextFull)) {
            return $nextFull
        }
        $i += 1
    }
}

function Get-RootClassification {
    param($Item)
    $name = [string]$Item.Name
    $lower = $name.ToLowerInvariant()
    $full = Get-FullPathSafe $Item.FullName

    if ($name -eq "_Organized" -or ($ExcludeNames | Where-Object { $_.Equals($name, [System.StringComparison]::OrdinalIgnoreCase) })) {
        return @("Protected-NoMove", "protected", "excluded root")
    }
    if (Test-OverlapsAny $full $ProtectedRoots) {
        return @("Protected-NoMove", "protected", "protected root from config")
    }
    if ($name -in @('$RECYCLE.BIN', 'System Volume Information', 'OneDriveTemp') -or
        $lower -in @('program files', 'program files (x86)', 'programdata', 'windows', 'docker', 'virtualbox') -or
        $lower -match '^(pagefile\.sys|swapfile\.sys|hiberfil\.sys|dumpstack\.log\.tmp)$' -or
        (Test-OverlapsAny $full $SystemRoots)) {
        return @("Protected-NoMove", "protected", "system/vendor runtime root")
    }
    if ((Test-OverlapsAny $full $InfrastructureRoots) -or $lower -in @('.claude', '.codex', '.pnpm-store')) {
        return @("AgentInfrastructure", "high", "agent/tool infrastructure")
    }
    if (Test-OverlapsAny $full $ProjectRoots) {
        return @("ActiveProject", "high", "project root from config")
    }
    foreach ($rule in @($config.drive_root_rules)) {
        if ($name -match $rule.pattern) {
            $risk = if ($DriveRootMovableCategories.Contains($rule.category)) { $DriveRootMovableCategories[$rule.category] } else { $DriveRootRecordOnlyCategories[$rule.category] }
            return @($rule.category, $risk, $rule.reason)
        }
    }
    # Default folder names of common Windows apps.
    if ($lower -eq $WeChatRoot) {
        return @("Documents-Private", "high", "personal messaging data root")
    }
    if ($lower -in @('360downloads', $Browser360Download, 'baidunetdiskdownload', $XunleiDownload, $XunleiCloud, $TencentMigration)) {
        return @("Downloads", "low", "download/migration root")
    }
    if ($lower -eq $HiFormatRecording) {
        return @("Media", "medium", "screen recording root")
    }
    if ($lower -match '^(temp|tmp)$') {
        return @("Temp-Review", "low", "temporary/scratch root")
    }
    if ($lower -match '^(auntecpkg_|lenovo|flashcenter|drivers|androwsdata|mailmasterdata)') {
        return @("Tools-Review", "medium", "legacy vendor/tool/app-data root")
    }
    return @("UnknownReview", "review", "unclassified drive-root item")
}

$driveFull = (Get-FullPathSafe $DriveRoot).TrimEnd('\') + "\"
if (-not (Test-Path -LiteralPath $driveFull -PathType Container)) {
    throw "Drive root not found: $driveFull"
}
if (-not $TargetRoot) {
    $TargetRoot = Join-Path $driveFull "_Organized"
}
if (-not $OutputDir) {
    $OutputDir = Join-Path $TargetRoot "_Plans"
}
$out = Get-FullPathSafe $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

$targetFull = Get-FullPathSafe $TargetRoot
if (-not (Test-PathUnder $targetFull $driveFull)) {
    throw "Target root must stay on the drive being organized: $targetFull"
}
$targetLeaf = Split-Path -Leaf $targetFull.TrimEnd('\')
if (-not $targetLeaf.Equals("_Organized", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Target root must be the drive-root _Organized directory: $targetFull"
}
$targetParent = (Split-Path -Parent $targetFull.TrimEnd('\')).TrimEnd('\') + "\"
if (-not $targetParent.Equals($driveFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Target root must be an immediate child of the drive root: $targetFull"
}
if (Test-Path -LiteralPath $targetFull) {
    $targetItem = Get-Item -LiteralPath $targetFull -Force
    if (($targetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Target root must not be a reparse point: $targetFull"
    }
}

$usedTargets = @{}
$items = [System.Collections.Generic.List[object]]::new()
$counter = 0
Get-ChildItem -LiteralPath $driveFull -Force | Sort-Object Name | ForEach-Object {
    $counter += 1
    $kind = if ($_.PSIsContainer) { "directory" } else { "file" }
    $isReparse = (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
    $classification = Get-RootClassification $_
    $category = $classification[0]
    $risk = $classification[1]
    $reason = $classification[2]
    $action = "record-only"
    $targetPath = $null
    if ($kind -eq "directory" -and -not $isReparse -and $DriveRootMovableCategories.Contains($category)) {
        $action = "move-with-junction"
        $desired = Join-Path (Join-Path (Join-Path $targetFull $category) "_RootDirs") (Get-SafeName $_.Name)
        $targetPath = Get-UniqueDirectory -DesiredPath $desired -Used $usedTargets
        $usedTargets[$targetPath.ToLowerInvariant()] = $true
    }
    $items.Add([pscustomobject][ordered]@{
        id = "dr_{0:D4}" -f $counter
        name = $_.Name
        source_path = $_.FullName
        kind = $kind
        attributes = [string]$_.Attributes
        category = $category
        risk_tier = $risk
        action = $action
        target_path = $targetPath
        junction_path = if ($action -eq "move-with-junction") { $_.FullName } else { $null }
        reason = $reason
    })
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $out "drive-root-organization-plan-$stamp.json"
$mdPath = Join-Path $out "drive-root-organization-plan-$stamp.md"
$moveItems = @($items | Where-Object { $_.action -eq "move-with-junction" })
$recordItems = @($items | Where-Object { $_.action -ne "move-with-junction" })

$plan = [ordered]@{
    schema_version = "1.0"
    generated_at = (Get-Date).ToString("o")
    drive_root = $driveFull
    target_root = $targetFull
    excluded_names = @($ExcludeNames)
    protected_roots = @($ProtectedRoots)
    infrastructure_roots = @($InfrastructureRoots)
    project_roots = @($ProjectRoots)
    item_count = $items.Count
    move_count = $moveItems.Count
    record_only_count = $recordItems.Count
    items = $items
}
$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Drive Root Organization Plan")
$lines.Add("")
$lines.Add("Generated: $((Get-Date).ToString('o'))")
$lines.Add("")
$lines.Add("Move-with-junction entries move the folder under ``$targetFull`` and leave a junction at the old path.")
$lines.Add("")
$lines.Add("| ID | Name | Category | Action | Target | Reason |")
$lines.Add("| --- | --- | --- | --- | --- | --- |")
foreach ($item in $items) {
    $target = if ($item.target_path) { "``$($item.target_path)``" } else { "" }
    $lines.Add("| $($item.id) | ``$($item.name)`` | $($item.category) | $($item.action) | $target | $($item.reason) |")
}
$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    plan = $jsonPath
    markdown = $mdPath
    item_count = $items.Count
    move_count = $moveItems.Count
    record_only_count = $recordItems.Count
    categories = @($items | Group-Object category | Sort-Object Name | ForEach-Object { [pscustomobject]@{ category = $_.Name; count = $_.Count } })
} | ConvertTo-Json -Depth 5
