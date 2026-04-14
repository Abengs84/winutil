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
        net user $name /add 2>&1 | ForEach-Object { Write-SetupLog "$_" 'INFO' }
    } else {
        net user $name $password /add 2>&1 | ForEach-Object { Write-SetupLog "$_" 'INFO' }
    }

    if ($LASTEXITCODE -ne 0) {
        throw "net user /add failed (exit $LASTEXITCODE)."
    }

    if ($adminAns -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $name -ErrorAction Stop
            Write-SetupLog "Added `"$name`" to Administrators (SID)." 'SUCCESS'
        } catch {
            Write-SetupLog "Add-LocalGroupMember failed, trying net localgroup: $_" 'WARN'
            net localgroup Administrators $name /add 2>&1 | ForEach-Object { Write-SetupLog "$_" 'INFO' }
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
