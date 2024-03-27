<#.SYNOPSIS
Sync Python dependencies.#>
Param(
    # Python version.
    [string]$Version,
    # Sync to highest dependencies.
    [switch]$High,
    # Add all local dependency compilations to the lock.
    [switch]$Lock,
    # Don't run pre-sync actions.
    [switch]$NoPreSync,
    # Don't run post-sync actions.
    [switch]$NoPostSync
)

. scripts/Common.ps1
. scripts/Initialize-Shell.ps1

'*** SYNCING' | Write-Progress

# ? Allow toggling CI in order to test local dev workflows
$CI = $Env:SYNC_PY_DISABLE_CI ? $null : $Env:CI
$Env:UV_SYSTEM_PYTHON = $CI ? 'true' : $null

# ? Don't pre-sync or post-sync in CI
$NoPreSync = $NoPreSync ? $NoPreSync : [bool]$CI
$NoPostSync = $NoPostSync ? $NoPostSync : [bool]$CI
(
    $($CI ? 'Will run CI steps' : 'Will run local steps'),
    $($NoPreSync ? "Won't run pre-sync tasks" : 'Will run pre-sync tasks'),
    $($NoPostSync ? "Won't run post-sync tasks" : 'Will run post-sync tasks')
) | Write-Progress -Info

# ? Install uv
$uvVersionRe = Get-Content 'requirements/uv.in' | Select-String -Pattern '^uv==(.+)$'
$uvVersion = $uvVersionRe.Matches.Groups[1].value
if (!(Test-Path 'bin/uv*') -or !(uv --version | Select-String $uvVersion)) {
    $Env:CARGO_HOME = '.'
    if ($IsWindows) {
        'INSTALLING UV FOR WINDOWS' | Write-Progress
        $uvInstaller = "$([System.IO.Path]::GetTempPath())$([System.Guid]::NewGuid()).ps1"
        Invoke-RestMethod "https://github.com/astral-sh/uv/releases/download/$uvVersion/uv-installer.ps1" |
            Out-File $uvInstaller
        powershell -Command "$uvInstaller -NoModifyPath"
    }
    else {
        'INSTALLING UV' | Write-Progress
        $Env:INSTALLER_NO_MODIFY_PATH = $true
        curl --proto '=https' --tlsv1.2 -LsSf "https://github.com/astral-sh/uv/releases/download/$uvVersion/uv-installer.sh" |
            sh
    }
    'UV INSTALLED' | Write-Progress -Done
}

# ? Synchronize local environment and return if not in CI
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
# ? Install the `copier_python_tools` Python module
uv pip install --editable=scripts
'TOOLS INSTALLED' | Write-Progress -Done

# ? Pre-sync
if (!$NoPreSync) {
    '*** RUNNING PRE-SYNC TASKS' | Write-Progress
    'SYNCING SUBMODULES' | Write-Progress
    git submodule update --init --merge
    'SUBMODULES SYNCED' | Write-Progress -Done
    '' | Write-Host
    '*** PRE-SYNC DONE ***' | Write-Progress -Done
}

# ? Compile
'COMPILING' | Write-Progress
$Comps = & $py -m copier_python_tools compile
$Comp = $High ? $Comps[1] : $Comps[0]
'COMPILED' | Write-Progress -Done

# ? Sync
'SYNCING DEPENDENCIES' | Write-Progress
uv pip sync $Comp
'DEPENDENCIES SYNCED' | Write-Progress -Done

# ? Post-sync
if (!$NoPostSync) {
    '*** RUNNING POST-SYNC TASKS' | Write-Progress
    'SYNCING LOCAL DEV CONFIGS' | Write-Progress
    & $py -m copier_python_tools 'sync-local-dev-configs'
    'LOCAL DEV CONFIGS SYNCED' | Write-Progress -Done
    'INSTALLING PRE-COMMIT HOOKS' | Write-Progress
    pre-commit install
    '*** POST-SYNC DONE ***' | Write-Progress -Done
}
# ? Sync project with template in CI
if ($CI) {
    'SYNCING PROJECT WITH TEMPLATE' | Write-Progress
    scripts/Sync-Template.ps1 -Stay
    'PROJECT SYNCED WITH TEMPLATE' | Write-Progress
}

# ? Lock
if ($Lock) {
    'LOCKING' | Write-Progress
    & $py -m copier_python_tools lock
    'LOCKED' | Write-Progress -Done
}

'' | Write-Host
'*** DONE ***' | Write-Progress -Done

# ? Stop PSScriptAnalyzer from complaining about these "unused" variables
$PSNativeCommandUseErrorActionPreference, $NoModifyPath | Out-Null
