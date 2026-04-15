function Invoke-WPFButton {

    <#

    .SYNOPSIS
        Invokes the function associated with the clicked button

    .PARAMETER Button
        The name of the button that was clicked

    #>

    Param ([string]$Button)

    # Use this to get the name of the button
    #[System.Windows.MessageBox]::Show("$Button","Chris Titus Tech's Windows Utility","OK","Info")
    if (-not $sync.ProcessRunning) {
        Set-WinUtilProgressBar  -label "" -percent 0
    }

    # Check if button is defined in feature config with function or InvokeScript
    if ($sync.configs.feature.$Button) {
        $buttonConfig = $sync.configs.feature.$Button

        # If button has a function defined, call it
        if ($buttonConfig.function) {
            $functionName = $buttonConfig.function
            if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                & $functionName
                return
            }
        }

        # If button has InvokeScript defined, execute the scripts
        if ($buttonConfig.InvokeScript -and $buttonConfig.InvokeScript.Count -gt 0) {
            foreach ($script in $buttonConfig.InvokeScript) {
                if (-not [string]::IsNullOrWhiteSpace($script)) {
                    Invoke-Expression $script
                }
            }
            return
        }
    }

    # Fallback to hard-coded switch for buttons not in feature.json
    Switch -Wildcard ($Button) {
        "WPFTab?BT" {Invoke-WPFTab $Button}
        "WPFInstall" {Invoke-WPFInstall}
        "WPFUninstall" {Invoke-WPFUnInstall}
        "WPFInstallUpgrade" {Invoke-WPFInstallUpgrade}
        "WPFCollapseAllCategories" {Invoke-WPFToggleAllCategories -Action "Collapse"}
        "WPFExpandAllCategories" {Invoke-WPFToggleAllCategories -Action "Expand"}
        "WPFStandard" {Invoke-WPFPresets "Standard" -checkboxfilterpattern "WPFTweak*"}
        "WPFMinimal" {Invoke-WPFPresets "Minimal" -checkboxfilterpattern "WPFTweak*"}
        "WPFClearTweaksSelection" {Invoke-WPFPresets -imported $true -checkboxfilterpattern "WPFTweak*"}
        "WPFClearInstallSelection" {Invoke-WPFPresets -imported $true -checkboxfilterpattern "WPFInstall*"}
        "WPFtweaksbutton" {Invoke-WPFtweaksbutton}
        "WPFOOSUbutton" {Invoke-WPFOOSU}
        "WPFAddUltPerf" {Invoke-WPFUltimatePerformance -Do}
        "WPFRemoveUltPerf" {Invoke-WPFUltimatePerformance}
        "WPFundoall" {Invoke-WPFundoall}
        "WPFUpdatesdefault" {Invoke-WPFUpdatesdefault}
        "WPFUpdatesdisable" {Invoke-WPFUpdatesdisable}
        "WPFUpdatessecurity" {Invoke-WPFUpdatessecurity}
        "WPFGetInstalled" {Invoke-WPFGetInstalled -CheckBox "winget"}
        "WPFGetInstalledTweaks" {Invoke-WPFGetInstalled -CheckBox "tweaks"}
        "WPFCloseButton" {$sync.Form.Close(); Write-Host "Bye bye!"}
        "WPFselectedAppsButton" {$sync.selectedAppsPopup.IsOpen = -not $sync.selectedAppsPopup.IsOpen}
        "WPFToggleFOSSHighlight" {
            if ($sync.WPFToggleFOSSHighlight.IsChecked) {
                 $sync.Form.Resources["FOSSColor"] = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(76, 175, 80)) # #4CAF50
            } else {
                 $sync.Form.Resources["FOSSColor"] = $sync.Form.Resources["MainForegroundColor"]
            }
        }
        "WPFAbittiInstallButton" { Invoke-WPFInstallAbittiCandidate }
        "WPFAbittiRefreshButton" { Update-WPFAbittiVersionDisplay }
        "WPFProvisionTweaksButton" { Invoke-WPFApplySysadminProvisioningTweaks }
        "WPFProvisionDisableTipsButton" { Invoke-WPFProvisionDisableTipsAction }
        "WPFProvisionWingetUpgradeButton" { Invoke-WPFProvisionWingetUpgradeAction }
        "WPFProvisionStoreUpdatesButton" { Invoke-WPFProvisionStoreUpdatesAction }
        "WPFProvisionWingetStoreUpgradeButton" { Invoke-WPFProvisionWingetStoreUpgradeAction }
        "WPFProvisionLenovoVantageButton" { Invoke-WPFProvisionLenovoCommercialVantageAction }
        "WPFProvisionNewUserButton" { Invoke-WPFProvisionCreateUserAction }
        "WPFProvisionTimeResyncButton" { Invoke-WPFProvisionTimeResyncAction }
        "WPFtrouble_scan" { Update-WPFTroubleshootTabDisplay }
        "WPFtrouble_restart_network" { Invoke-WPFTroubleshootRestartGroup -GroupKey network }
        "WPFtrouble_restart_bluetooth" { Invoke-WPFTroubleshootRestartGroup -GroupKey bluetooth }
        "WPFtrouble_restart_audio" { Invoke-WPFTroubleshootRestartGroup -GroupKey audio }
        "WPFtrouble_restart_camera" { Invoke-WPFTroubleshootRestartGroup -GroupKey camera }
        "WPFtrouble_restart_pointing" { Invoke-WPFTroubleshootRestartGroup -GroupKey pointing }
        "WPFtrouble_restart_keyboard" { Invoke-WPFTroubleshootRestartGroup -GroupKey keyboard }
        "WPFsys_devmgmt" { Invoke-WPFSystemToolDeviceManager }
        "WPFsys_gpedit" { Invoke-WPFSystemToolGpedit }
        "WPFsys_lusrmgr" { Invoke-WPFSystemToolLusrmgr }
        "WPFsys_netplwiz" { Invoke-WPFSystemToolNetplwiz }
        "WPFsys_dellwd19_page" { Invoke-WPFOpenDellWd19FirmwareSupport }
        "WPFsys_dellwd19_run" { Invoke-WPFRunDellDockFirmwareUtility }
        "WPFUpdatesOpenSettings" { Invoke-WPFUpdatesOpenSettingsAction }
    }
}
