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
    # In GUI mode, logs from pool runspaces should be marshalled to UI thread
    # so they appear in the same host/transcript stream as normal Write-Host output.
    $scriptTi = $null
    if ($sync -and $null -ne $sync.WinUtilScriptThreadId) {
        $scriptTi = [int]$sync.WinUtilScriptThreadId
    }
    $cur = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    $isWorkerThread = ($null -ne $scriptTi -and $cur -ne $scriptTi)
    $canUIHostWrite = ($sync -and $sync.Form -and (Get-Command Invoke-WPFUIThread -ErrorAction SilentlyContinue))
    if ($isWorkerThread -and $canUIHostWrite) {
        try {
            $msg = $line
            Invoke-WPFUIThread -ScriptBlock { Write-Host $msg }
        } catch {
            Write-Host $line
        }
    } else {
        Write-Host $line
    }
    try {
        Add-Content -LiteralPath $logPath -Value $line -Encoding utf8 -ErrorAction Stop
    } catch {
        $warn = "[$ts] [WARN] Could not append to log file: $logPath - $_"
        if ($isWorkerThread -and $canUIHostWrite) {
            try {
                $warnMsg = $warn
                Invoke-WPFUIThread -ScriptBlock { Write-Host $warnMsg }
            } catch {
                Write-Host $warn
            }
        } else {
            Write-Host $warn
        }
    }
}
