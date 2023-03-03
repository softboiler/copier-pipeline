<#.SYNOPSIS
Update the project to the latest template version, ignoring project-specific deviations.
#>

& '.tools/scripts/template_common.ps1'
copier 'gh:blakeNaccarato/copier-python' '.'
