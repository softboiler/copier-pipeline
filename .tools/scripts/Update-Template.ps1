<#.SYNOPSIS
Update the project to the latest template version.
#>

Param(
    # Whether to force templating using old answers.
    [switch]$Force
)

copier $(if ($Force) { '--force' })
python '.tools/scripts/compose_pyproject.py'
