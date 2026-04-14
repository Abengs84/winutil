function Update-WPFAbittiVersionDisplay {
    <#
    .SYNOPSIS
        Refreshes the Abitti2 tab label from uninstall registry (UI thread).
    #>
    if ($PARAM_NOUI) {
        return
    }
    if (-not $sync.WPFAbittiVersionDisplay) {
        return
    }
    Invoke-WPFUIThread -ScriptBlock {
        try {
            $sync.WPFAbittiVersionDisplay.Text = Get-AbittiVersionDisplayString
        } catch {
            $sync.WPFAbittiVersionDisplay.Text = 'Could not read version'
        }
    }
}
