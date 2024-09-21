<#.SYNOPSIS
Common utilities.#>

# ? Error-handling
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'

# ? Fix leaky UTF-8 encoding settings on Windows
if ($IsWindows) {
    # ? Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
    # ? system-wide has buggy downsides.
    # ? See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
}

function Initialize-Shell {
    <#.SYNOPSIS
    Initialize shell.#>
    if (!(Test-Path '.venv')) { Invoke-Uv -Sync -Update -Force }
    if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
}

function Find-Pattern {
    <#.SYNOPSIS
    Find the first match to a pattern in a string.#>
    Param(
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory, ValueFromPipeline)][string]$String
    )
    process {
        if ($Groups = ($String | Select-String -Pattern $Pattern).Matches.Groups) {
            return $Groups[1].value
        }
    }
}

function Install-Uv {
    <#.SYNOPSIS
    Invoke `uv`.#>
    Param([switch]$Update)
    $Env:PATH = "$HOME/.cargo/bin$([System.IO.Path]::PathSeparator)$Env:PATH"
    if (Get-Command 'uv' -ErrorAction 'Ignore') {
        if ($Update) { uv self update }
        return
    }
    if ($IsWindows) {
        Invoke-RestMethod 'https://astral.sh/uv/install.ps1' | Invoke-Expression
    }
    else {
        curl --proto '=https' --tlsv1.2 -LsSf 'https://astral.sh/uv/install.sh' | sh
    }

}

function New-Switch {
    Param($Cond = $False, $Alt = $False)
    return [switch]($Cond ? $True : $Alt)
}

