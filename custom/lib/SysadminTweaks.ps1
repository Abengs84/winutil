# Lightweight provisioning tweaks that do not require the WinUtil UI or compiled bundle.
# Safe to run headless; does not modify WinUtil upstream behavior.

if (-not (Get-Command Write-SetupLog -ErrorAction SilentlyContinue)) {
    $logLib = Join-Path $PSScriptRoot 'SetupLogging.ps1'
    if (Test-Path -LiteralPath $logLib) { . $logLib }
}

function Invoke-SysadminProvisioningTweaks {
    Write-SetupLog 'Applying built-in sysadmin provisioning tweaks (registry).' 'INFO'

    try {
        $longPathKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
        $current = Get-ItemProperty -Path $longPathKey -Name 'LongPathsEnabled' -ErrorAction SilentlyContinue
        if (-not $current -or $current.LongPathsEnabled -ne 1) {
            New-ItemProperty -Path $longPathKey -Name 'LongPathsEnabled' -Value 1 -PropertyType DWord -Force | Out-Null
            Write-SetupLog 'Enabled NTFS long paths (LongPathsEnabled=1).' 'SUCCESS'
        } else {
            Write-SetupLog 'Long paths already enabled; no change.' 'INFO'
        }
    } catch {
        Write-SetupLog "Tweak failed (long paths): $_" 'WARN'
    }

    Write-SetupLog 'Sysadmin provisioning tweaks section finished.' 'INFO'
}
