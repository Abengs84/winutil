function Invoke-WPFSystemToolDeviceManager {
    try {
        Start-Process -FilePath 'devmgmt.msc' -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("Could not start Device Manager: $_", 'System Tools',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFSystemToolGpedit {
    try {
        Start-Process -FilePath 'gpedit.msc' -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show(
            "Group Policy Editor is not available on this edition (common on Windows Home), or mmc failed: $_",
            'System Tools',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFSystemToolLusrmgr {
    try {
        Start-Process -FilePath 'lusrmgr.msc' -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show(
            "Local Users and Groups is not available on this edition, or mmc failed: $_",
            'System Tools',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning)
    }
}
