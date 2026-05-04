#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://dl.abitti.fi/AbittiCandidateInstaller.msi',
    [string]$InstallerPath = $(Join-Path $env:TEMP 'AbittiCandidateInstaller.msi'),
    [string]$MsiLogPath = $(Join-Path $env:TEMP 'abitti-msi.log')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
