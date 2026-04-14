# Lenovo ThinkPad - PnP device reset profile (dynamic FriendlyName matching).

if (-not (Get-Command Write-SetupLog -ErrorAction SilentlyContinue)) {
    $logLib = Join-Path $PSScriptRoot '..\..\lib\SetupLogging.ps1'
    if (Test-Path -LiteralPath $logLib) { . $logLib }
}
if (-not (Get-Command Reset-Device -ErrorAction SilentlyContinue)) {
    $utils = Join-Path $PSScriptRoot '..\utils\reset-device.ps1'
    if (Test-Path -LiteralPath $utils) { . $utils }
}

function Invoke-LenovoThinkPadDeviceReset {
    Write-SetupLog '=== Lenovo ThinkPad device profile: starting ===' 'INFO'

    $groups = @(
        @{ Label = 'Bluetooth — Intel Wireless Bluetooth'; Pattern = '*Intel*Wireless*Bluetooth*' },
        @{ Label = 'Camera — Integrated Camera'; Pattern = '*Integrated Camera*' },
        @{ Label = 'Audio — Realtek(R) Audio'; Pattern = '*Realtek(R) Audio*' },
        @{ Label = 'Audio — Intel Smart Sound Technology Microphone Array'; Pattern = '*Intel*Smart*Sound*Microphone*' },
        @{ Label = 'Input — HID-compatible mouse'; Pattern = '*HID-compliant mouse*' },
        @{ Label = 'Input — Synaptics Pointing Device'; Pattern = '*Synaptics*Pointing*Device*' },
        @{ Label = 'Input — HID Keyboard Device'; Pattern = '*HID Keyboard Device*' },
        @{ Label = 'Input — Standard PS/2 Keyboard'; Pattern = '*Standard PS/2 Keyboard*' },
        @{ Label = 'Network — Intel Wi-Fi 6E AX210'; Pattern = '*Intel*Wi-Fi*6E*AX210*' }
    )

    foreach ($g in $groups) {
        Reset-Device -Pattern $g.Pattern -GroupLabel $g.Label
    }

    Write-SetupLog '=== Lenovo ThinkPad device profile: finished ===' 'INFO'
}
