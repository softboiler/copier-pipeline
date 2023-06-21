<#.SYNOPSIS
Update the project from the project template.
#>

Param(
    # Whether to recopy the template, ignoring prior diffs, or update in a smart manner.
    [switch]$Recopy,

    # Whether to use default values for unanswered questions.
    [switch]$Defaults
)

if ( $Recopy ) {
    copier recopy --force $(if ($Defaults) { '--defaults' })
}
else {
    git submodule update --init --remote --merge template
    git add --all
    git commit -m "Update template digest to $(git rev-parse --short HEAD:template)"
    git submodule deinit template
    copier update $(if ($Defaults) { '--defaults' })
}
python '.tools/scripts/compose_pyproject.py'
