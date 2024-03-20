<#.SYNOPSIS
This should be the default since PowerShell 7.4, but somehow it's not.#>
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$PSNativeCommandUseErrorActionPreference | Out-Null
