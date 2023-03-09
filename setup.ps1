<#.SYNOPSIS
Set up the project, creating a virtual environment and then running update tasks.
#>

# * -------------------------------------------------------------------------------- * #
# * Changes below may be lost in significant template updates.

if ($Env:VIRTUAL_ENV) { 'deactivate' }
if (Test-Path '.venv') { Remove-Item -Recurse -Force '.venv' }
$GLOBAL_PYTHON = 'py -3.11'
try { Invoke-Expression $("$GLOBAL_PYTHON --version") }
catch [System.Management.Automation.CommandNotFoundException] {
    $GLOBAL_PYTHON = 'python3.11'
}
Invoke-Expression "$GLOBAL_PYTHON -m venv '.venv' --upgrade-deps"
. './update.ps1'

# * -------------------------------------------------------------------------------- * #
# * Changes below should persist in significant template updates.
