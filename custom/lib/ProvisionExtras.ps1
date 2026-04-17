# New-computer / provision actions (fork). Requires elevated WinUtil.

if (-not (Get-Command Write-SetupLog -ErrorAction SilentlyContinue)) {
    $logLib = Join-Path $PSScriptRoot 'SetupLogging.ps1'
    if (Test-Path -LiteralPath $logLib) { . $logLib }
}

function Invoke-ProvisionDisableWindowsSuggestions {
    Write-SetupLog 'Disabling Windows tips / suggestions (ContentDeliveryManager).' 'INFO'
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    $dwordProps = [ordered]@{
        SoftLandingEnabled = 0
        'SubscribedContent-338389Enabled'   = 0
        'SubscribedContent-338393Enabled'   = 0
        'SubscribedContent-310093Enabled'   = 0
        'SubscribedContent-353694Enabled'   = 0
        'SubscribedContent-353696Enabled'   = 0
    }
    foreach ($entry in $dwordProps.GetEnumerator()) {
        try {
            Set-ItemProperty -LiteralPath $path -Name $entry.Key -Value $entry.Value -Type DWord -Force -ErrorAction Stop
        } catch {
            Write-SetupLog "Set-ItemProperty $($entry.Key): $_" 'WARN'
        }
    }

    Write-SetupLog 'Restarting Explorer.' 'INFO'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process -FilePath 'explorer.exe' -ErrorAction SilentlyContinue
    Write-SetupLog 'Suggestions tweak and Explorer restart finished.' 'SUCCESS'
}

function Invoke-ProvisionWingetUpgradeAll {
    Write-SetupLog 'Running winget upgrade --all ...' 'INFO'
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'winget not found. Install App Installer from the Microsoft Store.'
    }
    $p = Start-Process -FilePath 'winget.exe' -ArgumentList @(
        'upgrade', '--all',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--include-unknown',
        '--disable-interactivity'
    ) -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -notin 0, -1978335189, -1978335188) {
        Write-SetupLog "winget exited with $($p.ExitCode)." 'WARN'
    }
    Write-SetupLog 'winget upgrade --all completed.' 'SUCCESS'
}

function Invoke-ProvisionOpenMicrosoftStoreUpdates {
    Write-SetupLog 'Opening Microsoft Store (Downloads and updates).' 'INFO'
    Start-Process -FilePath 'ms-windows-store://downloadsandupdates' -ErrorAction Stop
}

function Invoke-ProvisionWingetStoreUpgradeAll {
    <#
    .SYNOPSIS
        Upgrade packages from the msstore source (winget equivalent of applying Store updates where indexed).
    #>
    Write-SetupLog 'Running winget upgrade --all --source msstore ...' 'INFO'
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'winget not found. Install App Installer from the Microsoft Store.'
    }
    $p = Start-Process -FilePath 'winget.exe' -ArgumentList @(
        'upgrade', '--all',
        '--source', 'msstore',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--include-unknown',
        '--disable-interactivity'
    ) -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -notin 0, -1978335189, -1978335188) {
        Write-SetupLog "winget (msstore) exited with $($p.ExitCode)." 'WARN'
    }
    Write-SetupLog 'winget msstore upgrade pass completed.' 'SUCCESS'
}

function Invoke-ProvisionInstallLenovoCommercialVantage {
    Write-SetupLog 'Installing Lenovo Commercial Vantage via winget (Microsoft Store source)...' 'INFO'
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'winget not found.'
    }
    $p = Start-Process -FilePath 'winget.exe' -ArgumentList @(
        'install', '--name', 'Lenovo Commercial Vantage',
        '--source', 'msstore',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity'
    ) -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        throw "Lenovo Commercial Vantage install failed (exit $($p.ExitCode)). Run: winget search `"Lenovo`" and install the Commercial Vantage listing from msstore, or use the Microsoft Store app."
    }
    Write-SetupLog 'Lenovo Commercial Vantage install finished.' 'SUCCESS'
}

function Invoke-OpenWindowsUpdateSettings {
    Write-SetupLog 'Opening Windows Update (Settings).' 'INFO'
    Start-Process -FilePath 'ms-settings:windowsupdate' -ErrorAction Stop
}

function Invoke-OpenDellWd19FirmwareSupportPage {
    <#
 Opens Dell Drivers & Downloads for a fixed service tag. On the site, choose Windows 11
        in the operating system list, then use category / search to find Dock or Firmware utilities.
    #>
    $st = 'BRPKD44'
    $url = "https://www.dell.com/support/home/en-us/product-support/servicetag/$($st.ToLowerInvariant())/drivers"
    Write-SetupLog "Opening Dell drivers for service tag $st (select Windows 11 on the site if prompted)." 'INFO'
    Start-Process $url -ErrorAction Stop
}

function Invoke-DownloadLenovoThinkPadHybridUsbCDockFirmwareTool {
    <#
        .SYNOPSIS
 Downloads the ThinkPad Hybrid USB-C with USB-A Dock (40AF) firmware update tool from Lenovo CDN.
        .NOTES
            File name/version may change; update $DownloadUrl if Lenovo publishes a newer build.
            Support reference: https://pcsupport.lenovo.com/us/en/downloads/ds504448-firmware-update-tool-for-windows-7-10-32-bit-64-bit-thinkpad-hybrid-usb-c-with-usb-a-dock
    #>
    param(
        [string]$DownloadUrl = 'https://download.lenovo.com/pccbbs/mobiles/fhybd1042_1.exe'
    )

    $destDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserDownloads)
    if (-not (Test-Path -LiteralPath $destDir)) {
        throw "Downloads folder not found: $destDir"
    }
    $leaf = [System.IO.Path]::GetFileName(($DownloadUrl -split '\?')[0])
    $dest = Join-Path $destDir $leaf

    Write-SetupLog "Downloading Lenovo Hybrid USB-C Dock firmware tool to `"$dest`" ..." 'INFO'
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $dest -UseBasicParsing
    if (-not (Test-Path -LiteralPath $dest)) {
        throw 'Download finished but file is missing.'
    }
    Write-SetupLog 'Lenovo dock firmware tool download finished.' 'SUCCESS'
    return $dest
}

