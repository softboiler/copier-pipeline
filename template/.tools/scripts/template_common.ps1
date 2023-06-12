<#.SYNOPSIS
Common logic for template bumping.
#>

git submodule update --init --remote --merge template
git add --all
git commit -m "Update template digest to $(git rev-parse --short HEAD:template)"
