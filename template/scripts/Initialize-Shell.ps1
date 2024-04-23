<#
.SYNOPSIS
Initialization commands for PowerShell shells in pre-commit and tasks.#>

# ? Error-handling
$ErrorActionPreference = 'Stop'
($PSNativeCommandUseErrorActionPreference = $true) | Out-Null
($ErrorView = 'NormalView') | Out-Null

# ? Fix leaky UTF-8 encoding settings on Windows
if ($IsWindows) {
    # Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
    # system-wide has buggy downsides.
    # See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
}

# ? Environment variables
$Env:PIP_DISABLE_PIP_VERSION_CHECK = 1
$Env:PYDEVD_DISABLE_FILE_VALIDATION = 1
$Env:PYTHONIOENCODING = 'utf-8:strict'
$Env:PYTHONUTF8 = 1
$Env:PYTHONWARNDEFAULTENCODING = 1
# Ignore warnings until explicitly re-enabled in tests
$Env:PYTHONWARNINGS = 'ignore'

function Set-Env {
    <#.SYNOPSIS
    Load `.env`, activate a virtual environment found here or in parent directories.#>
    # ? Activate virtual environment if one exists
    if (Test-Path '.venv') {
        if ($IsWindows) { .venv/scripts/activate.ps1 }
        else {
            .venv/bin/activate.ps1
            # ? uv-sourced, virtualenv-based `activate.ps1` incorrectly uses  `;` sep
            $Env:PATH = $Env:PATH -Replace ';', ':'
        }
    }
    # ? Prepend local `bin` to PATH
    $sep = $IsWindows ? ';' : ':'
    $Env:PATH = "bin$sep$Env:PATH"
}
Set-Env
