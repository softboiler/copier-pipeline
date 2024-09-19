<#.SYNOPSIS
Initialize shell.#>

# ? Error-handling
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$ErrorView = 'NormalView'

# ? Fix leaky UTF-8 encoding settings on Windows
if ($IsWindows) {
    # ? Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
    # ? system-wide has buggy downsides.
    # ? See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
}
if (Test-Path '.venv') {
    if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
}
if (!$Env:CI) { $Env:PATH = "$HOME/.cargo/bin;$Env:PATH" }
