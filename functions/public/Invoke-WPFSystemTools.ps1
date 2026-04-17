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

function Get-WinUtilExeCandidatesInUserDownloads {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$NamePredicate
    )
    $root = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserDownloads)
    if (-not (Test-Path -LiteralPath $root)) {
        return @()
    }
    $exes = @(Get-ChildItem -LiteralPath $root -Filter *.exe -File -ErrorAction SilentlyContinue)
    foreach ($dir in (Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
        $exes += Get-ChildItem -LiteralPath $dir.FullName -Filter *.exe -File -ErrorAction SilentlyContinue
    }
    return @($exes | Where-Object { & $NamePredicate $_.Name } | Sort-Object LastWriteTime -Descending)
}

function Invoke-WPFOpenDellWd19FirmwareSupport {
    try {
        Invoke-OpenDellWd19FirmwareSupportPage
    } catch {
        [System.Windows.MessageBox]::Show("Could not open browser: $_", 'Dock',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFRunDellDockFirmwareUtility {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $pred = {
        param([string]$name)
        $n = $name.ToLowerInvariant()
        ($n -match 'dell' -and ($n -match 'dock|firmware|wd19|wd22')) -or
        ($n -match 'dock' -and $n -match 'firmware' -and $n -match 'dell')
    }
    $candidates = Get-WinUtilExeCandidatesInUserDownloads -NamePredicate $pred
    if ($candidates.Count -eq 0) {
        $pred2 = {
            param([string]$name)
            $n = $name.ToLowerInvariant()
            ($n -match 'wd19|wd22') -or ($n -match 'dock' -and $n -match 'firmware')
        }
        $candidates = Get-WinUtilExeCandidatesInUserDownloads -NamePredicate $pred2
    }
    $pick = $null
    if ($candidates.Count -eq 1) {
        $pick = $candidates[0].FullName
    } elseif ($candidates.Count -gt 1) {
        $lines = 0..([Math]::Min(8, $candidates.Count - 1)) | ForEach-Object {
            "$($_ + 1). $($candidates[$_].Name)  ($($candidates[$_].LastWriteTime))"
        }
        $msg = "Multiple matches in your Downloads folder.`n`n$($lines -join "`n")`n`nOpen the newest file?`n$($candidates[0].FullName)"
        $ans = [System.Windows.Forms.MessageBox]::Show($msg, 'Dock',
            [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
            $pick = $candidates[0].FullName
        }
    }
    if (-not $pick) {
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = 'Executable (*.exe)|*.exe|All files (*.*)|*.*'
        $dlg.Title = 'Select Dell dock firmware utility'
        $dlg.InitialDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserDownloads)
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }
        $pick = $dlg.FileName
    }
    try {
        Start-Process -FilePath $pick -Verb RunAs -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("Could not start utility: $_", 'Dock',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFInstallLenovoHybridDockFirmwareTool {
    try {
        $path = Invoke-DownloadLenovoThinkPadHybridUsbCDockFirmwareTool
        [System.Windows.MessageBox]::Show("Saved to:`n$path", 'Dock',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Download failed: $_`n`nTry the Lenovo support page from the tool tip or update the download URL in the script.", 'Dock',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}

function Invoke-WPFRunLenovoHybridDockFirmwareFromDownloads {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $pred = {
        param([string]$name)
        $n = $name.ToLowerInvariant()
        $n -match 'fhybd|hybrid' -or ($n -match 'lenovo' -and $n -match 'dock') -or $n -match '40af'
    }
    $candidates = Get-WinUtilExeCandidatesInUserDownloads -NamePredicate $pred
    if ($candidates.Count -eq 0) {
        $pred2 = { param([string]$name) $name.ToLowerInvariant() -match 'fhybd\d+' }
        $candidates = Get-WinUtilExeCandidatesInUserDownloads -NamePredicate $pred2
    }
    $pick = $null
    if ($candidates.Count -eq 1) {
        $pick = $candidates[0].FullName
    } elseif ($candidates.Count -gt 1) {
        $lines = 0..([Math]::Min(8, $candidates.Count - 1)) | ForEach-Object {
            "$($_ + 1). $($candidates[$_].Name)  ($($candidates[$_].LastWriteTime))"
        }
        $msg = "Multiple matches in Downloads.`n`n$($lines -join "`n")`n`nRun the newest file?`n$($candidates[0].FullName)"
        $ans = [System.Windows.Forms.MessageBox]::Show($msg, 'Dock',
            [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
            $pick = $candidates[0].FullName
        }
    }
    if (-not $pick) {
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = 'Executable (*.exe)|*.exe|All files (*.*)|*.*'
        $dlg.Title = 'Select Lenovo Hybrid USB-C Dock firmware tool'
        $dlg.InitialDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserDownloads)
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }
        $pick = $dlg.FileName
    }
    try {
        Start-Process -FilePath $pick -Verb RunAs -ErrorAction Stop
    } catch {
        [System.Windows.MessageBox]::Show("Could not start utility: $_", 'Dock',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }
}
