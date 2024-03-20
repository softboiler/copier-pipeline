<#.SYNOPSIS
Initialize repository prior to first commit.#>

. 'scripts/Set-StrictErrors.ps1'

git add -A
git commit --no-verify -m 'Prepare template using blakeNaccarato/copier-python'
git submodule add --force --name template https://github.com/blakeNaccarato/copier-python.git submodules/template
git submodule add --force --name typings https://github.com/blakeNaccarato/pylance-stubs-unofficial.git submodules/typings
git add -A
git commit --no-verify -m 'Add template and type stub submodules'
scripts/Sync-Py.ps1
git add -A
git commit --no-verify -m 'Initialize template using blakeNaccarato/copier-python'
