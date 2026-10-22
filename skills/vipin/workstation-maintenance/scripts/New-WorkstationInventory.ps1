param(
    [string[]]$Roots = @(),
    [string]$OutputDir = ".",
    [string]$TargetRoot = "",
    [string]$ConfigPath = "",
    [ValidateSet("Live", "Fixture")]
    [string]$Mode = "Live"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "WorkstationConfig.ps1")

# A live run must know what to protect, so it needs a config file.
$config = Get-WorkstationConfig -ConfigPath $ConfigPath -Required:($Mode -eq "Live")
if ($Roots.Count -eq 0) { $Roots = @($config.inventory_roots) }
if ($Roots.Count -eq 0) {
    throw "Nothing to scan. Pass -Roots or set inventory_roots in the config."
}
if (-not $TargetRoot) { $TargetRoot = $config.organized_root }
if (-not $TargetRoot) {
    throw "No target folder. Pass -TargetRoot or set organized_root in the config."
}
$ProtectedRoots = @($config.protected_roots)
$SystemRoots = @(Get-SystemRoots)
$InfrastructureRoots = @($config.infrastructure_roots) + @(Get-BuiltInInfrastructureRoots)
$ProjectRoots = @($config.project_roots)
$CourseworkPattern = (@('exam', 'course', 'lecture', 'study', 'homework', 'assignment', 'resit') + @($config.coursework_patterns)) -join '|'
$ProfileFolders = @("Downloads", "Desktop", "Documents", "Pictures", "Videos")

function Get-ReparseTarget {
    param($Item)
    if (-not (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        return $null
    }
    if ($Item.Target) {
        if ($Item.Target -is [array]) { return ($Item.Target -join ";") }
        return [string]$Item.Target
    }
    try {
        return (Get-Item -LiteralPath $Item.FullName -Force).Target
    } catch {
        return $null
    }
}

function Get-Kind {
    param($Item)
    if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return "reparse" }
    if ($Item.PSIsContainer) { return "directory" }
    if ($Item -is [System.IO.FileInfo]) { return "file" }
    return "other"
}

