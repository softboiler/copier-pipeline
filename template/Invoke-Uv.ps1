<#.SYNOPSIS
Invoke `uv`.#>
[CmdletBinding(PositionalBinding = $False)]
Param(
    [switch]$Sync,
    [switch]$Update,
    [switch]$Low,
    [switch]$High,
    [switch]$Build,
    [switch]$Force,
    [switch]$CI,
    [switch]$Devcontainer,
    [string]$PythonVersion = (Get-Content '.python-version'),
    [string]$PylanceVersion = (Get-Content '.pylance-version'),
    [Parameter(ValueFromRemainingArguments = $True)][string[]]$Run
)

. ./dev.ps1

$InvokeUvArgs = @{
    Sync           = $Sync
    Update         = $Update
    Low            = $Low
    High           = $High
    Build          = $Build
    Force          = $Force
    CI             = (New-Switch $Env:SYNC_ENV_DISABLE_CI (New-Switch $Env:CI))
    Devcontainer   = (New-Switch $Env:SYNC_ENV_DISABLE_DEVCONTAINER (New-Switch $Env:DEVCONTAINER))
    PythonVersion  = $PythonVersion
    PylanceVersion = $PylanceVersion
    Run            = $Run
}
Invoke-Uv @InvokeUvArgs
