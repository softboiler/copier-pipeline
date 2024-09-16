<#.SYNOPSIS
Initialize repository.#>

. scripts/Common.ps1
. scripts/Initialize-Shell.ps1

git init

# ? Modify GitHub repo later on only if there were not already commits in this repo
try { git rev-parse HEAD }
catch [System.Management.Automation.NativeCommandExitException] { $Fresh = $true }

git add .
try { git commit --no-verify -m 'Prepare template using blakeNaccarato/copier-python' }
catch [System.Management.Automation.NativeCommandExitException] { $AlreadyTemplated = $true }

git submodule add --force --name 'template' 'https://github.com/blakeNaccarato/copier-python.git' 'submodules/template'
git submodule add --force --name 'stubs' 'https://github.com/microsoft/python-type-stubs.git' 'submodules/stubs'
git add .
try { git commit --no-verify -m 'Add template and type stub submodules' }
catch [System.Management.Automation.NativeCommandExitException] { $HadSubmodules = $true }

scripts/Sync-Py.ps1
Set-Env
git add .
try { git commit --no-verify -m 'Lock' }
catch [System.Management.Automation.NativeCommandExitException] { $AlreadyLocked = $true }

# ? Modify GitHub repo if there were not already commits in this repo
if ($fresh) {
    if (!(git remote)) {
        git remote add origin 'https://github.com/blakeNaccarato/copier-python.git'
        git branch --move --force main
    }
    gh repo edit --description (Get-Content '.copier-answers.yml' | Find-Pattern '^project_description:\s(.+)$')
    gh repo edit --homepage 'https://blakeNaccarato.github.io/copier-python/'
}

git push --set-upstream origin main