function Invoke-Uv {
    <#.SYNOPSIS
    Invoke `uv`.#>
    [CmdletBinding(PositionalBinding = $False)]
    Param(
        [switch]$Sync,
        [switch]$Update,
        [switch]$Low,
        [switch]$High,
        [switch]$Build,
        [switch]$Force,
        [switch]$CI = (New-Switch $Env:SYNC_ENV_DISABLE_CI (New-Switch $Env:CI)),
        [switch]$Devcontainer = (New-Switch $Env:SYNC_ENV_DISABLE_DEVCONTAINER (New-Switch $Env:DEVCONTAINER)),
        [string]$PythonVersion = (Get-Content '.python-version'),
        [string]$PylanceVersion = (Get-Content '.pylance-version'),
        [Parameter(ValueFromRemainingArguments = $True)][string[]]$Run
    )
    if ($CI -or $Sync) {
        if (!$CI) {
            Install-Uv -Update:$Update
            # ? Sync submodules
            Get-ChildItem '.git/modules' -Filter 'config.lock' -Recurse -Depth 1 |
                Remove-Item
            git submodule update --init --merge
        }
        # ? Sync the environment
        if (!(Test-Path 'requirements')) {
            New-Item 'requirements' -ItemType 'Directory'
        }
        if ($Low) {
            uv sync --resolution lowest-direct --python $PythonVersion
            uv export --resolution lowest-direct --frozen --no-hashes --python $PythonVersion |
                Set-Content "$PWD/requirements/requirements_dev_low.txt"
            $Env:ENV_SYNCED = $null
        }
        elseif ($High) {
            uv sync --upgrade --python $PythonVersion
            uv export --frozen --no-hashes --python $PythonVersion |
                Set-Content "$PWD/requirements/requirements_dev_high.txt"
            $Env:ENV_SYNCED = $null
        }
        elseif ($Build) {
            uv sync --no-sources --no-dev --python $PythonVersion
            uv export --frozen --no-dev --no-hashes --python $PythonVersion |
                Set-Content "$PWD/requirements/requirements_prod.txt"
            uv build --python $PythonVersion
            $Env:ENV_SYNCED = $null
        }
        elseif ($CI -or $Force -or !$Env:ENV_SYNCED) {
            # ? Sync the environment
            uv sync --python $PythonVersion
            uv export --frozen --no-hashes --python $PythonVersion |
                Set-Content "$PWD/requirements/requirements_dev.txt"
            if ($CI) {
                Add-Content $Env:GITHUB_PATH ("$PWD/.venv/bin", "$PWD/.venv/scripts")
            }
            $Env:ENV_SYNCED = $True

            # ? Track environment variables to update `.env` with later
            $EnvVars = @{}
            $EnvVars.Add('PYRIGHT_PYTHON_PYLANCE_VERSION', $PylanceVersion)
            $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : "$PWD/.env"
            if (!(Test-Path $EnvFile)) { New-Item $EnvFile }

            # ? Get environment variables from `pyproject.toml`
            uv run --no-sync --python $PythonVersion dev init-shell |
                Select-String -Pattern '^(.+)=(.+)$' |
                ForEach-Object {
                    $Key, $Value = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
                    if ($EnvVars -notcontains $Key) { $EnvVars.Add($Key, $Value) }
                }

            # ? Get environment variables to update in `.env`
            $Keys = @()
            $Lines = Get-Content $EnvFile | ForEach-Object {
                $_ -Replace '^(?<Key>.+)=(?<Value>.+)$', {
                    $Key = $_.Groups['Key'].Value
                    if ($EnvVars.ContainsKey($Key)) {
                        $Keys += $Key
                        return "$Key=$($EnvVars[$Key])"
                    }
                    return $_
                }
            }
            # ? Sync environment variables and those in `.env`
            $NewLines = $EnvVars.GetEnumerator() | ForEach-Object {
                $Key, $Value = $_.Key, $_.Value
                Set-Item "Env:$Key" $Value
                if ($Keys -notcontains $Key) { return "$Key=$Value" }
            }
            @($Lines, $NewLines) | Set-Content $EnvFile
            # ? Environment-specific setup
            if ($Devcontainer) {
                $Repo = Get-ChildItem '/workspaces'
                $Packages = Get-ChildItem "$Repo/packages"
                $SafeDirs = @($Repo) + $Packages
                foreach ($Dir in $SafeDirs) {
                    if (!($SafeDirs -contains $Dir)) {
                        git config --global --add safe.directory $Dir
                    }
                }
            }
            elseif ($CI) {
                uv run --no-sync --python $PythonVersion dev elevate-pyright-warnings
            }
            # ? Install pre-commit hooks
            else {
                $Hooks = '.git/hooks'
                if (
                    !(Test-Path "$Hooks/pre-commit") -or
                    !(Test-Path "$Hooks/post-checkout")
                ) { uv run --no-sync --python $PythonVersion pre-commit install --install-hooks }
                if (!$Devcontainer -and (Get-Command -Name 'code' -ErrorAction 'Ignore')) {
                    $LocalExtensions = '.vscode/extensions'
                    $Pylance = 'ms-python.vscode-pylance'
                    if (!(Test-Path "$LocalExtensions/$Pylance-$PylanceVersion")) {
                        $Install = @(
                            "--extensions-dir=$LocalExtensions",
                            "--install-extension=$Pylance@$PylanceVersion"
                        )
                        code @Install
                        if (Test-Path $LocalExtensions) {
                            $PylanceExtension = (
                                Get-ChildItem -Path $LocalExtensions -Filter "$Pylance-*"
                            )
                            # ? Remove other files
                            Get-ChildItem -Path $LocalExtensions |
                                Where-Object { Compare-Object $_ $PylanceExtension } |
                                Remove-Item -Recurse
                            # ? Remove local Pylance bundled stubs
                            $PylanceExtension | ForEach-Object {
                                Get-ChildItem "$_/dist/bundled" -Filter '*stubs'
                            } | Remove-Item -Recurse
                        }
                    }
                }
            }
        }
    }
    if ($Run) { uv run --no-sync --python $PythonVersion $Run }
}
Set-Alias -Name 'iuv' -Value 'Invoke-Uv'

function Sync-Template {
    <#.SYNOPSIS
    Sync with template.#>
    Param(
        # Specific template VCS reference.
        [string]$Ref = 'HEAD',
        # Prompt for new answers.
        [switch]$Prompt,
        # Recopy, ignoring prior diffs instead of a smart update.
        [switch]$Recopy,
        # Stay on the current template version when updating.
        [switch]$Stay
    )
    if (!(Get-Command 'uv' -ErrorAction 'Ignore')) { Install-Uv -Update }
    $Copier = "copier@$(Get-Content '.copier-version')"
    $Ref = $Stay ? (Get-Content '.copier-answers.yml' | Find-Pattern '^_commit:\s.+([^-]+)$') : $Ref
    if ($Recopy) {
        if ($Prompt) { return uvx $Copier recopy $Defaults --vcs-ref=$Ref }
        return uvx $Copier recopy --overwrite --defaults
    }
    if ($Prompt) { return uvx $Copier update --vcs-ref=$Ref }
    return uvx $Copier update --defaults --vcs-ref=$Ref
}

