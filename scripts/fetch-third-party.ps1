# Download the third-party skills listed in scripts/third-party.txt into
# third_party/<name> (git-ignored), each checked out at its pinned commit.
#
#   .\scripts\fetch-third-party.ps1                         # everything
#   .\scripts\fetch-third-party.ps1 superpowers, gsap-skills
#
# Uses a blob-less partial clone plus sparse checkout, so only the listed
# paths are downloaded. Re-running updates an existing checkout in place.
param([string[]]$Name)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $PSScriptRoot 'third-party.txt'
$destRoot = Join-Path $root 'third_party'
New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed with exit code $LASTEXITCODE" }
}

$matched = 0
foreach ($line in Get-Content -LiteralPath $manifest) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $fields = $line -split '\s+'
    $entry, $repo, $ref = $fields[0], $fields[1], $fields[2]
    $paths = @($fields[3..($fields.Count - 1)])
    if ($Name -and ($Name -notcontains $entry)) { continue }
    $matched++
    $dest = Join-Path $destRoot $entry

    if (-not (Test-Path -LiteralPath (Join-Path $dest '.git'))) {
        Invoke-Git clone --quiet --filter=blob:none --no-checkout "https://github.com/$repo.git" $dest
    }
    if ($paths.Count -eq 1 -and $paths[0] -eq '.') {
        Invoke-Git -C $dest sparse-checkout disable
    } else {
        Invoke-Git -C $dest sparse-checkout set --cone @paths
    }
    & git -C $dest rev-parse --verify --quiet "$ref^{commit}" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Invoke-Git -C $dest fetch --quiet origin $ref
    }
    Invoke-Git -C $dest -c advice.detachedHead=false checkout --quiet $ref
    Write-Host "$entry -> third_party/$entry @ $($ref.Substring(0, 7))"
}

if ($matched -eq 0) {
    throw "No entries matched: $($Name -join ', ')"
}
