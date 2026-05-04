function Invoke-WPFInstallAbittiCandidate {
    <#
    .SYNOPSIS
        GUI action: silent install of Abitti Candidate MSI (fork custom layer).
    #>
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Write-Host ''
    Write-Host "[WinUtil] Abitti 2 Candidate: installation startad i bakgrunden. Logg (samma som setup): $($sync.CustomSetupLogPath)" -ForegroundColor Cyan
    Write-Host '[WinUtil] Folj raderna nedan under nedladdning och msiexec (kan ta flera minuter).' -ForegroundColor DarkGray
    try {
        if (-not (Test-Path -LiteralPath $sync.CustomSetupLogPath)) {
            New-Item -ItemType File -Path $sync.CustomSetupLogPath -Force | Out-Null
        }
        Add-Content -LiteralPath $sync.CustomSetupLogPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] UI click: Abitti install button pressed." -Encoding utf8
    } catch {
        Write-Host "Could not initialize Abitti log file: $($_.Exception.Message)"
    }

    try {
        $sync.ProcessRunning = $true
        Invoke-WPFUIThread -ScriptBlock {
            Set-WinUtilProgressbar -label 'Starting Abitti installer process...' -percent 20
            Set-WinUtilTaskbaritem -state 'Normal' -overlay 'download'
        }

        $bootstrapName = "winutil-abitti-install-{0:yyyyMMdd-HHmmss}.ps1" -f (Get-Date)
        $bootstrapPath = Join-Path $env:TEMP $bootstrapName
        $bootstrap = @"
`$ErrorActionPreference = 'Stop'
`$sync = [hashtable]::Synchronized(@{})
`$sync.CustomSetupLogPath = '$($sync.CustomSetupLogPath)'
. '$($sync.PSScriptRoot)\custom\lib\SetupLogging.ps1'
. '$($sync.PSScriptRoot)\custom\apps\abitti.ps1'
Write-SetupLog 'Abitti background installer process started.' 'INFO'
Install-AbittiCandidate
Write-SetupLog 'Abitti background installer process finished.' 'SUCCESS'
"@
        Set-Content -LiteralPath $bootstrapPath -Value $bootstrap -Encoding ascii

        $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell.exe' }
        $args = @(
            '-ExecutionPolicy', 'Bypass',
            '-NoProfile',
            '-File', $bootstrapPath
        )
        $proc = Start-Process -FilePath $psExe -ArgumentList $args -PassThru
        Write-Host "[WinUtil] Abitti installer started in separate process (PID $($proc.Id))."
        Write-Host "[WinUtil] Follow this log for progress: $($sync.CustomSetupLogPath)"
    } catch {
        $err = "Abitti launcher error: $_"
        Write-Host $err
        Invoke-WPFUIThread -ScriptBlock {
            Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning'
            $sync.progressBarTextBlock.Text = ''
            $sync.progressBarTextBlock.ToolTip = ''
            $sync.ProgressBar.Value = 0
        }
    } finally {
        $sync.ProcessRunning = $false
    }
}

function Invoke-WPFApplySysadminProvisioningTweaks {
    <#
    .SYNOPSIS
        GUI action: registry tweaks from custom SysadminTweaks module.
    #>
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Applying provisioning tweaks...'
            Invoke-SysadminProvisioningTweaks
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host "Provisioning tweaks error: $_"
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
        }
    } | Out-Null
}