function Initialize-Repo {
    <#.SYNOPSIS
    Initialize repository.#>

    git init

    # ? Modify GitHub repo later on only if there were not already commits in this repo
    try { git rev-parse HEAD }
    catch [System.Management.Automation.NativeCommandExitException] { $Fresh = $True }

    git add .
    try { git commit --no-verify -m 'Prepare template using blakeNaccarato/copier-python' }
    catch [System.Management.Automation.NativeCommandExitException] {}

    git submodule add --force --name 'typings' 'https://github.com/microsoft/python-type-stubs.git' 'typings'
    git add .
    try { git commit --no-verify -m 'Add template and type stub submodules' }
    catch [System.Management.Automation.NativeCommandExitException] {}

    Invoke-Uv -Sync -Update

    git add .
    try { git commit --no-verify -m 'Lock' }
    catch [System.Management.Automation.NativeCommandExitException] {}

    # ? Modify GitHub repo if there were not already commits in this repo
    if ($Fresh) {
        if (!(git remote)) {
            git remote add origin 'https://github.com/{{ project_owner_github_username }}/{{ github_repo_name }}.git'
            git branch --move --force main
        }
        gh repo edit --description (
            Get-Content '.copier-answers.yml' |
                Find-Pattern '^project_description:\s(.+)$'
        )
        gh repo edit --homepage 'https://{{ project_owner_github_username }}.github.io/{{ github_repo_name }}/'
    }

    git push --set-upstream origin main
}


function Initialize-Machine {
    <#.SYNOPSIS
    Finish machine initialization (cross-platform).#>

    # ? Set Git username if missing
    try { $name = git config 'user.name' }
    catch [System.Management.Automation.NativeCommandExitException] { $name = '' }
    if (!$name) {
        Write-Output 'Username missing from `.gitconfig`. Prompting for GitHub username/email ...'
        git config --global 'user.name' (Read-Host -Prompt 'Enter your GitHub username')
        git config --global fetch.prune true
        git config --global pull.rebase true
        git config --global push.autoSetupRemote true
        git config --global push.followTags true

        # ? Set Git email if missing
        try { $email = git config 'user.email' }
        catch [System.Management.Automation.NativeCommandExitException] { $email = '' }
        if (!$email) {
            git config --global 'user.email' (Read-Host -Prompt 'Enter the email address associated with your GitHub account')
        }
    }
    # ? Log in to GitHub API
    if (! (gh auth status)) { gh auth login -Done }
}

function Initialize-Windows {
    <#.SYNOPSIS
    Initialize Windows machine.#>

    $origPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    # ? Install and update `uv`
    Install-Uv -Update

    # ? Common winget options
    $Install = @(
        'install',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity'
        '--exact',
        '--no-upgrade',
        '--silent',
        '--source=winget'
    )

    # ? Install PowerShell Core
    winget @Install --id='Microsoft.PowerShell' --override='/quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ADD_PATH=1 ENABLE_MU=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1'
    # ? Set Windows PowerShell execution policy
    powershell -Command 'Set-ExecutionPolicy -Scope CurrentUser Unrestricted'
    # ? Set PowerShell Core execution policy
    pwsh -Command 'Set-ExecutionPolicy -Scope CurrentUser Unrestricted'

    # ? Install VSCode
    winget @Install --id='Microsoft.VisualStudioCode'
    # ? Install Windows Terminal
    winget @Install --id='Microsoft.WindowsTerminal'
    # ? Install GitHub CLI
    winget @Install --id='GitHub.cli'

    # ? Install git
    @'
[Setup]
Lang=default
Dir=C:/Program Files/Git
Group=Git
NoIcons=0
SetupType=default
Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,autoupdate,windowsterminal,scalar
Tasks=
EditorOption=VisualStudioCode
CustomEditorPath=
DefaultBranchOption=main
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=OpenSSL
CRLFOption=CRLFAlways
BashTerminalOption=MinTTY
GitPullBehaviorOption=Merge
UseCredentialManager=Enabled
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Disabled
EnablePseudoConsoleSupport=Disabled
EnableFSMonitor=Enabled
'@ | Out-File ($inf = New-TemporaryFile)
    winget @Install --id='Git.Git' --override="/SILENT /LOADINF=$inf"
    $ErrorActionPreference = $origPreference

    # ? Finish machine setup
    Initialize-Machine
}
