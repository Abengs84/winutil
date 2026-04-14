# Asus VivoBook - PnP device reset profile (dynamic FriendlyName matching).

if (-not (Get-Command Write-SetupLog -ErrorAction SilentlyContinue)) {
    $logLib = Join-Path $PSScriptRoot '..\..\lib\SetupLogging.ps1'
    if (Test-Path -LiteralPath $logLib) { . $logLib }
}
if (-not (Get-Command Reset-Device -ErrorAction SilentlyContinue)) {
    $utils = Join-Path $PSScriptRoot '..\utils\reset-device.ps1'
    if (Test-Path -LiteralPath $utils) { . $utils }
}

function Invoke-AsusVivoBookDeviceReset {
    Write-SetupLog '=== Asus VivoBook device profile: starting ===' 'INFO'

    $groups = @(
        @{ Label = 'HID / Input — ASUS Precision Touchpad'; Pattern = '*ASUS Precision Touchpad*' },
        @{ Label = 'Audio — Realtek(R) Audio'; Pattern = '*Realtek(R) Audio*' },
        @{ Label = 'Audio — Speakers (Realtek Audio)'; Pattern = '*Speakers*Realtek*Audio*' },
        @{ Label = 'Audio — Microphone Array (Realtek Audio)'; Pattern = '*Microphone*Realtek*Audio*' },
        @{ Label = 'Network — MediaTek Wi-Fi 6 MT7921'; Pattern = '*MediaTek*MT7921*' },
        @{ Label = 'Network — MediaTek Bluetooth'; Pattern = '*MediaTek*Bluetooth*' },
        @{ Label = 'Camera — USB2.0 HD UVC WebCam'; Pattern = '*USB2.0*UVC*WebCam*' },
        @{ Label = 'Keyboard — PC/AT Enhanced PS/2 Keyboard'; Pattern = '*PC/AT*PS/2*Keyboard*' }
    )

    foreach ($g in $groups) {
        Reset-Device -Pattern $g.Pattern -GroupLabel $g.Label
    }

    Write-SetupLog '=== Asus VivoBook device profile: finished ===' 'INFO'
}
