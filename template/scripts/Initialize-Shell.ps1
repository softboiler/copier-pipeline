<#
.SYNOPSIS
Initialization commands for PowerShell shells in pre-commit and tasks.#>

# ? Error-handling
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$ErrorView = 'NormalView'

# ? Fix leaky UTF-8 encoding settings on Windows
if ($IsWindows) {
    # Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
    # system-wide has buggy downsides.
    # See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
}

# ? Environment setup
function Set-Env {
    <#.SYNOPSIS
    Activate virtual environment and set environment variables.#>
    # ? Activate virtual environment if one exists
    if (Test-Path '.venv') {
        if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
    }
    # ? Set environment variables
    if (Get-Command -Name '{{ project_name }}_tools' -ErrorAction 'Ignore') {
        $EnvVars = @{}
        {{ project_name }}_tools init-shell |
            Select-String -Pattern '^(.+)=(.+)$' |
            ForEach-Object {
                $EnvVars.Add($_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value)
            }
        $Keys = @()
        $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.env'
        if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
        $Lines = Get-Content $EnvFile | ForEach-Object {
            $_ -replace '^(?<Key>.+)=(?<Value>.+)$', {
                $Key = $_.Groups['Key'].Value
                if ($EnvVars.ContainsKey($Key)) {
                    $Keys += $Key
                    return "$Key=$($EnvVars[$Key])"
                }
                return $_
            }
        }
        $NewLines = $EnvVars.GetEnumerator() | ForEach-Object {
            $Key, $Value = $_.Key, $_.Value
            Set-Item "Env:$Key" $Value
            if (($Key.ToLower() -ne 'path') -and ($Keys -notcontains $Key)) {
                return "$Key=$Value"
            }
        }
        @($Lines, $NewLines) | Set-Content $EnvFile
    }
}
Set-Env
