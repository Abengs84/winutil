function Invoke-WPFRunspace {

    <#

    .SYNOPSIS
        Creates and invokes a runspace using the given scriptblock and argumentlist

    .PARAMETER ScriptBlock
        The scriptblock to invoke in the runspace

    .PARAMETER ArgumentList
        A list of arguments to pass to the runspace

    .PARAMETER ParameterList
        A list of named parameters that should be provided.
    .EXAMPLE
        Invoke-WPFRunspace `
            -ScriptBlock $sync.ScriptsInstallPrograms `
            -ArgumentList "Installadvancedip,Installbitwarden" `

        Invoke-WPFRunspace`
            -ScriptBlock $sync.ScriptsInstallPrograms `
            -ParameterList @(("PackagesToInstall", @("Installadvancedip,Installbitwarden")),("ChocoPreference", $true))
    #>

    [CmdletBinding()]
    Param (
        $ScriptBlock,
        $ArgumentList,
        $ParameterList
    )

    # Create a PowerShell instance (local to this invocation).
    $powershell = [powershell]::Create()

    # Add Scriptblock and Arguments to runspace
    $powershell.AddScript($ScriptBlock) | Out-Null
    $powershell.AddArgument($ArgumentList) | Out-Null

    foreach ($parameter in $ParameterList) {
        $powershell.AddParameter($parameter[0], $parameter[1]) | Out-Null
    }

    $powershell.RunspacePool = $sync.runspace

    # Execute the RunspacePool
    $handle = $powershell.BeginInvoke()

    # Ensure EndInvoke is always called so errors/output are flushed and resources are released.
    if ($handle.IsCompleted) {
        try {
            $powershell.EndInvoke($handle) | Out-Null
        } catch {
            Write-Host "Runspace error: $_"
        } finally {
            $powershell.Dispose()
        }
    } else {
        [System.Threading.ThreadPool]::RegisterWaitForSingleObject(
            $handle.AsyncWaitHandle,
            [System.Threading.WaitOrTimerCallback]{
                param($state, $timedOut)
                try {
                    $state.PowerShell.EndInvoke($state.Handle) | Out-Null
                } catch {
                    # EndInvoke can throw when task failed; suppress here because caller handles task-level UX.
                } finally {
                    $state.PowerShell.Dispose()
                }
            },
            @{ PowerShell = $powershell; Handle = $handle },
            -1,
            $true
        ) | Out-Null
    }
    # Return the handle
    return $handle
}
