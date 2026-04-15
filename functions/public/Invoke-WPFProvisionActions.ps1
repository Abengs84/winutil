function Invoke-WPFProvisionDisableTipsAction {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Disabling tips and restarting Explorer...'
            Invoke-ProvisionDisableWindowsSuggestions
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host $_
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
        }
    } | Out-Null
}

function Invoke-WPFProvisionWingetUpgradeAction {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Running winget upgrade --all (may take a long time)...'
            Invoke-ProvisionWingetUpgradeAll
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host $_
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
        }
    } | Out-Null
}

function Invoke-WPFProvisionStoreUpdatesAction {
    try {
        Invoke-ProvisionOpenMicrosoftStoreUpdates
    } catch {
        [System.Windows.MessageBox]::Show("Could not open Store updates: $_", 'Provision',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFProvisionCreateUserAction {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    try {
        Invoke-ProvisionCreateLocalUserInteractive
    } catch {
        $err = $_.Exception.Message
        if ([string]::IsNullOrWhiteSpace($err)) { $err = [string]$_.ToString() }
        if ([string]::IsNullOrWhiteSpace($err)) { $err = 'Create user failed (see PowerShell window for details).' }
        [System.Windows.MessageBox]::Show($err, 'Provision',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

function Invoke-WPFProvisionWingetStoreUpgradeAction {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Running winget upgrade for Microsoft Store source...'
            Invoke-ProvisionWingetStoreUpgradeAll
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host $_
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
        }
    } | Out-Null
}

function Invoke-WPFProvisionLenovoCommercialVantageAction {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Installing Lenovo Commercial Vantage (winget)...'
            Invoke-ProvisionInstallLenovoCommercialVantage
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host $_
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
        }
    } | Out-Null
}

function Invoke-WPFUpdatesOpenSettingsAction {
    try {
        Invoke-OpenWindowsUpdateSettings
    } catch {
        [System.Windows.MessageBox]::Show("Could not open Windows Update: $_", 'Updates',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFProvisionTimeResyncAction {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ScriptBlock {
        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text 'Recycling Windows Time service...'
            Invoke-ProvisionWindowsTimeResync
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host $_
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
        }
    } | Out-Null
}
