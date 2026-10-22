param(
    [string]$Path = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$ErrorActionPreference = "Stop"
$resolved = (Resolve-Path -LiteralPath $Path).Path
$pattern = 'sk-proj-[A-Za-z0-9_-]{20,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{32,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'
$allowedPlaceholders = @(
    "ghp_your_github_token",
    "ghp_your_new_github_token",
    "github_pat_your_github_token",
    "github_pat_your_new_github_token"
)

Push-Location $resolved
try {
    $ripgrep = Get-Command rg -ErrorAction SilentlyContinue
    if ($null -ne $ripgrep) {
        $raw = @(& $ripgrep.Source -n -I --pcre2 --with-filename --no-heading $pattern . 2>$null)
        if ($LASTEXITCODE -notin @(0, 1)) {
            throw "ripgrep public-safety scan failed in $resolved"
        }
    } else {
        & git -C $resolved rev-parse --is-inside-work-tree 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "ripgrep is unavailable and $resolved is not a Git worktree"
        }

        $raw = @(& git -C $resolved -c core.quotePath=false grep -n -I -E -e $pattern -- . 2>$null)
        if ($LASTEXITCODE -notin @(0, 1)) {
            throw "git grep public-safety scan failed in $resolved"
        }

        $untracked = @(& git -C $resolved -c core.quotePath=false ls-files --others --exclude-standard 2>$null)
        if ($LASTEXITCODE -ne 0) {
            throw "cannot enumerate untracked files in $resolved"
        }
        foreach ($relative in $untracked) {
            $full = Join-Path $resolved ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                continue
            }
            $item = Get-Item -LiteralPath $full
            if ($item.Length -gt 5MB) {
                continue
            }
            try {
                $text = Get-Content -LiteralPath $full -Raw -ErrorAction Stop
            } catch {
                continue
            }
            if ($null -eq $text) {
                continue
            }
            foreach ($match in [regex]::Matches($text, $pattern)) {
                $raw += "${relative}:$($match.Value)"
            }
        }
    }
    $hits = @()
    foreach ($line in $raw) {
        foreach ($match in [regex]::Matches($line, $pattern)) {
            $value = $match.Value
            if ($allowedPlaceholders -contains $value) {
                continue
            }
            $redacted = if ($value.Length -gt 12) {
                $value.Substring(0, 8) + "..." + $value.Substring($value.Length - 4)
            } else {
                "[redacted]"
            }
            $hits += $line.Replace($value, $redacted)
        }
    }

    if ($hits.Count -gt 0) {
        $hits | Select-Object -First 80
        throw "Strict public-safety scan failed in $resolved"
    }

    # Absolute Windows paths (a drive letter, a colon, a backslash) describe one
    # machine's folder layout. Skills take such paths from a git-ignored config
    # file or an environment variable instead, so tracked files should have none.
    $drivePathPattern = '(^|[^A-Za-z0-9])[A-Za-z]:\\\\?[A-Za-z0-9_.$%-]'
    $drivePathHits = @(& git -C $resolved -c core.quotePath=false grep -n -I -E -e $drivePathPattern -- . 2>$null)
    if ($LASTEXITCODE -notin @(0, 1)) {
        throw "git grep drive-path scan failed in $resolved"
    }
    if ($drivePathHits.Count -gt 0) {
        $drivePathHits | Select-Object -First 80
        throw "Tracked files contain absolute Windows paths in $resolved"
    }
    # git grep exits 1 when nothing matches; do not let that become the script's exit code.
    $global:LASTEXITCODE = 0

    Write-Host "Strict public-safety scan passed: $resolved" -ForegroundColor Green
} finally {
    Pop-Location
}
