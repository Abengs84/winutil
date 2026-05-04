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

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Invoke-WPFUIThread -ScriptBlock {
                Set-WinUtilProgressbar -label 'Installing Abitti Candidate...' -percent 50
            }
            Install-AbittiCandidate
            Invoke-WPFUIThread -ScriptBlock {
                Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark'
                $sync.progressBarTextBlock.Text = ''
                $sync.progressBarTextBlock.ToolTip = ''
                $sync.ProgressBar.Value = 0
                if ($sync.WPFAbittiVersionDisplay) {
                    try {
                        $sync.WPFAbittiVersionDisplay.Text = Get-AbittiVersionDisplayString
                    } catch { }
                }
                try {
                    $sync.Form.Activate() | Out-Null
                    $sync.Form.Focus() | Out-Null
                } catch { }
            }
        } catch {
            $err = "Abitti install error: $_"
            Write-Host $err
            Invoke-WPFUIThread -ScriptBlock {
                Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning'
                $sync.progressBarTextBlock.Text = ''
                $sync.progressBarTextBlock.ToolTip = ''
                $sync.ProgressBar.Value = 0
                Hide-WPFInstallAppBusy
                try {
                    $sync.Form.Activate() | Out-Null
                } catch { }
            }
        } finally {
            $sync.ProcessRunning = $false
            Invoke-WPFUIThread -ScriptBlock {
                Hide-WPFInstallAppBusy
                try {
                    $sync.Form.Activate() | Out-Null
                } catch { }
            }
        }
    } | Out-Null
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
