# Dot-source to use: . "$PSScriptRoot\reset-device.ps1"
# Depends on Write-SetupLog when custom\lib\SetupLogging.ps1 was loaded first; otherwise falls back to Write-Host.

if (-not (Get-Command Write-SetupLog -ErrorAction SilentlyContinue)) {
    function Write-SetupLog {
        param([string]$Message, [string]$Level = 'INFO')
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    }
}

function Reset-Device {
    <#
    .SYNOPSIS
        Disables then re-enables all PnP devices whose FriendlyName matches a wildcard pattern.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,

        [string]$GroupLabel
    )

    $label = if ($GroupLabel) { $GroupLabel } else { $Pattern }
    Write-SetupLog "Scanning PnP devices for pattern '$Pattern' ($label)" 'INFO'

    try {
        $devices = @(Get-PnpDevice -ErrorAction Stop | Where-Object { $_.FriendlyName -like $Pattern })
    } catch {
        Write-SetupLog "Get-PnpDevice failed for group '$label': $_" 'ERROR'
        return
    }

    if ($devices.Count -eq 0) {
        Write-SetupLog "No devices matched '$Pattern' ($label); skipping." 'WARN'
        return
    }

    Write-SetupLog "Matched $($devices.Count) device(s) for '$Pattern'." 'INFO'

    foreach ($d in $devices) {
        $name = $d.FriendlyName
        $id = $d.InstanceId
        try {
            Write-SetupLog "Disable → $name" 'INFO'
            Disable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            Write-SetupLog "Enable → $name" 'INFO'
            Enable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop
            Write-SetupLog "Reset OK: $name" 'SUCCESS'
        } catch {
            Write-SetupLog "Reset failed for '$name' ($id): $_" 'ERROR'
        }
    }
}