function Invoke-ProvisionCreateLocalUserInteractive {
    Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

    $name = [Microsoft.VisualBasic.Interaction]::InputBox(
        'Local account user name:',
        'Create local user',
        ''
    )
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-SetupLog 'Create user cancelled (empty name).' 'WARN'
        return
    }

    $password = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Password for `"$name`" (leave empty if allowed by policy):",
        'Create local user',
        ''
    )

    $adminAns = [System.Windows.Forms.MessageBox]::Show(
        "Add `"$name`" to the built-in Administrators group (SID S-1-5-32-544)?",
        'Create local user',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    Write-SetupLog "Creating local user `"$name`" ..." 'INFO'

    if ([string]::IsNullOrEmpty($password)) {
        net user $name /add 2>&1 | ForEach-Object {
            $line = "$_".Trim()
            if ($line.Length -gt 0) { Write-SetupLog $line 'INFO' }
        }
    } else {
        net user $name $password /add 2>&1 | ForEach-Object {
            $line = "$_".Trim()
            if ($line.Length -gt 0) { Write-SetupLog $line 'INFO' }
        }
    }

    if ($LASTEXITCODE -ne 0) {
        throw "net user /add failed (exit $LASTEXITCODE)."
    }

    Start-Sleep -Milliseconds 400

    if ($adminAns -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            $userObj = Get-LocalUser -Name $name -ErrorAction Stop
            $adminGrp = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction Stop
            Add-LocalGroupMember -Group $adminGrp -Member $userObj -ErrorAction Stop
            Write-SetupLog "Added `"$name`" to Administrators (local group SID S-1-5-32-544)." 'SUCCESS'
        } catch {
            Write-SetupLog "Add-LocalGroupMember failed: $_; trying WinNT ADSI..." 'WARN'
            try {
                $adsGrp = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
                $adsGrp.Add("WinNT://$env:COMPUTERNAME/$name,user")
                Write-SetupLog "Added `"$name`" via ADSI Administrators." 'SUCCESS'
            } catch {
                Write-SetupLog "ADSI add failed: $_" 'ERROR'
                throw
            }
        }
    }
}

function Invoke-ProvisionWindowsTimeResync {
    Write-SetupLog 'Recycling Windows Time service and resyncing.' 'INFO'
    Stop-Service -Name w32time -Force -ErrorAction SilentlyContinue
    Set-Service -Name w32time -StartupType Disabled -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Set-Service -Name w32time -StartupType Manual -ErrorAction Stop
    Start-Service -Name w32time -ErrorAction Stop
    $null = & w32tm.exe /resync /force 2>&1
    Write-SetupLog 'w32tm /resync finished.' 'SUCCESS'
}

function store {
    <#
    .SYNOPSIS
        Minimal CLI sugar: `store updates --apply` runs winget upgrades for the msstore source (Store apps winget knows about).
    #>
    param(
        [Parameter(Position = 0)]
        [string]$Action,
        [Parameter(Position = 1)]
        [string]$ApplyFlag
    )
    if ($Action -eq 'updates' -and $ApplyFlag -eq '--apply') {
        Invoke-ProvisionWingetStoreUpgradeAll
        return
    }
    throw "Usage: store updates --apply   (runs winget upgrade --all --source msstore)"
}
