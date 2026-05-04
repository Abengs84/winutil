# Shared log sink for custom provisioning scripts (dot-source from setup or profiles).
# In compiled WinUtil, $sync.CustomSetupLogPath is set in start.ps1 so runspaces can log.

if (-not $script:CustomSetupLogPath -and ($sync -and $sync.CustomSetupLogPath)) {
    $script:CustomSetupLogPath = $sync.CustomSetupLogPath
}
if (-not $script:CustomSetupLogPath) {
    $script:CustomSetupLogPath = Join-Path $env:TEMP ("sysadmin-setup-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
    if ($sync) { $sync.CustomSetupLogPath = $script:CustomSetupLogPath }
}

function Write-SetupLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $logPath = $null
    if ($sync -and $sync.CustomSetupLogPath) {
        $logPath = [string]$sync.CustomSetupLogPath
    } elseif ($script:CustomSetupLogPath) {
        $logPath = [string]$script:CustomSetupLogPath
    }
    if ([string]::IsNullOrWhiteSpace($logPath)) {
        $logPath = Join-Path $env:TEMP ("sysadmin-setup-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
        if ($sync) { $sync.CustomSetupLogPath = $logPath }
        $script:CustomSetupLogPath = $logPath
    }

    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    # WinUtil GUI uses BeginInvoke without EndInvoke; Write-Host from pool runspaces stays buffered.
    # Same process stdio: use Console on worker threads so lines appear immediately in the terminal.
    $scriptTi = $null
    if ($sync -and $null -ne $sync.WinUtilScriptThreadId) {
        $scriptTi = [int]$sync.WinUtilScriptThreadId
    }
    $cur = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    if ($null -ne $scriptTi -and $cur -ne $scriptTi) {
        try { [Console]::WriteLine($line) } catch { Write-Host $line }
    } else {
        Write-Host $line
    }
    try {
        Add-Content -LiteralPath $logPath -Value $line -Encoding utf8 -ErrorAction Stop
    } catch {
        $warn = "[$ts] [WARN] Could not append to log file: $logPath - $_"
        if ($null -ne $scriptTi -and $cur -ne $scriptTi) {
            try { [Console]::WriteLine($warn) } catch { Write-Host $warn }
        } else {
            Write-Host $warn
        }
    }
}
