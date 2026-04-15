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

function Invoke-WPFSystemToolNetplwiz {
    try {
        Start-Process -FilePath 'netplwiz.exe' -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("Could not start netplwiz: $_", 'System Tools',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFOpenDellWd19FirmwareSupport {
    try {
        Invoke-OpenDellWd19FirmwareSupportPage
    } catch {
        [System.Windows.MessageBox]::Show("Could not open browser: $_", 'System Tools',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFRunDellDockFirmwareUtility {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'Executable (*.exe)|*.exe|All files (*.*)|*.*'
    $dlg.Title = 'Select Dell Dock Firmware Update Utility (download from Dell first)'
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        return
    }
    try {
        Start-Process -FilePath $dlg.FileName -Verb RunAs -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("Could not start utility: $_", 'System Tools',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}
