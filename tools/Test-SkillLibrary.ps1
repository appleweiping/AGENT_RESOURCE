param(
    [string]$Path = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$ChangedFrom = "",
    [switch]$Strict,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $Path).Path
$python = Get-Command python -ErrorAction Stop
$catalog = Join-Path $root "tools/skill_catalog.py"

$arguments = @($catalog, "--root", $root, "validate")
if ($ChangedFrom) {
    $arguments += @("--changed-from", $ChangedFrom)
} elseif ($Strict) {
    $arguments += "--strict"
}

& $python.Source @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Skill manifest validation failed in $root"
}

if (-not $SkipTests) {
    Push-Location $root
    try {
        # unittest reports on stderr; Windows PowerShell 5.1 turns redirected
        # stderr into errors, so rely on the exit code instead.
        $ErrorActionPreference = "Continue"
        & $python.Source -m unittest discover -s "tools/tests" -p "test_*.py"
        $ErrorActionPreference = "Stop"
        if ($LASTEXITCODE -ne 0) {
            throw "Skill library unit tests failed in $root"
        }
    } finally {
        Pop-Location
    }
}

Write-Host "Skill library validation passed: $root" -ForegroundColor Green
