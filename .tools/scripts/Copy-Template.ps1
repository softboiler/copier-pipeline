<#.SYNOPSIS
Update the project to the latest template version, ignoring project-specific deviations.
#>

copier 'gh:blakeNaccarato/copier-python' '.'
python '.tools/scripts/compose_pyproject.py'
