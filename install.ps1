<#
.SYNOPSIS
    pre-flight-check — installer (Windows / PowerShell).

.DESCRIPTION
    Installs the pre-flight-check Claude Code skill either globally
    (%USERPROFILE%\.claude\skills\) or into the current project
    (.\.claude\skills\).

.PARAMETER Project
    Install into the current directory's .claude\skills\ instead of the global location.

.PARAMETER Dir
    Install into a custom .claude\skills\ parent directory.

.PARAMETER Ref
    Git ref (branch/tag/sha) to download from. Default: main.

.PARAMETER Force
    Overwrite an existing install without prompting.

.PARAMETER Uninstall
    Remove an existing install instead of installing.

.EXAMPLE
    irm https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.ps1 | iex

.EXAMPLE
    iwr https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.ps1 -UseBasicParsing | iex; Install-PreFlightCheck -Project

.EXAMPLE
    .\install.ps1 -Project -Force
#>

[CmdletBinding()]
param(
    [switch]$Project,
    [string]$Dir,
    [string]$Ref = 'main',
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$Repo      = 'mirekondro1/The-Pre-Flight-Check'
$SkillName = 'pre-flight-check'

function Write-Step  { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "✓  $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "!  $Msg" -ForegroundColor Yellow }
function Throw-Die   { param([string]$Msg) Write-Host "✗  $Msg" -ForegroundColor Red; throw $Msg }

# ---------- resolve destination ----------
if     ($Dir)     { $parent = (Resolve-Path -LiteralPath $Dir -ErrorAction SilentlyContinue) ; if (-not $parent) { $parent = $Dir }; $scope = 'custom' }
elseif ($Project) { $parent = Join-Path (Get-Location) '.claude\skills'; $scope = 'project' }
else              { $parent = Join-Path $env:USERPROFILE '.claude\skills'; $scope = 'global' }

$dest = Join-Path $parent $SkillName

# ---------- uninstall ----------
if ($Uninstall) {
    if (Test-Path $dest) {
        Write-Step "Removing $dest"
        Remove-Item -Recurse -Force $dest
        Write-Ok 'Uninstalled.'
    } else {
        Write-Warn2 "Nothing to remove at $dest"
    }
    return
}

# ---------- prerequisites ----------
$py = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
if (-not $py) {
    Throw-Die 'python (3.8+) not found on PATH. Install from https://www.python.org or via winget: winget install Python.Python.3.12'
}

$pyVer = & $py.Source -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'
$verParts = $pyVer.Split('.')
$major = [int]$verParts[0]; $minor = [int]$verParts[1]
if (($major -lt 3) -or ($major -eq 3 -and $minor -lt 8)) {
    Throw-Die "Python $pyVer too old. Need Python ≥3.8."
}

# ---------- existing install ----------
if ((Test-Path $dest) -and (-not $Force)) {
    if ([Environment]::UserInteractive -and $Host.UI.RawUI) {
        $reply = Read-Host "?  $dest exists. Overwrite? [y/N]"
        if ($reply -notmatch '^(y|Y|yes|YES)$') { Throw-Die 'Aborted.' }
    } else {
        Throw-Die "$dest already exists. Re-run with -Force to overwrite."
    }
}

# ---------- locate source ----------
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { $null }
$localSrc  = $null
if ($scriptDir -and (Test-Path (Join-Path $scriptDir "skills\$SkillName\SKILL.md"))) {
    $localSrc = Join-Path $scriptDir "skills\$SkillName"
}

New-Item -ItemType Directory -Force -Path (Join-Path $dest 'scripts') | Out-Null

if ($localSrc) {
    Write-Step "Installing from local clone: $localSrc"
    Copy-Item (Join-Path $localSrc 'SKILL.md')                  (Join-Path $dest 'SKILL.md')                  -Force
    Copy-Item (Join-Path $localSrc 'scripts\run-pipeline.py')   (Join-Path $dest 'scripts\run-pipeline.py')   -Force
} else {
    $base = "https://raw.githubusercontent.com/$Repo/$Ref/skills/$SkillName"
    Write-Step "Downloading from $base"
    try {
        Invoke-WebRequest -Uri "$base/SKILL.md"                -OutFile (Join-Path $dest 'SKILL.md')                -UseBasicParsing
        Invoke-WebRequest -Uri "$base/scripts/run-pipeline.py" -OutFile (Join-Path $dest 'scripts\run-pipeline.py') -UseBasicParsing
    } catch {
        Throw-Die "Download failed: $($_.Exception.Message)"
    }
}

# ---------- summary ----------
Write-Host ''
Write-Ok "Installed pre-flight-check → $dest"
Write-Host ''
Write-Host "  Scope:   $scope"
Write-Host "  Python:  $pyVer ($($py.Source))"
Write-Host "  Source:  $(if ($localSrc) { $localSrc } else { "$Repo@$Ref" })"
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Open Claude Code in a project root.'
Write-Host "  2. The skill is auto-discovered — ask Claude to 'run pre-flight check'."
Write-Host '  3. Or run it directly:'
Write-Host "       python `"$dest\scripts\run-pipeline.py`""
Write-Host ''
Write-Host 'Uninstall: re-run with -Uninstall (same scope switch).'
