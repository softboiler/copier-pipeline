<#.SYNOPSIS
Common utilities.#>

. scripts/Initialize-Shell.ps1

function Get-Py {
    <#.SYNOPSIS
    Get virtual environment Python interpreter, creating it if necessary.#>
    Param([Parameter(Mandatory)][string]$Version)
    if (Test-Path '.venv') {
        $VenvPy = Start-PyVenv
        if (Select-PyVersion $VenvPy $Version) { return $VenvPy }
        'Virtual environment is the wrong Python version' | Write-Progress -Info
        Remove-Item -Recurse -Force $Env:VIRTUAL_ENV
    }
    uv venv --python $(Get-PySystem $Version)
    return Start-PyVenv
}

function Get-PySystem {
    <#.SYNOPSIS
    Get system Python interpreter.#>
    Param([Parameter(Mandatory)][string]$Version)

    $getExe = 'from sys import executable; print(executable)'

    # ? Try to get a known-correct Python at the project `bin`
    if (Test-Path ($py = "bin/python$Version/Scripts/python.exe")) { return $py }
    elseif (($py = "python$Version") | Get-Command -ErrorAction 'Ignore') { return & $py -c $getExe }

    # ? Get the global interpreter, return it if it's the correct Python version
    if (Get-Command -Name 'py' -ErrorAction 'Ignore') { $py = 'py' }
    elseif (Get-Command -Name 'python3' -ErrorAction 'Ignore') { $py = 'python3' }
    elseif (Get-Command -Name 'python' -ErrorAction 'Ignore') { $py = 'python' }
    else { throw 'Python doesn''t appear to be installed. Install from https://www.python.org.' }

    # ? Look for suitable global Python interpreter, return if correct Python version
    'Looking for suitable global Python interpreter' | Write-Progress -Info
    if ($py -eq 'py') { $SysPy = & $py -$Version -c $getExe }
    else { $SysPy = & $py -c $getExe }
    if (Select-PyVersion $py $Version) { return $SysPy }

    # ? Install the correct Python from any system Python
    'Could not find correct version of Python' | Write-Progress -Info
    'DOWNLOADING AND INSTALLING CORRECT PYTHON VERSION TO PROJECT BIN' | Write-Progress
    $SysPyVenvPath = 'bin/sys_venv'
    if (!(Test-Path $SysPyVenvPath)) { uv venv $SysPyVenvPath }
    $SysPyVenv = Start-PyVenv $SysPyVenvPath
    uv pip install $(Get-Content 'requirements/install.in')
    return & $SysPyVenv scripts/install.py $Version
}

function Start-PyVenv {
    <#.SYNOPSIS
    Get an activated virtual environment Python interpreter.#>
    Param([Parameter(ValueFromPipeline)][string]$Path = '.venv')
    process {
        if (Test-Path ($scripts = "$Path/Scripts")) {
            & "$scripts/activate.ps1"
            $Py = "$scripts/python.exe"
        }
        else {
            $bin = "$Path/bin"
            & "$bin/activate.ps1"
            # ? uv-sourced, virtualenv-based `activate.ps1` incorrectly uses  `;` sep
            $Env:PATH = $Env:PATH -Replace ';', ':'
            $Py = "$bin/python"
        }
        # ? Prepend local `bin` to PATH
        $sep = $IsWindows ? ';' : ':'
        $Env:PATH = "bin$sep$Env:PATH"
        return $Py
    }
}

function Select-PyVersion {
    <#.SYNOPSIS
    Select Python version.#>
    Param([Parameter(Mandatory)][string]$Py, [Parameter(Mandatory)][string]$Version)
    $versions = ($py -eq 'py') ? (& $py --list) : (& $Py --version)
    return $versions | Select-String -Pattern $([Regex]::Escape($Version))
}

function Test-CommandLock {
    <#.SYNOPSIS
    Test whether the file handle to a command is locked.#>
    Param ([parameter(Mandatory, ValueFromPipeline)][string]$Name)
    process {
        if (!($Name | Get-Command -ErrorAction 'Ignore')) { return $false }
        return Get-Command $Name | Test-FileLock
    }
}

function Test-FileLock {
    <#.SYNOPSIS
    Test whether a file handle is locked.#>
    Param ([parameter(Mandatory, ValueFromPipeline)][string]$Path)
    process {
        if ( !($Path | Test-Path) ) { return $false }
        try {
            $handle = (
                New-Object 'System.IO.FileInfo' $Path).Open([System.IO.FileMode]::Open,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None
            )
            if ($handle) { $handle.Close() }
            return $false
        }
        catch [System.IO.IOException], [System.UnauthorizedAccessException] { return $true }
    }
}

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
