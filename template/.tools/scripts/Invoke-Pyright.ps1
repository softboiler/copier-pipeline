<#.SYNOPSIS
Ensure type stubs are synchronized and run pyright.
#>

git submodule update --init --merge typings
Get-Content .tools/requirements/requirements_both.txt |
    Select-String pyright |
    ForEach-Object { pip install $_ }
pyright
$PyrightExitCode = $LastExitCode
nbqa pyright src tests
$NbqaPyrightExitCode = $LastExitCode
if (($PyrightExitCode -ne 0) -or ($NbqaPyrightExitCode -ne 0)) {
    Exit $PyrightExitCode -or $NbqaPyrightExitCode
}
