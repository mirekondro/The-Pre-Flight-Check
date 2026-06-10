<#
.SYNOPSIS
    pre-flight-check — multi-tool installer (Windows / PowerShell).

.DESCRIPTION
    Installs the pre-flight-check skill for one or more AI coding tools.
    The pipeline engine (run-pipeline.py) is the same across all tools;
    only the instruction/rule file format and deploy path differ.

.PARAMETER Tool
    AI tool to install for. One of: claude, codex, gemini, cursor, copilot,
    windsurf, cline, kiro, roo, agents-skills, all. Default: claude.

.PARAMETER Global
    Install Claude into %USERPROFILE%\.claude\skills\. Claude only.

.PARAMETER Project
    Install into the current directory (default for non-Claude tools).

.PARAMETER Dir
    Override the project root the adapter is deployed into.

.PARAMETER Ref
    Git ref (branch/tag/sha) to download from. Default: main.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER Uninstall
    Remove the install instead of installing.

.PARAMETER ListTools
    Print the supported AI tools table and exit.

.EXAMPLE
    irm https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.ps1 | iex

.EXAMPLE
    .\install.ps1 -Tool cursor -Project -Force

.EXAMPLE
    .\install.ps1 -Tool all -Project
#>

[CmdletBinding()]
param(
    [string]$Tool = 'claude',
    [switch]$Global,
    [switch]$Project,
    [string]$Dir,
    [string]$Ref = 'main',
    [switch]$Force,
    [switch]$Uninstall,
    [switch]$ListTools
)

$ErrorActionPreference = 'Stop'

$Repo      = 'mirekondro/The-Pre-Flight-Check'
$SkillName = 'pre-flight-check'
$SupportedTools = @('claude','codex','gemini','cursor','copilot','windsurf','cline','kiro','roo','agents-skills','all')

