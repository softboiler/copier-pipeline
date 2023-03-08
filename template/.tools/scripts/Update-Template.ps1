<#.SYNOPSIS
Update the project to the latest template version.
#>

& '.tools/scripts/template_common.ps1'
copier -f -r "$(git rev-parse HEAD:template)"
python '.tools/scripts/compose_pyproject.py'
