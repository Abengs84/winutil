#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sysadmin provisioning entry point for this WinUtil fork (custom layer only).

.EXAMPLE
    .\setup.ps1 -Profile Asus    .\setup.ps1 -Profile ThinkPad
    .\setup.ps1 -InstallAbitti
    .\setup.ps1 -Profile ThinkPad -InstallAbitti
#>
[CmdletBinding()]
param(
    [string]$Profile,

    [switch]$InstallAbitti,

    [switch]$SkipTweaks
)

if ($Profile -and $Profile -notin @('Asus', 'ThinkPad')) {
    throw "Invalid -Profile '$Profile'. Use 'Asus', 'ThinkPad', or omit."
}

$ErrorActionPreference = 'Stop'

$customRoot = $PSScriptRoot
. (Join-Path $customRoot 'lib\SetupLogging.ps1')

Write-SetupLog "Log file: $($script:CustomSetupLogPath)" 'INFO'
Write-SetupLog 'Starting custom sysadmin provisioning run.' 'INFO'

if (-not $SkipTweaks) {
    . (Join-Path $customRoot 'lib\SysadminTweaks.ps1')
    Invoke-SysadminProvisioningTweaks
} else {
    Write-SetupLog 'Skipped built-in sysadmin tweaks (-SkipTweaks).' 'WARN'
}

if ($InstallAbitti) {
    . (Join-Path $customRoot 'apps\abitti.ps1')
    Install-AbittiCandidate
}

switch ($Profile) {
    'Asus' {
        . (Join-Path $customRoot 'devices\profiles\asus-vivobook.ps1')
        Invoke-AsusVivoBookDeviceReset
    }
    'ThinkPad' {
        . (Join-Path $customRoot 'devices\profiles\lenovo-thinkpad.ps1')
        Invoke-LenovoThinkPadDeviceReset
    }
    default {
        Write-SetupLog 'No hardware profile selected (omit -Profile or use Asus | ThinkPad).' 'INFO'
    }
}

Write-SetupLog 'Custom sysadmin provisioning run completed.' 'SUCCESS'
