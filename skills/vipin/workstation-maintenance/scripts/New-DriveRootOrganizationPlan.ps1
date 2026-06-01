param(
    [string]$DriveRoot = "D:\",
    [string]$OutputDir = "",
    [string]$TargetRoot = "D:\_Organized",
    [string[]]$ExcludeNames = @("Research", "agent-resources", "devtools", "devtools-public", "_Organized")
)

$ErrorActionPreference = "Stop"
$HardProtectedRootNames = @("Research", "agent-resources", "devtools", "devtools-public", "_Organized")

function Get-FullPathSafe {
    param([string]$Path)
    try { return [System.IO.Path]::GetFullPath($Path) } catch { return $Path }
}

function Test-PathUnder {
    param([string]$Path, [string]$Root)
    if (-not $Path) { return $false }
    $full = (Get-FullPathSafe $Path).TrimEnd('\')
    $base = (Get-FullPathSafe $Root).TrimEnd('\')
    return $full.Equals($base, [System.StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($base + "\", [System.StringComparison]::OrdinalIgnoreCase)
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
$LoveName = New-StringFromCodePoints @(0x7231)
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

    if (($ExcludeNames + $HardProtectedRootNames) | Where-Object { $_.Equals($name, [System.StringComparison]::OrdinalIgnoreCase) }) {
        return @("Protected-NoMove", "protected", "excluded root")
    }
    if ($name -in @('$RECYCLE.BIN', 'System Volume Information', 'OneDriveTemp') -or
        $lower -in @('program files', 'docker', 'virtualbox') -or
        $lower -match '^(pagefile\.sys|dumpstack\.log\.tmp)$') {
        return @("Protected-NoMove", "protected", "system/vendor runtime root")
    }
    if ($lower -in @('.claude', 'devtools', 'devtools-public', 'agent-resources') -or
        $lower -match '^\.pnpm-store$') {
        return @("AgentInfrastructure", "high", "agent/tool infrastructure")
    }
    if ($lower -in @('company', 'project', 'healthcare', 'game_develop', 'frontend', 'idea', 'weipingyan_portfolio')) {
        return @("ActiveProject", "high", "known active project root")
    }
    if ($lower -match '^(academic_portfolio)$') {
        return @("Documents-Private", "medium", "sensitive archive root")
    }
    if ($lower -eq $WeChatRoot) {
        return @("Documents-Private", "high", "personal messaging data root")
    }
    if ($lower -match '^(undergraduate_|tuelearning$|cs project$)') {
        return @("Coursework", "medium", "coursework/archive root")
    }
    if ($lower -in @('terraria_doc', 'girlvania')) {
        return @("Games", "medium", "game/archive root")
    }
    if ($lower -in @('video creation', $HiFormatRecording, $LoveName)) {
        return @("Media", "medium", "media/personal asset root")
    }
    if ($lower -in @('360downloads', $Browser360Download, 'baidunetdiskdownload', $XunleiDownload, $XunleiCloud, $TencentMigration)) {
        return @("Downloads", "low", "download/migration root")
    }
    if ($lower -match '^(temp|tmp|tempappleweiping-site|codex-chrome-automation-profile-.+)$') {
        return @("Temp-Review", "low", "temporary/scratch root")
    }
    if ($lower -match '^(auntecpkg_|lenovo|flashcenter|drivers|androwsdata|mailmasterdata)') {
        return @("Tools-Review", "medium", "legacy vendor/tool/app-data root")
    }
    return @("UnknownReview", "review", "unclassified D-root item")
}

$driveFull = (Get-FullPathSafe $DriveRoot).TrimEnd('\') + "\"
if (-not (Test-Path -LiteralPath $driveFull -PathType Container)) {
    throw "Drive root not found: $driveFull"
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
    if ($kind -eq "directory" -and -not $isReparse -and $category -in @("Downloads", "Media", "Coursework", "Documents-Private", "Games", "Temp-Review", "Tools-Review")) {
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
$jsonPath = Join-Path $out "d-drive-root-organization-plan-$stamp.json"
$mdPath = Join-Path $out "d-drive-root-organization-plan-$stamp.md"
$moveItems = @($items | Where-Object { $_.action -eq "move-with-junction" })
$recordItems = @($items | Where-Object { $_.action -ne "move-with-junction" })

$plan = [ordered]@{
    schema_version = "1.0"
    generated_at = (Get-Date).ToString("o")
    drive_root = $driveFull
    target_root = $targetFull
    excluded_names = $ExcludeNames
    item_count = $items.Count
    move_count = $moveItems.Count
    record_only_count = $recordItems.Count
    items = $items
}
$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# D-Drive Root Organization Plan")
$lines.Add("")
$lines.Add("Generated: $((Get-Date).ToString('o'))")
$lines.Add("")
$lines.Add("Move-with-junction entries move actual data under `D:\_Organized` and leave the old root path as a junction.")
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
