# Shared log sink for custom provisioning scripts (dot-source from setup or profiles).

if (-not $script:CustomSetupLogPath) {
    $script:CustomSetupLogPath = Join-Path $env:TEMP ("sysadmin-setup-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
}

function Write-SetupLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    try {
        Add-Content -LiteralPath $script:CustomSetupLogPath -Value $line -Encoding utf8 -ErrorAction Stop
    } catch {
        Write-Host "[$ts] [WARN] Could not append to log file: $($script:CustomSetupLogPath) - $_"
    }
}
