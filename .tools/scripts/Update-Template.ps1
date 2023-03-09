<#.SYNOPSIS
Update the project to the latest template version.
#>

Param(
    # Whether to update to the latest remote template version
    [switch]$Remote,

    # Whether to force templating using old answers.
    [switch]$Force
)

$(if ($Remote) { & '.tools/scripts/template_common.ps1' })
copier $(if ($Force) { '--force' }) --vcs-ref "$(git rev-parse HEAD:template)"
python '.tools/scripts/compose_pyproject.py'
