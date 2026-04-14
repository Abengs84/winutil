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

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Installing Abitti Candidate...'
            Install-AbittiCandidate
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock {
                Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark'
                if ($sync.WPFAbittiVersionDisplay) {
                    try {
                        $sync.WPFAbittiVersionDisplay.Text = Get-AbittiVersionDisplayString
                    } catch { }
                }
            }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host "Abitti install error: $_"
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
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
