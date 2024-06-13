<#.SYNOPSIS
Sync Python dependencies.#>
Param(
    # Python version.
    [string]$Version,
    # Sync to highest dependencies.
    [switch]$High
)

. scripts/Common.ps1
. scripts/Initialize-Shell.ps1

'****** SYNCING' | Write-Progress

'CHECKING ENVIRONMENT TYPE' | Write-Progress
$High = $High ? $High : [bool]$Env:SYNC_PY_HIGH
$CI = $Env:SYNC_PY_DISABLE_CI ? $null : $Env:CI
$Devcontainer = $Env:SYNC_PY_DISABLE_DEVCONTAINER ? $null : $Env:DEVCONTAINER
$Env:UV_SYSTEM_PYTHON = $CI ? 'true' : $null
if ($CI) { $msg = 'CI' }
elseif ($Devcontainer) { $msg = 'devcontainer' }
else { $msg = 'contributor environment' }
"Will run $msg steps" | Write-Progress -Info

'FINDING UV' | Write-Progress
$uvVersionRe = Get-Content 'requirements/uv.in' | Select-String -Pattern '^uv==(.+)$'
$uvVersion = $uvVersionRe.Matches.Groups[1].value
if (!(Test-Path 'bin/uv*') -or !(bin/uv --version | Select-String $uvVersion)) {
    $Env:CARGO_HOME = '.'
    if ($IsWindows) {
        'INSTALLING UV FOR WINDOWS' | Write-Progress
        $uvInstaller = "$([System.IO.Path]::GetTempPath())$([System.Guid]::NewGuid()).ps1"
        Invoke-RestMethod "https://github.com/astral-sh/uv/releases/download/$uvVersion/uv-installer.ps1" |
            Out-File $uvInstaller
        powershell -Command "& '$uvInstaller' -NoModifyPath"
    }
    else {
        'INSTALLING UV' | Write-Progress
        $Env:INSTALLER_NO_MODIFY_PATH = $true
        curl --proto '=https' --tlsv1.2 -LsSf "https://github.com/astral-sh/uv/releases/download/$uvVersion/uv-installer.sh" |
            sh
    }
    'UV INSTALLED' | Write-Progress -Done
}

'INSTALLING TOOLS' | Write-Progress
$pyDevVersionRe = Get-Content '.copier-answers.yml' |
    Select-String -Pattern '^python_version:\s?["'']([^"'']+)["'']$'
$Version = $Version ? $Version : $pyDevVersionRe.Matches.Groups[1].value
if ($CI) {
    $py = Get-PySystem $Version
    "Using $(Resolve-Path $py)" | Write-Progress -Info
}
else {
    $py = Get-Py $Version
    "Using $(Resolve-Path $py -Relative)" | Write-Progress -Info
}
bin/uv pip install --editable=scripts
'TOOLS INSTALLED' | Write-Progress -Done

'*** RUNNING PRE-SYNC TASKS' | Write-Progress
if ($CI) {
    'SYNCING PROJECT WITH TEMPLATE' | Write-Progress
    try {scripts/Sync-Template.ps1 -Stay} catch [System.Management.Automation.NativeCommandExitException] {
        git stash save --include-untracked
        scripts/Sync-Template.ps1 -Stay
        git stash pop
        git add .
    }
    'PROJECT SYNCED WITH TEMPLATE' | Write-Progress
}
if ($Devcontainer) {
    $repo = Get-ChildItem '/workspaces'
    $submodules = Get-ChildItem "$repo/submodules"
    $safeDirs = @($repo) + $submodules
    foreach ($dir in $safeDirs) {
        if (!($safeDirs -contains $dir)) { git config --global --add safe.directory $dir }
    }
}
if (!$CI) {
    'SYNCING SUBMODULES' | Write-Progress
    git submodule update --init --merge
    'SUBMODULES SYNCED' | Write-Progress -Done
    '' | Write-Host
}
'*** PRE-SYNC DONE ***' | Write-Progress -Done

'SYNCING DEPENDENCIES' | Write-Progress
copier_python_tools compile $($High ? '--high' : '--no-high') | bin/uv pip sync -
'DEPENDENCIES SYNCED' | Write-Progress -Done

'*** RUNNING POST-SYNC TASKS' | Write-Progress
if (!$CI) {
    'INSTALLING PRE-COMMIT HOOKS' | Write-Progress
    pre-commit install
    'PRE-COMMIT HOOKS INSTALLED' | Write-Progress -Done
    '' | Write-Host
}
'*** POST-SYNC DONE ***' | Write-Progress -Done
'' | Write-Host

'****** DONE ******' | Write-Progress -Done

# ? Stop PSScriptAnalyzer from complaining about these "unused" variables
$PSNativeCommandUseErrorActionPreference, $NoModifyPath | Out-Null
