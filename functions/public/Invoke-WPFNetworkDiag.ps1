function Get-WinUtilNetDiagRoot {
    $base = $sync.PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($base) -and $PSScriptRoot) {
        $base = $PSScriptRoot
    }
    if ([string]::IsNullOrWhiteSpace($base) -and $PSCommandPath) {
        $base = Split-Path -Parent $PSCommandPath
    }
    if ([string]::IsNullOrWhiteSpace($base)) {
        return $null
    }
    return (Join-Path $base 'tools\netdiag')
}

function Start-WinUtilNetDiagConsole {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $root = Get-WinUtilNetDiagRoot
    if (-not $root -or -not (Test-Path -LiteralPath $root)) {
        [System.Windows.MessageBox]::Show(
            "Network tool folder not found:`n$root`n`nExpected tools\netdiag next to winutil.ps1.",
            'Network diagnostics',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pyCmd) {
        [System.Windows.MessageBox]::Show(
            "Python was not found in PATH. Install Python 3 and pip install -r tools\netdiag\requirements.txt (optional scapy for capture).",
            'Network diagnostics',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $pyExe = $pyCmd.Source
    if (-not (Test-Path -LiteralPath $pyExe)) {
        [System.Windows.MessageBox]::Show(
            "Python path is invalid:`n$pyExe`n`nTurn off App Execution Aliases for 'python.exe' in Settings, or use a full install from python.org.",
            'Network diagnostics',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # Quote args for a single PowerShell -Command string (must run with WorkingDirectory = tools\netdiag so -m netdiag resolves)
    $argStr = ($Arguments | ForEach-Object {
            if ($_ -match "[\s']") {
                "'{0}'" -f ($_.Replace("'", "''"))
            } else {
                $_
            }
        }) -join ' '

    $pyQuoted = $pyExe.Replace("'", "''")
    $inner = "& '$pyQuoted' -m netdiag $argStr"

    $psExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
    if (-not $psExe -or -not (Test-Path -LiteralPath $psExe)) {
        $psExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    }

    $psi = @{
        FilePath               = $psExe
        WorkingDirectory       = $root
        ArgumentList           = @('-NoLogo', '-NoExit', '-NoProfile', '-Command', $inner)
        PassThru               = $false
    }

    $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
    if ($wt -and (Test-Path -LiteralPath $wt.Source)) {
        # -d sets starting directory; full path to powershell avoids 0x80070002 when PATH inside WT is minimal
        $psi['FilePath'] = $wt.Source
        $psi['ArgumentList'] = @(
            '-d', $root,
            $psExe,
            '-NoLogo', '-NoExit', '-NoProfile', '-Command', $inner
        )
        # wt starts the child with cwd from -d; keep WorkingDirectory for Start-Process metadata
        $psi['WorkingDirectory'] = $root
    }

    Start-Process @psi
}

function Invoke-WPFNetdiagDiagnose {
    Start-WinUtilNetDiagConsole -Arguments @('diagnose', '--capture')
}

function Invoke-WPFNetdiagDiagnoseQuick {
    Start-WinUtilNetDiagConsole -Arguments @('diagnose')
}

function Invoke-WPFNetdiagCapture {
    Start-WinUtilNetDiagConsole -Arguments @('capture')
}

function Invoke-WPFNetdiagRenew {
    Start-WinUtilNetDiagConsole -Arguments @('renew')
}

function Invoke-WPFNetdiagExport {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $path = Join-Path $docs "netdiag-snapshot-$stamp.json"
    Start-WinUtilNetDiagConsole -Arguments @('export', '-o', $path)
}

function Invoke-WPFNetdiagCompare {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $dlg1 = New-Object System.Windows.Forms.OpenFileDialog
    $dlg1.Filter = 'JSON snapshot (*.json)|*.json|All files (*.*)|*.*'
    $dlg1.Title = 'Compare netdiag: first snapshot JSON'
    if ($dlg1.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $dlg2 = New-Object System.Windows.Forms.OpenFileDialog
    $dlg2.Filter = 'JSON snapshot (*.json)|*.json|All files (*.*)|*.*'
    $dlg2.Title = 'Compare netdiag: second snapshot JSON'
    if ($dlg2.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    Start-WinUtilNetDiagConsole -Arguments @('compare', $dlg1.FileName, $dlg2.FileName)
}

function Invoke-WPFNetdiagListIfaces {
    Start-WinUtilNetDiagConsole -Arguments @('list-ifaces')
}

function Invoke-WPFNetdiagLinkMon {
    Start-WinUtilNetDiagConsole -Arguments @('linkmon', '--on-link-up')
}
