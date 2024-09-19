<#.SYNOPSIS
Sync environment.#>

Param(
    [string]$PythonVersion,
    [string]$UvVersion,
    [switch]$Low,
    [switch]$High,
    [switch]$Build
)

. scripts/Initialize-Shell.ps1

# ? Error-handling
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$ErrorView = 'NormalView'

# ? Fix leaky UTF-8 encoding settings on Windows
if ($IsWindows) {
    # ? Now PowerShell pipes will be UTF-8. Note that fixing it from Control Panel and
    # ? system-wide has buggy downsides.
    # ? See: https://github.com/PowerShell/PowerShell/issues/7233#issuecomment-640243647
    [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
}

$PythonVersion = $PythonVersion ? $PythonVersion : (Get-Content '.python-version')
$UvVersion = $UvVersion ? $UvVersion : (Get-Content '.uv-version')
$PylanceVersion = $PylanceVersion ? $PylanceVersion : (Get-Content '.pylance-version')

$CI = [bool]($Env:SYNC_ENV_DISABLE_CI ? $null : $Env:CI)
$Devcontainer = [bool]($Env:SYNC_ENV_DISABLE_DEVCONTAINER ? $null : $Env:DEVCONTAINER)

if (!$CI) {
    if (Get-Command 'uv' -ErrorAction 'Ignore') {
        if (!(uv --version | Select-String $UvVersion)) { uv self update $UvVersion }
    }
    else {
        if ($IsWindows) { Invoke-RestMethod "https://github.com/astral-sh/uv/releases/download/$UvVersion/uv-installer.ps1" | Invoke-Expression }
        else { curl --proto '=https' --tlsv1.2 -LsSf "https://github.com/astral-sh/uv/releases/download/$UvVersion/uv-installer.sh" | sh }
    }
    Get-ChildItem '.git/modules' -Filter 'config.lock' -Recurse -Depth 1 | Remove-Item
    git submodule update --init --merge
}

# ? Sync the environment
if (!(Test-Path 'requirements')) { New-Item 'requirements' -ItemType 'Directory' }
if ($Low) {
    uv sync --resolution lowest-direct --python $PythonVersion
    uv export --resolution lowest-direct --frozen --no-hashes --python $PythonVersion |
        Set-Content "$PWD/requirements/requirements_dev_low.txt"
}
elseif ($High) {
    uv sync --upgrade --python $PythonVersion
    uv export --frozen --no-hashes --python $PythonVersion |
        Set-Content "$PWD/requirements/requirements_dev_high.txt"
}
elseif ($Build) {
    uv sync --no-sources --no-dev --python $PythonVersion
    uv export --frozen  --no-dev --no-hashes --python $PythonVersion |
        Set-Content "$PWD/requirements/requirements_prod.txt"
    uv build --python $PythonVersion
    if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
    return
}
else {
    if ($Env:SYNC_ENV_SYNCED) {
        if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
        return
    }
    uv sync --python $PythonVersion
    uv export --frozen --no-hashes --python $PythonVersion |
        Set-Content "$PWD/requirements/requirements_dev.txt"
    $Env:SYNC_ENV_SYNCED = $true
}
if ($IsWindows) { .venv/scripts/activate.ps1 } else { .venv/bin/activate.ps1 }
if ($CI) { Add-Content $Env:GITHUB_PATH ("$PWD/.venv/bin", "$PWD/.venv/scripts") }

# ? Track environment variables to update `.env` with later
$EnvVars = @{}
$EnvVars.Add('PYRIGHT_PYTHON_PYLANCE_VERSION', $PylanceVersion)
$EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : "$PWD/.env"
if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
# ? Get environment variables from `pyproject.toml`
dev init-shell |
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
elseif ($CI) { dev elevate-pyright-warnings }
else {
    $Hooks = '.git/hooks'
    if (!(Test-Path "$Hooks/post-checkout") -or !(Test-Path "$Hooks/pre-commit") -or
        !(Test-Path "$Hooks/pre-push")
    ) { pre-commit install --install-hooks }
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
                $PylanceExtension = Get-ChildItem -Path $LocalExtensions -Filter "$Pylance-*"
                # ? Remove other files
                Get-ChildItem -Path $LocalExtensions |
                    Where-Object { Compare-Object $_ $PylanceExtension } |
                    Remove-Item -Recurse
                # ? Remove local Pylance bundled stubs
                $PylanceExtension |
                    ForEach-Object { Get-ChildItem "$_/dist/bundled" -Filter '*stubs' } |
                    Remove-Item -Recurse
            }
        }
    }
}
