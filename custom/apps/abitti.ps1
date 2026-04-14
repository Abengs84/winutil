# Abitti2 Candidate - silent MSI install (dot-source from setup.ps1).

if (-not (Get-Command Write-SetupLog -ErrorAction SilentlyContinue)) {
    $logLib = Join-Path $PSScriptRoot '..\lib\SetupLogging.ps1'
    if (Test-Path -LiteralPath $logLib) { . $logLib }
}

function Test-AbittiCandidateInstalled {
    return ($null -ne (Get-AbittiInstalledDetails))
}

function Get-AbittiInstalledDetails {
    <#
    .SYNOPSIS
        Reads Abitti from HKLM Uninstall (same source as Apps & Features).
    #>
    $uninstallRoots = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $uninstallRoots) {
        $hits = @(Get-ItemProperty $root -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.DisplayName -like '*Abitti*' })
        if ($hits.Count -gt 0) {
            $h = $hits[0]
            return [pscustomobject]@{
                DisplayName    = $h.DisplayName
                DisplayVersion = $h.DisplayVersion
                Publisher      = $h.Publisher
            }
        }
    }
    return $null
}

function Get-AbittiVersionDisplayString {
    $d = Get-AbittiInstalledDetails
    if (-not $d) {
        return 'Not installed'
    }
    $ver = $d.DisplayVersion
    if ([string]::IsNullOrWhiteSpace($ver)) {
        $ver = 'unknown'
    }
    return "$($d.DisplayName)  |  Version $ver"
}

function Install-AbittiCandidate {
    <#
    .SYNOPSIS
        Downloads the official Abitti Candidate MSI and installs silently (/qn).
        Re-runs are safe: skips when Abitti is already registered as installed.
    #>
    param(
        [string]$DownloadUrl = 'https://dl.abitti.fi/AbittiCandidateInstaller.msi',

        [string]$InstallerPath = $(Join-Path $env:TEMP 'Abitti.msi')
    )

    Write-SetupLog 'Abitti Candidate: starting installer workflow.' 'INFO'

    if (Test-AbittiCandidateInstalled) {
        Write-SetupLog 'Abitti Candidate appears already installed (Uninstall registry). Skipping reinstall.' 'INFO'
        return
    }

    try {
        if (-not (Test-Path -LiteralPath $InstallerPath)) {
            Write-SetupLog "Downloading installer to `"$InstallerPath`" ..." 'INFO'
            $parent = Split-Path -Parent $InstallerPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing
        } else {
            Write-SetupLog "Installer already present at `"$InstallerPath`"; reusing file." 'INFO'
        }

        if (-not (Test-Path -LiteralPath $InstallerPath)) {
            throw "Installer missing after download: $InstallerPath"
        }
    } catch {
        Write-SetupLog "Abitti download or file check failed: $_" 'ERROR'
        throw
    }

    Write-SetupLog 'Running msiexec /qn (silent, no restart) ...' 'INFO'
    $msiArgs = "/i `"$InstallerPath`" /qn /norestart"
    $proc = Start-Process -FilePath msiexec.exe -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

    $code = $proc.ExitCode
    if ($code -eq 0) {
        Write-SetupLog "Abitti Candidate install completed (exit $code)." 'SUCCESS'
    } elseif ($code -eq 3010) {
        Write-SetupLog "Abitti Candidate install completed; reboot recommended (exit $code)." 'SUCCESS'
    } else {
        Write-SetupLog "Abitti Candidate install failed (msiexec exit $code)." 'ERROR'
        throw "msiexec exited with $code"
    }
}
