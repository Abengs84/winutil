[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://dl.abitti.fi/AbittiCandidateInstaller.msi',
    [string]$InstallerPath = $(Join-Path $env:TEMP 'AbittiCandidateInstaller.msi'),
    [string]$MsiLogPath = $(Join-Path $env:TEMP 'abitti-msi.log'),
    [string]$QuickScriptUrl = 'https://raw.githubusercontent.com/Abengs84/winutil/main/abitti-quick-install.ps1'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Relaunch elevated when command is started from non-admin terminal.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host '[Abitti] Admin rights required. Requesting elevation...'
    $cmd = @"
`$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; irm '$QuickScriptUrl' | iex
"@
    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-ExecutionPolicy', 'Bypass',
        '-NoProfile',
        '-Command', $cmd
    ) -Verb RunAs | Out-Null
    return
}

Write-Host '[Abitti] Starting quick install...'

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    Write-Host "[Abitti] Downloading MSI to: $InstallerPath"
    $parent = Split-Path -Parent $InstallerPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing -TimeoutSec 90 -ErrorAction Stop
} else {
    Write-Host "[Abitti] Reusing existing MSI: $InstallerPath"
}

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw "Installer file missing: $InstallerPath"
}

Write-Host "[Abitti] Running msiexec (log: $MsiLogPath)"
$proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList @(
    '/i', $InstallerPath,
    '/qn',
    '/norestart',
    '/L*v', $MsiLogPath
) -Wait -PassThru

switch ($proc.ExitCode) {
    0 {
        Write-Host '[Abitti] Install completed successfully (exit 0).'
        break
    }
    3010 {
        Write-Host '[Abitti] Install completed; restart recommended (exit 3010).'
        break
    }
    default {
        throw "Abitti installation failed with exit code $($proc.ExitCode). See: $MsiLogPath"
    }
}
