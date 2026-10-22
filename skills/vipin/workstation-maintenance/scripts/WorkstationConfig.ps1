# Shared helpers for the workstation-maintenance scripts. Dot-source this file.
#
# Everything specific to one machine (which folders to protect, where organized
# files go, how to bucket top-level folders) lives in a JSON config file instead
# of the scripts. Lookup order:
#   1. the -ConfigPath argument of the calling script
#   2. $env:WORKSTATION_MAINTENANCE_CONFIG
#   3. config.json next to SKILL.md (git-ignored; start from config.example.json)
# Paths in the config may use environment variables such as %USERPROFILE%.

$script:WorkstationSkillRoot = Split-Path -Parent $PSScriptRoot

# Drive-root buckets a top-level folder can be moved into, with their risk tier.
$script:DriveRootMovableCategories = [ordered]@{
    "Downloads" = "low"
    "Temp-Review" = "low"
    "Media" = "medium"
    "Coursework" = "medium"
    "Documents-Private" = "medium"
    "Games" = "medium"
    "Tools-Review" = "medium"
}
# Drive-root categories that are only recorded.
$script:DriveRootRecordOnlyCategories = [ordered]@{
    "Protected-NoMove" = "protected"
    "AgentInfrastructure" = "high"
    "ActiveProject" = "high"
    "UnknownReview" = "review"
}

function Get-FullPathSafe {
    # Resolves relative paths against the PowerShell location (not the process
    # directory, which can differ) and normalizes the result.
    param([string]$Path)
    if (-not $Path) { return $Path }
    try { $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path) } catch { }
    try { return [System.IO.Path]::GetFullPath($Path) } catch { return $Path }
}

function Test-PathUnder {
    param([string]$Path, [string]$Root)
    if (-not $Path -or -not $Root) { return $false }
    $full = (Get-FullPathSafe $Path).TrimEnd('\')
    $base = (Get-FullPathSafe $Root).TrimEnd('\')
    return $full.Equals($base, [System.StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($base + "\", [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathUnderAny {
    param([string]$Path, [string[]]$Roots)
    foreach ($root in @($Roots)) {
        if ($root -and (Test-PathUnder $Path $root)) { return $true }
    }
    return $false
}

function Expand-ConfigPath {
    param([string]$Path)
    if (-not $Path) { return $null }
    return (Get-FullPathSafe ([Environment]::ExpandEnvironmentVariables($Path))).TrimEnd('\')
}

function Get-ConfigList {
    param($Raw, [string]$Name, [switch]$Paths)
    if ($null -eq $Raw) { return @() }
    if (-not ($Raw.PSObject.Properties.Name -contains $Name)) { return @() }
    $values = @($Raw.$Name | Where-Object { $_ })
    if ($Paths) {
        return @($values | ForEach-Object { Expand-ConfigPath ([string]$_) } | Where-Object { $_ })
    }
    return @($values | ForEach-Object { [string]$_ })
}

function Get-WorkstationConfig {
    param(
        [string]$ConfigPath = "",
        [switch]$Required
    )
    $explicit = $true
    if (-not $ConfigPath) { $ConfigPath = $env:WORKSTATION_MAINTENANCE_CONFIG }
    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $script:WorkstationSkillRoot "config.json"
        $explicit = $false
    }

    $raw = $null
    $source = $null
    $ConfigPath = Get-FullPathSafe $ConfigPath
    if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        $source = $ConfigPath
        $raw = Get-Content -LiteralPath $source -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } elseif ($explicit) {
        throw "Config file not found: $ConfigPath"
    } elseif ($Required) {
        throw ("No config.json found in $($script:WorkstationSkillRoot). Copy config.example.json to config.json, " +
            "list the folders that must never move, then run again (or pass -ConfigPath).")
    }

    $rules = [System.Collections.Generic.List[object]]::new()
    if ($raw -and ($raw.PSObject.Properties.Name -contains "drive_root_rules")) {
        foreach ($rule in @($raw.drive_root_rules)) {
            $category = [string]$rule.category
            if (-not ($script:DriveRootMovableCategories.Contains($category) -or $script:DriveRootRecordOnlyCategories.Contains($category))) {
                throw "Unknown drive_root_rules category '$category' in $source"
            }
            [void][regex]::new([string]$rule.pattern)
            $reason = if ($rule.PSObject.Properties.Name -contains "reason" -and $rule.reason) { [string]$rule.reason } else { "config rule" }
            $rules.Add([pscustomobject]@{ pattern = [string]$rule.pattern; category = $category; reason = $reason })
        }
    }

    $organizedRoot = $null
    if ($raw -and ($raw.PSObject.Properties.Name -contains "organized_root") -and $raw.organized_root) {
        $organizedRoot = Expand-ConfigPath ([string]$raw.organized_root)
    }

    return [pscustomobject]@{
        source = $source
        protected_roots = @(Get-ConfigList $raw "protected_roots" -Paths)
        infrastructure_roots = @(Get-ConfigList $raw "infrastructure_roots" -Paths)
        project_roots = @(Get-ConfigList $raw "project_roots" -Paths)
        inventory_roots = @(Get-ConfigList $raw "inventory_roots" -Paths)
        organized_root = $organizedRoot
        coursework_patterns = @(Get-ConfigList $raw "coursework_patterns")
        drive_root_rules = $rules.ToArray()
    }
}

function Get-PlanList {
    # Reads a list property that an earlier step recorded in a manifest or plan.
    param($Document, [string]$Name)
    if ($null -eq $Document) { return @() }
    if (-not ($Document.PSObject.Properties.Name -contains $Name)) { return @() }
    return @($Document.$Name | Where-Object { $_ } | ForEach-Object { [string]$_ })
}

function Get-SystemRoots {
    # Windows and installed-program folders; never moved.
    $roots = @($env:windir, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData)
    return @($roots | Where-Object { $_ } | ForEach-Object { Get-FullPathSafe $_ })
}

function Get-BuiltInInfrastructureRoots {
    # Agent and tool state in the user profile; recorded, never moved.
    if (-not $env:USERPROFILE) { return @() }
    $relative = @(".codex", ".claude", ".openhands", ".config\opencode", ".cache\opencode", ".local\share\opencode", ".local\state\opencode")
    return @($relative | ForEach-Object { Join-Path $env:USERPROFILE $_ })
}

function Get-ScriptCommand {
    # A ready-to-paste command line for another script in this folder.
    param([string]$ScriptName, [string]$Arguments)
    $scriptPath = Join-Path (Join-Path $script:WorkstationSkillRoot "scripts") $ScriptName
    return "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $Arguments"
}
