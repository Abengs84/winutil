#Requires -Version 5.1
<#
.SYNOPSIS
    Build winutil.ps1 locally, then publish a GitHub Release (for irm .../releases/latest/download/winutil.ps1).

.DESCRIPTION
    Requires GitHub CLI:  winget install GitHub.cli
    One-time auth:       gh auth login

.EXAMPLE
    .\Publish-ForkRelease.ps1
    .\Publish-ForkRelease.ps1 -Tag "26.04.15"
    .\Publish-ForkRelease.ps1 -SkipCompile
#>
[CmdletBinding()]
param(
    [string]$Tag,

    [switch]$SkipCompile,

    [string]$Repo = 'Abengs84/winutil'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not $SkipCompile) {
    Write-Host 'Running Compile.ps1 ...' -ForegroundColor Cyan
    & (Join-Path $root 'Compile.ps1')
}

$artifact = Join-Path $root 'winutil.ps1'
if (-not (Test-Path -LiteralPath $artifact)) {
    throw "Missing $artifact. Run .\Compile.ps1 first."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw @"
GitHub CLI (gh) not found. Install it, then run: gh auth login

  winget install --id GitHub.cli
"@
}

if (-not $Tag) {
    $Tag = Get-Date -Format 'yy.MM.dd-HHmm'
}

Write-Host "Creating release $Tag on $Repo ..." -ForegroundColor Cyan

$notes = "Local build: winutil.ps1 from Compile.ps1 ($([DateTime]::Now.ToString('yyyy-MM-dd HH:mm')))"

gh release create $Tag `
    $artifact `
    --repo $Repo `
    --title "Release $Tag" `
    --notes $notes `
    --latest

Write-Host 'Done. Test with:' -ForegroundColor Green
Write-Host "irm `"https://github.com/$Repo/releases/latest/download/winutil.ps1`" | iex" -ForegroundColor Gray