function Write-Step  { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "✓  $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "!  $Msg" -ForegroundColor Yellow }
function Throw-Die   { param([string]$Msg) Write-Host "✗  $Msg" -ForegroundColor Red; throw $Msg }

if ($ListTools) {
    @"
Supported AI tools (-Tool):

  claude          Claude Code            -> %USERPROFILE%\.claude\skills\  or  .claude\skills\
  codex           OpenAI Codex / AGENTS  -> AGENTS.md at repo root
  gemini          Gemini CLI             -> GEMINI.md + gemini-extension.json at repo root
  cursor          Cursor                 -> .cursor\rules\pre-flight-check.mdc
  copilot         GitHub Copilot         -> .github\copilot-instructions.md
  windsurf        Windsurf               -> .windsurf\rules\pre-flight-check.md
  cline           Cline                  -> .clinerules\pre-flight-check.md
  kiro            Kiro                   -> .kiro\steering\pre-flight-check.md
  roo             Roo Code               -> .roo\rules\pre-flight-check.md
  agents-skills   Agent Skills standard  -> .agents\skills\pre-flight-check\

  all             Install for every supported tool above.

The pipeline engine (run-pipeline.py) is deployed once per scope:
  - Claude: .claude\skills\pre-flight-check\scripts\run-pipeline.py
  - All others: .pre-flight-check\scripts\run-pipeline.py
"@ | Write-Host
    return
}

if ($SupportedTools -notcontains $Tool) {
    Throw-Die "unknown tool: $Tool (use -ListTools to see supported tools)"
}

# --Global only applies to Claude; non-Claude defaults to --Project.
if ($Tool -ne 'claude' -and $Global) {
    Throw-Die "-Global is only supported for -Tool claude. Use -Project or -Dir for $Tool."
}

# Resolve target root.
if     ($Dir)     { $target = (Resolve-Path -LiteralPath $Dir -ErrorAction SilentlyContinue); if (-not $target) { $target = $Dir }; $scope = 'custom' }
elseif ($Project) { $target = (Get-Location).Path; $scope = 'project' }
elseif ($Global)  { $target = $env:USERPROFILE; $scope = 'global' }
elseif ($Tool -eq 'claude') { $target = $env:USERPROFILE; $scope = 'global' }
else              { $target = (Get-Location).Path; $scope = 'project' }

# ---------- prerequisites ----------
function Test-Python {
    $py = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
    if (-not $py) {
        Throw-Die 'python (3.8+) not found on PATH. Install from https://www.python.org or via winget: winget install Python.Python.3.12'
    }
    $verStr = & $py.Source -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'
    $parts = $verStr.Split('.')
    if (([int]$parts[0]) -lt 3 -or (([int]$parts[0]) -eq 3 -and ([int]$parts[1]) -lt 8)) {
        Throw-Die "Python $verStr too old. Need Python ≥3.8."
    }
    return @{ Path = $py.Source; Version = $verStr }
}

# ---------- locate local clone ----------
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { $null }
$localRepo = $null
if ($scriptDir -and (Test-Path (Join-Path $scriptDir "skills\$SkillName\SKILL.md"))) {
    $localRepo = $scriptDir
}
$baseUrl = "https://raw.githubusercontent.com/$Repo/$Ref"

function Deploy-File {
    param([string]$SrcRel, [string]$Dest)
    $destDir = Split-Path -Parent $Dest
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    if ($localRepo -and (Test-Path (Join-Path $localRepo $SrcRel))) {
        Copy-Item -LiteralPath (Join-Path $localRepo $SrcRel) -Destination $Dest -Force
    } else {
        try {
            Invoke-WebRequest -Uri "$baseUrl/$SrcRel" -OutFile $Dest -UseBasicParsing
        } catch {
            Throw-Die "Failed to download $SrcRel from $baseUrl/$SrcRel"
        }
    }
}

function Confirm-Overwrite {
    param([string]$ExistingPath)
    if ($Force) { return }
    if ([Environment]::UserInteractive -and $Host.UI.RawUI) {
        $reply = Read-Host "?  $ExistingPath already exists. Overwrite? [y/N]"
        if ($reply -notmatch '^(y|Y|yes|YES)$') { Throw-Die 'Aborted.' }
    } else {
        Throw-Die "$ExistingPath already exists. Re-run with -Force to overwrite."
    }
}

function Get-ScriptDest {
    param([string]$T)
    switch ($T) {
        'claude'        { Join-Path $target ".claude\skills\$SkillName\scripts\run-pipeline.py" }
        'agents-skills' { Join-Path $target ".agents\skills\$SkillName\scripts\run-pipeline.py" }
        default         { Join-Path $target ".$SkillName\scripts\run-pipeline.py" }
    }
}

function Get-AdapterPaths {
    param([string]$T)
    switch ($T) {
        'claude'        { @((Join-Path $target ".claude\skills\$SkillName\SKILL.md")) }
        'codex'         { @((Join-Path $target 'AGENTS.md')) }
        'gemini'        { @((Join-Path $target 'GEMINI.md'), (Join-Path $target 'gemini-extension.json')) }
        'cursor'        { @((Join-Path $target '.cursor\rules\pre-flight-check.mdc')) }
        'copilot'       { @((Join-Path $target '.github\copilot-instructions.md')) }
        'windsurf'      { @((Join-Path $target '.windsurf\rules\pre-flight-check.md')) }
        'cline'         { @((Join-Path $target '.clinerules\pre-flight-check.md')) }
        'kiro'          { @((Join-Path $target '.kiro\steering\pre-flight-check.md')) }
        'roo'           { @((Join-Path $target '.roo\rules\pre-flight-check.md')) }
        'agents-skills' { @((Join-Path $target ".agents\skills\$SkillName\SKILL.md")) }
    }
}

function Install-OneTool {
    param([string]$T)
    Write-Step "Installing for $T"
    $scriptDest = Get-ScriptDest $T
    foreach ($p in (Get-AdapterPaths $T) + $scriptDest) {
        if (Test-Path $p) { Confirm-Overwrite $p }
    }

    Deploy-File "skills/$SkillName/scripts/run-pipeline.py" $scriptDest

    switch ($T) {
        'claude'        { Deploy-File "skills/$SkillName/SKILL.md" (Join-Path $target ".claude\skills\$SkillName\SKILL.md") }
        'codex'         { Deploy-File 'AGENTS.md' (Join-Path $target 'AGENTS.md') }
        'gemini'        {
            Deploy-File 'GEMINI.md' (Join-Path $target 'GEMINI.md')
            Deploy-File 'gemini-extension.json' (Join-Path $target 'gemini-extension.json')
        }
        'cursor'        { Deploy-File 'adapters/cursor/pre-flight-check.mdc' (Join-Path $target '.cursor\rules\pre-flight-check.mdc') }
        'copilot'       { Deploy-File 'adapters/copilot/copilot-instructions.md' (Join-Path $target '.github\copilot-instructions.md') }
        'windsurf'      { Deploy-File 'adapters/windsurf/pre-flight-check.md' (Join-Path $target '.windsurf\rules\pre-flight-check.md') }
        'cline'         { Deploy-File 'adapters/cline/pre-flight-check.md' (Join-Path $target '.clinerules\pre-flight-check.md') }
        'kiro'          { Deploy-File 'adapters/kiro/pre-flight-check.md' (Join-Path $target '.kiro\steering\pre-flight-check.md') }
        'roo'           { Deploy-File 'adapters/roo/pre-flight-check.md' (Join-Path $target '.roo\rules\pre-flight-check.md') }
        'agents-skills' { Deploy-File "skills/$SkillName/SKILL.md" (Join-Path $target ".agents\skills\$SkillName\SKILL.md") }
    }

    Write-Ok "Installed for $T"
}

function Uninstall-OneTool {
    param([string]$T)
    Write-Step "Uninstalling $T"
    $removed = 0
    foreach ($p in (Get-AdapterPaths $T) + (Get-ScriptDest $T)) {
        if (Test-Path $p) {
            Remove-Item -LiteralPath $p -Force
            $removed++
        }
    }
    if ($removed -eq 0) {
        Write-Warn2 "Nothing to remove for $T at $target"
    } else {
        Write-Ok "Removed $removed file(s) for $T"
    }
}

# ---------- main ----------
if (-not $Uninstall) {
    $py = Test-Python
}

$toolsToRun = if ($Tool -eq 'all') {
    @('claude','codex','gemini','cursor','copilot','windsurf','cline','kiro','roo','agents-skills')
} else { @($Tool) }

if ($Uninstall) {
    foreach ($t in $toolsToRun) { Uninstall-OneTool $t }
    return
}

foreach ($t in $toolsToRun) { Install-OneTool $t }

Write-Host ''
Write-Ok 'Done.'
Write-Host ''
Write-Host "  Tool(s):   $($toolsToRun -join ' ')"
Write-Host "  Scope:     $scope"
Write-Host "  Target:    $target"
Write-Host "  Python:    $($py.Version) ($($py.Path))"
Write-Host "  Source:    $(if ($localRepo) { $localRepo } else { "$Repo@$Ref" })"
Write-Host ''
Write-Host 'Next steps:'
Write-Host "  1. Open your AI tool in the project root: $target"
Write-Host '  2. The skill / rule / instruction file is auto-discovered.'
Write-Host "  3. Ask your agent to 'run pre-flight check' — it should invoke:"
$firstTool = $toolsToRun[0]
switch ($firstTool) {
    'claude'        { Write-Host "       python `"$target\.claude\skills\$SkillName\scripts\run-pipeline.py`"" }
    'agents-skills' { Write-Host "       python `"$target\.agents\skills\$SkillName\scripts\run-pipeline.py`"" }
    default         { Write-Host "       python `"$target\.$SkillName\scripts\run-pipeline.py`"" }
}
Write-Host ''
Write-Host 'Uninstall: re-run with -Uninstall (and the same -Tool flag).'
