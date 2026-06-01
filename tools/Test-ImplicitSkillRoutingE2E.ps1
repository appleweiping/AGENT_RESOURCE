param(
    [switch]$RunCc,
    [string]$CcModel = "claude-haiku-4-5"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$agentAudit = "D:\devtools\codex\home\skills\ecc\skills\agent-architecture-audit\SKILL.md"
$wikiSkill = "D:\Research\vipin's knowledgebase\.codex\skills\vipin-wiki\SKILL.md"

foreach ($path in @($agentAudit, $wikiSkill)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing expected implicit-routing target: $path"
    }
}

$agentAuditText = Get-Content -LiteralPath $agentAudit -Raw
if ($agentAuditText -notmatch "memory" -or $agentAuditText -notmatch "tool" -or $agentAuditText -notmatch "wrapper") {
    throw "agent architecture audit metadata/body is missing expected trigger terms"
}

$wikiSkillText = Get-Content -LiteralPath $wikiSkill -Raw
if ($wikiSkillText -notmatch "wiki" -or $wikiSkillText -notmatch "maintain" -or $wikiSkillText -notmatch "log") {
    throw "vipin-wiki metadata/body is missing expected trigger terms"
}

Write-Host "Codex implicit-routing evidence paths exist and contain trigger terms." -ForegroundColor Green

if ($RunCc) {
    $cc = "D:\devtools\cc.cmd"
    if (-not (Test-Path -LiteralPath $cc)) {
        throw "Missing CC launcher: $cc"
    }
    $prompt = @'
AUTHORIZATION: User-authorized local read-only test.
TASK: A user reports that an LLM-powered assistant regressed after adding wrapper layers: stale long-term memory leaks into new tasks, required tools are skipped, hidden retry/repair loops may mutate answers, and old queue coordination keeps reappearing. Choose the relevant installed workflow instruction file from local metadata, read it, and answer exactly:
SELECTED_PATH: <absolute path>
TRIGGER_REASON: <one sentence>
FIRST_HEADING: <first markdown heading>
CONSTRAINTS: Read-only. No edits. No credentials.
'@
    $output = $prompt | & $cc -p --model $CcModel --output-format text --permission-mode dontAsk --allowedTools "Read,Grep,Glob" --add-dir "D:\devtools\codex\home\skills" --max-budget-usd 0.50 --no-session-persistence
    $output
    if ($LASTEXITCODE -ne 0) {
        throw "CC implicit-routing prompt failed"
    }
    if ($output -notmatch "SELECTED_PATH:" -or $output -notmatch "FIRST_HEADING:") {
        throw "CC output did not prove it selected and read a local workflow file"
    }
}

Write-Host "Implicit skill routing E2E check completed." -ForegroundColor Cyan
