<#.SYNOPSIS
Common utilities.#>

function Write-Progress {
    <#.SYNOPSIS
    Write progress and completion messages.#>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)][string]$Message,
        [switch]$Done,
        [switch]$Info
    )
    begin {
        $InProgress = !$Done -and !$Info
        if ($Info) { $Color = 'Magenta' }
        elseif ($Done) { $Color = 'Green' }
        else { $Color = 'Yellow' }
    }
    process {
        if ($InProgress) { Write-Host }
        "$Message$($InProgress ? '...' : '')" | Write-Host -ForegroundColor $Color
    }
}

function Find-Pattern {
    <#.SYNOPSIS
    Find the first match to a pattern in a string.#>
    Param(
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory, ValueFromPipeline)][string]$String
    )
    process {
        if ($Groups = ($String | Select-String -Pattern $Pattern).Matches.Groups) {
            return $Groups[1].value
        }
    }
}

function Sync-Uv {
    <#.SYNOPSIS
    Sync local `uv` version.#>
    Param(
        [string]$Version = (Get-Content 'requirements/uv.txt' | Find-Pattern '^uv==(.+)$')
    )
    if (Get-Command 'uv' -ErrorAction 'Ignore') { $Uv = 'uv' }
    else {
        $Uv = Get-Item 'bin/uv.*' -ErrorAction 'Ignore'
    }
    # ? Prepend local `bin` to PATH
    if (!($Bin = Get-Item 'bin' -ErrorAction 'Ignore')) {
        New-Item 'bin' -ItemType 'Directory'
        $Bin = Get-Item 'bin'
    }
    $Sep = $IsWindows ? ';' : ':'
    $Env:PATH = "$(Get-Item 'bin')$Sep$Env:PATH"
    $CI = $Env:SYNC_PY_DISABLE_CI ? $null : $Env:CI
    $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.env'
    if ($CI) { ("PATH=$Env:PATH", "UV_TOOL_BIN_DIR=$Bin") | Add-Content $EnvFile }
    # ? Install `uv`
    if ((!$Uv -or !(& $Uv --version | Select-String $Version))) {
        'Installing uv' | Write-Progress
        $OrigCargoHome = $Env:CARGO_HOME
        $Env:CARGO_HOME = '.'
        $Env:INSTALLER_NO_MODIFY_PATH = $true
        if ($IsWindows) { Invoke-RestMethod "https://github.com/astral-sh/uv/releases/download/$Version/uv-installer.ps1" | Invoke-Expression }
        else { curl --proto '=https' --tlsv1.2 -LsSf "https://github.com/astral-sh/uv/releases/download/$Version/uv-installer.sh" | sh }
        if ($OrigCargoHome) { $Env:CARGO_HOME = $OrigCargoHome }
        'uv installed' | Write-Progress -Done
        return Get-Item 'bin/uv.*'
    }
}
