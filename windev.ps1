<#
.SYNOPSIS
    Dev / latest-tag launcher for this fork (Abengs84/winutil).
.DESCRIPTION
    This Script provides a simple way to start the bleeding edge release of winutil.
.EXAMPLE
    irm https://github.com/Abengs84/winutil/releases/latest/download/winutil.ps1 | iex
    OR
    Run in Admin Powershell >  ./windev.ps1
#>

$latestTag = (Invoke-RestMethod "https://api.github.com/repos/Abengs84/winutil/tags")[0].name
Invoke-RestMethod "https://github.com/Abengs84/winutil/releases/download/$latestTag/winutil.ps1" | Invoke-Expression
