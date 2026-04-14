function Update-WPFTroubleshootTabDisplay {
    <#
    .SYNOPSIS
        Scans PnP devices and fills Troubleshoot tab text boxes; stores InstanceIds on $sync.
    #>
    if ($PARAM_NOUI) { return }

    $catalog = Get-TroubleshootGroupCatalog
    if (-not $sync.troubleshootDeviceIds) {
        $sync.troubleshootDeviceIds = @{}
    }

    try {
        $allDevices = @(Get-PnpDevice -ErrorAction Stop)
    } catch {
        Write-Host "Get-PnpDevice failed: $_"
        return
    }

    $labelMap = @{}

    foreach ($key in $catalog.Keys) {
        $meta = $catalog[$key]
        $idSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $lines = New-Object System.Collections.Generic.List[string]

        foreach ($pattern in $meta.Patterns) {
            foreach ($d in $allDevices) {
                if (-not $d.FriendlyName) { continue }
                if ($d.FriendlyName -notlike $pattern) { continue }
                if ($idSet.Add($d.InstanceId)) {
                    $lines.Add("$($d.FriendlyName)  [Status: $($d.Status)]")
                }
            }
        }

        $sync.troubleshootDeviceIds[$key] = $idSet.ToArray()

        if ($lines.Count -gt 0) {
            $labelMap[$key] = ($lines -join "`r`n")
        } else {
            $labelMap[$key] = '(No matching devices found.)'
        }
    }

    $sync.troubleshootLabelMap = $labelMap
    Invoke-WPFUIThread -ScriptBlock {
        if (-not $sync.troubleshootLabelMap) { return }
        foreach ($k in @($sync.troubleshootLabelMap.Keys)) {
            $tb = $sync."WPFtrouble_list_$k"
            if ($tb) {
                $tb.Text = [string]$sync.troubleshootLabelMap[$k]
            }
        }
    }
}

function Invoke-WPFTroubleshootRestartGroup {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('network', 'bluetooth', 'audio', 'camera', 'pointing', 'keyboard')]
        [string]$GroupKey
    )

    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show('Another WinUtil task is already running.', 'Winutil',
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $ids = @()
    if ($sync.troubleshootDeviceIds -and $sync.troubleshootDeviceIds[$GroupKey]) {
        $ids = $sync.troubleshootDeviceIds[$GroupKey]
    }

    if (-not $ids -or $ids.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "No devices listed for this group. Click `"Scan devices`" on the Troubleshoot tab first.",
            'Troubleshoot',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information)
        return
    }

    $catalog = Get-TroubleshootGroupCatalog
    $title = $catalog[$GroupKey].Title

    $confirm = [System.Windows.MessageBox]::Show(
        "Restart $($ids.Count) device(s) in `"$title`"? Input may pause briefly.",
        'Confirm device restart',
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    Invoke-WPFRunspace -ScriptBlock {
        param($GroupKey, $Title, $Ids)

        try {
            $sync.ProcessRunning = $true
            Show-WPFInstallAppBusy -text "Restarting: $Title ..."
            Reset-PnpDeviceInstanceIds -InstanceIds $Ids -GroupLabel $Title
            Hide-WPFInstallAppBusy
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'None' -overlay 'checkmark' }
        } catch {
            Hide-WPFInstallAppBusy
            Write-Host $_
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state 'Error' -overlay 'warning' }
        } finally {
            $sync.ProcessRunning = $false
            Update-WPFTroubleshootTabDisplay
        }
    } -ParameterList @(
        @('GroupKey', $GroupKey),
        @('Title', $title),
        @('Ids', $ids)
    ) | Out-Null
}