function Get-GitRoot {
    param([string]$Path)
    $full = Get-FullPathSafe $Path
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        $dir = Split-Path -Parent $full
    } else {
        $dir = $full
    }
    while ($dir) {
        if (Test-Path -LiteralPath (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

function Get-SourceBucket {
    param([string]$Path)
    $full = Get-FullPathSafe $Path
    if ($env:USERPROFILE) {
        foreach ($folder in $ProfileFolders) {
            if (Test-PathUnder $full (Join-Path $env:USERPROFILE $folder)) {
                return ("Users-$($env:USERNAME)-$folder" -replace '[^A-Za-z0-9._-]+', '-')
            }
        }
    }
    $leafParent = Split-Path -Leaf (Split-Path -Parent $full)
    if (-not $leafParent) { $leafParent = "root" }
    return ($leafParent -replace '[^A-Za-z0-9._-]+', '-')
}

function Join-OrganizedPath {
    param(
        [string]$Category,
        [string]$SourcePath,
        [string]$TargetRoot
    )
    $fileName = Split-Path -Leaf $SourcePath
    $bucket = Get-SourceBucket $SourcePath
    switch ($Category) {
        "Downloads" { $sub = "Downloads" }
        "MediaAssets" { $sub = "Media" }
        "TempCache" { $sub = "Temp-Review" }
        default { $sub = "Temp-Review" }
    }
    return Join-Path (Join-Path (Join-Path $TargetRoot $sub) $bucket) $fileName
}

function Get-Classification {
    param(
        $Item,
        [string]$Kind,
        [string]$GitRoot,
        [string]$ReparseTarget
    )
    $path = Get-FullPathSafe $Item.FullName
    $name = $Item.Name.ToLowerInvariant()
    $lower = $path.ToLowerInvariant()

    if (Test-PathUnderAny $path $ProtectedRoots) {
        return @("Protected-NoMove", "protected", "under a protected root")
    }
    if ($ReparseTarget -and (Test-PathUnderAny $ReparseTarget $ProtectedRoots)) {
        return @("Protected-NoMove", "protected", "reparse target under a protected root")
    }
    if ($Kind -eq "reparse") {
        return @("Protected-NoMove", "protected", "reparse point")
    }
    if (Test-PathUnderAny $path $SystemRoots) {
        return @("Protected-NoMove", "protected", "Windows system or installed program root")
    }
    if ($Mode -ne "Fixture" -and $lower -match '\\appdata\\') {
        return @("Protected-NoMove", "protected", "user runtime AppData")
    }
    if ($lower -match '\\(cache|caches|node_modules|\.venv|venv|site-packages|logs?|sessions?|profiles?|cookies|databases?|auth)(\\|$)') {
        return @("Protected-NoMove", "protected", "runtime/cache/auth/session path")
    }
    if (Test-PathUnderAny $path $InfrastructureRoots) {
        return @("AgentInfrastructure", "high", "agent infrastructure path")
    }
    if ($GitRoot) {
        return @("ActiveProject", "high", "inside git worktree")
    }
    if (Test-PathUnderAny $path $ProjectRoots) {
        return @("ActiveProject", "high", "configured project root")
    }
    if ($lower -match '(medical|health|bank|finance|tax|passport|visa|insurance|application|contract|offer|resume|cv|identity|credential|secret|token|private)') {
        return @("PersonalSensitive", "high", "sensitive filename/path pattern")
    }
    if ($name -match "($CourseworkPattern)") {
        return @("CourseworkArchive", "medium", "coursework filename/path pattern")
    }
    if ($name -match '\.(jpg|jpeg|png|gif|webp|mp4|mov|avi|mkv|mp3|wav|flac)$') {
        return @("MediaAssets", "low", "media extension")
    }
    if ($lower -match '\\(temp|tmp|downloads?)\\' -or $name -match '\.(zip|7z|rar|tar|gz|msi|exe|dmg|pkg|crdownload)$') {
        if ($lower -match '\\(temp|tmp)\\') {
            return @("TempCache", "low", "temporary folder/file candidate")
        }
        return @("Downloads", "low", "download folder or downloaded file candidate")
    }
    if ($lower -match '(visual studio|cuda|python|nodejs|anaconda|miniconda|mingw|llvm|jdk|android|docker|wsl)') {
        return @("VendorSystemToolchain", "high", "vendor/toolchain path")
    }
    return @("UnknownReview", "review", "needs manual review")
}

function Add-InventoryItem {
    param(
        $Item,
        [System.Collections.Generic.List[object]]$Items,
        [ref]$Counter
    )
    $kind = Get-Kind $Item
    $reparseTarget = Get-ReparseTarget $Item
    $resolved = Get-FullPathSafe $Item.FullName
    if ($reparseTarget) {
        $resolved = Get-FullPathSafe $reparseTarget
    }
    if ((Test-PathUnderAny $resolved $ProtectedRoots) -or (Test-PathUnderAny $Item.FullName $ProtectedRoots)) {
        return
    }
    $gitRoot = if ($kind -eq "reparse") { $null } else { Get-GitRoot $Item.FullName }
    $class = Get-Classification $Item $kind $gitRoot $reparseTarget
    $category = $class[0]
    $risk = $class[1]
    $reason = $class[2]
    $eligible = ($kind -eq "file" -and -not $gitRoot -and $risk -eq "low" -and
        @("Downloads", "MediaAssets", "TempCache") -contains $category)
    $destination = $null
    if ($eligible) {
        $destination = Join-OrganizedPath $category $Item.FullName $TargetRoot
    }
    $Counter.Value++
    $id = "wm_{0:D6}" -f $Counter.Value
    $size = if ($Item -is [System.IO.FileInfo]) { [long]$Item.Length } else { 0 }
    $Items.Add([pscustomobject][ordered]@{
        id = $id
        path = $Item.FullName
        resolved_path = $resolved
        drive = ([System.IO.Path]::GetPathRoot($Item.FullName)).TrimEnd('\')
        kind = $kind
        size = $size
        mtime = $Item.LastWriteTime.ToString("o")
        attributes = [string]$Item.Attributes
        reparse_target = $reparseTarget
        git_root = $gitRoot
        category = $category
        risk_tier = $risk
        move_eligible = [bool]$eligible
        proposed_destination = $destination
        reason = $reason
        rollback_source = $destination
        rollback_destination = $Item.FullName
    })
}

$out = Get-FullPathSafe $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null

$scanPaths = [System.Collections.Generic.List[string]]::new()
foreach ($root in $Roots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    if (Test-PathUnderAny $root $ProtectedRoots) { continue }
    $scanPaths.Add((Get-FullPathSafe $root))
    try {
        Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop | ForEach-Object {
            if (-not (Test-PathUnderAny $_.FullName $ProtectedRoots)) {
                $scanPaths.Add($_.FullName)
                if ($_.PSIsContainer -and $_.Name -match '^(Downloads|Download|Temp|tmp|Pictures|Videos|Desktop|Documents)$') {
                    Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue | ForEach-Object {
                        if (-not (Test-PathUnderAny $_.FullName $ProtectedRoots)) { $scanPaths.Add($_.FullName) }
                    }
                }
            }
        }
    } catch {
        Write-Warning "Could not enumerate root ${root}: $($_.Exception.Message)"
    }
}

if ($Mode -eq "Live" -and $env:USERPROFILE) {
    # Also look one level into the usual clutter folders of the current user.
    $extraDirs = @($ProfileFolders | ForEach-Object { Join-Path $env:USERPROFILE $_ })
    if ($env:LOCALAPPDATA) { $extraDirs += (Join-Path $env:LOCALAPPDATA "Temp") }
    foreach ($dir in $extraDirs) {
        if (Test-Path -LiteralPath $dir -PathType Container) {
            try {
                Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    if (-not (Test-PathUnderAny $_.FullName $ProtectedRoots)) { $scanPaths.Add($_.FullName) }
                }
            } catch {
                Write-Warning "Could not enumerate extra dir ${dir}: $($_.Exception.Message)"
            }
        }
    }
}

$uniquePaths = @($scanPaths | Sort-Object -Unique)
$items = [System.Collections.Generic.List[object]]::new()
$counter = 0
foreach ($path in $uniquePaths) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    if (Test-PathUnderAny $path $ProtectedRoots) { continue }
    try {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        Add-InventoryItem -Item $item -Items $items -Counter ([ref]$counter)
    } catch {
        Write-Warning "Could not inspect ${path}: $($_.Exception.Message)"
    }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $out "workstation-inventory-$stamp.json"
$mdPath = Join-Path $out "workstation-inventory-$stamp.md"

$manifest = [ordered]@{
    schema_version = "1.0"
    generated_at = (Get-Date).ToString("o")
    mode = $Mode
    config_path = $config.source
    roots = @($Roots)
    target_root = $TargetRoot
    protected_roots = @($ProtectedRoots)
    item_count = $items.Count
    move_eligible_count = @($items | Where-Object { $_.move_eligible }).Count
    items = $items
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Workstation Inventory")
$lines.Add("")
$lines.Add("Generated: $((Get-Date).ToString('o'))")
$lines.Add("")
$lines.Add("This is a dry-run manifest. It is not approval to move files.")
$lines.Add("")
$lines.Add("## Category Summary")
$lines.Add("")
$lines.Add("| Category | Count | Move eligible |")
$lines.Add("| --- | ---: | ---: |")
foreach ($group in @($items | Group-Object category | Sort-Object Name)) {
    $eligibleCount = @($group.Group | Where-Object { $_.move_eligible }).Count
    $lines.Add("| $($group.Name) | $($group.Count) | $eligibleCount |")
}
$lines.Add("")
$lines.Add("Paths under protected roots are left out of this manifest on purpose.")
$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

[pscustomobject]@{
    manifest = $jsonPath
    markdown = $mdPath
    item_count = $items.Count
    move_eligible_count = @($items | Where-Object { $_.move_eligible }).Count
} | ConvertTo-Json -Depth 4
