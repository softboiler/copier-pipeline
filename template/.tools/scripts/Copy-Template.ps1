<#.SYNOPSIS
Update the project from the project template.
#>

Param(
    # Whether to update to the latest remote template version
    [switch]$Update,

    # Whether to recopy the template, ignoring prior diffs, or update in a smart manner.
    [switch]$Recopy,

    # Whether to use default values for unanswered questions.
    [switch]$Defaults
)

$(if ($Update) { & '.tools/scripts/template_common.ps1' })
copier $(if ($Recopy) { 'recopy' } else { 'update' }) $(if ($Defaults) { '--defaults' }) --vcs-ref "$(git rev-parse HEAD:template)"
python '.tools/scripts/compose_pyproject.py'
