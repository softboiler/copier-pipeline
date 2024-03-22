<#.SYNOPSIS
Cross-platform support for getting system and virtual environment Python interpreters.#>

$VenvPath = '.venv'

function Get-Py {
    <#.SYNOPSIS
    Get virtual environment Python interpreter, creating it if necessary.#>
    Param([Parameter(Mandatory, ValueFromPipeline)][string]$Version)
    process {
        $SysPy = $Version | Get-PySystem
        if (!(Test-Path $VenvPath)) { & $SysPy -m venv $VenvPath }
        $VenvPy = Start-PyVenv
        $foundVersion = & $VenvPy --version
        if ($foundVersion |
                Select-String -Pattern "^Python $([Regex]::Escape($Version))\.\d+$") {
            return $VenvPy
        }
        Remove-Item -Recurse -Force $Env:VIRTUAL_ENV
        return Get-Py $Version
    }
}

function Get-PySystem {
    <#.SYNOPSIS
    Get system Python interpreter.#>
    Param([Parameter(Mandatory, ValueFromPipeline)][string]$Version)
    begin {
        function Test-Command {
            <#.SYNOPSIS
            Like `Get-Command` but errors are ignored.#>
            return Get-Command @args -ErrorAction 'Ignore'
        }
    }
    process {
        $command = 'from sys import executable; print(executable)'
        if ((Test-Command 'py') -and (py '--list' | Select-String -Pattern "^\s?-V:$([Regex]::Escape($Version))")) {
            return & py -$Version -c $command
        }
        elseif (Test-Command ($py = "python$Version")) { }
        elseif (Test-Command ($py = 'python')) { }
        else { throw "Expected Python $Version, which does not appear to be installed. Ensure it is installed (e.g. from https://www.python.org/downloads/) and run this script again." }
        return & $py -c $command
    }
}

function Start-PyVenv {
    <#.SYNOPSIS
    Activate and get the Python interpreter for the virtual environment.#>
    if ($IsWindows) { $bin = 'Scripts'; $py = 'python.exe' }
    else { $bin = 'bin'; $py = 'python' }
    & "$VenvPath/$bin/Activate.ps1"
    return "$Env:VIRTUAL_ENV/$bin/$py"
}
