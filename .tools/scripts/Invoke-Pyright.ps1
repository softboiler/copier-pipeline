<#.SYNOPSIS
Ensure type stubs are synchronized and run pyright.
#>

git submodule update --init --merge submodules/typings
Get-Content .tools/requirements/requirements_both.txt |
    Select-String pyright |
    ForEach-Object { pip install $_ }
pyright
git submodule deinit submodules/typings
