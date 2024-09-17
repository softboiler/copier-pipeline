<#
.SYNOPSIS
Initialization commands for PowerShell shells in pre-commit and tasks.#>

. scripts/Common.ps1

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

    Param([string]$Version = $(Get-Content '.copier-answers.yml' |
                Find-Pattern '^python_version:\s?["'']([^"'']+)["'']$' |
                Find-Pattern '^([^.]+\.[^.]+).*$')
    )

    # ? Track environment variables to update `.env` with later
    $EnvVars = @{}
    $Sep = $IsWindows ? ';' : ':'
    $EnvPath = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.env'
    # ? Create `env` if missing
    if (!($EnvFile = Get-Item $EnvPath -ErrorAction 'Ignore')) {
        New-Item $EnvPath
        $EnvFile = Get-Item $EnvPath
    }
    # ? Create local `bin` if missing
    if (!($Bin = Get-Item 'bin' -ErrorAction 'Ignore')) {
        New-Item 'bin' -ItemType 'Directory'
        $Bin = Get-Item 'bin'
    }
    # ? Add local `bin` to path
    $Env:PATH = "$Bin$Sep$Env:PATH"
    # ? Set `uv` tool directory to local `bin`
    $Env:UV_TOOL_BIN_DIR = $Bin
    $EnvVars.Add('UV_TOOL_BIN_DIR', $Bin)

    # ? Sync local `uv` version
    Sync-Uv

    # ? Sync contributor virtual environment
    $CI = $Env:SYNC_PY_DISABLE_CI ? $null : $Env:CI
    if (!$CI) {
        if (!(Test-Path '.venv')) { uv venv --python $Version }
        if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
        if (!(python --version | Select-String -Pattern $([Regex]::Escape($Version)))) {
            'Virtual environment is the wrong Python version.' | Write-Progress -Info
            'Creating virtual environment with correct Python version' | Write-Progress
            Remove-Item -Recurse -Force $Env:VIRTUAL_ENV
            uv venv --python $Version
            if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
        }
    }
    if (!(Get-Command 'copier_python_tools' -ErrorAction 'Ignore')) {
        'Installing tools' | Write-Progress
        uv tool install --force --python $Version --resolution 'lowest-direct' --editable 'scripts/.'
        'Tools installed' | Write-Progress -Done
    }

    # ? Get environment variables from `pyproject.toml`
    copier_python_tools init-shell |
        Select-String -Pattern '^(.+)=(.+)$' |
        ForEach-Object {
            $Key, $Value = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
            if ((($Key.ToLower() -ne 'path')) -and ($EnvVars -notcontains $Key)) {
                $EnvVars.Add($Key, $Value)
            }
        }
    # ? Get environment variables to update in `.env`
    $Keys = @()
    $Lines = Get-Content $EnvFile | ForEach-Object {
        $_ -replace '^(?<Key>.+)=(?<Value>.+)$', {
            $Key = $_.Groups['Key'].Value
            if ($Key.ToLower() -eq 'path') { $PathInEnvFile = $true }
            elseif ($EnvVars.ContainsKey($Key)) {
                $Keys += $Key
                return "$Key=$($EnvVars[$Key])"
            }
            return $_
        }
    }
    # ? Sync environment variables and those in `.env`
    $NewLines = $EnvVars.GetEnumerator() | ForEach-Object {
        $Key, $Value = $_.Key, $_.Value
        if ($Key.ToLower() -ne 'path') {
            Set-Item "Env:$Key" $Value
            if ($Keys -notcontains $Key) { return "$Key=$Value" }
        }
    }
    @($Lines, $NewLines) | Set-Content $EnvFile
    if ($CI -and !$PathInEnvFile) { "PATH=$Path" | Add-Content $EnvFile }
}

Set-Env
