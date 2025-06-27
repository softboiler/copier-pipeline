Set-StrictMode -Version '3.0'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8
#? Extra variables only set in certain environments
$ExtraConVars = [ordered]@{
    DEV_OUTPUT_FILE        = '.dummy-ci-output-file'
    DEV_PYRIGHTCONFIG_FILE = '.dummy-ci-pyrightconfig.json'
}
$ExtraCiVars = [ordered]@{
    DEV_OUTPUT_FILE        = $Env:GITHUB_OUTPUT
    DEV_PYRIGHTCONFIG_FILE = 'pyrightconfig.json'
    JUST_COLOR             = 'always'
    JUST_NO_DOTENV         = 'true'
    JUST_TIMESTAMP         = 'true'
    JUST_VERBOSE           = '1'
}

function Sync-Uv {
    <#.SYNOPSIS
    Sync uv version.#>
    if (Get-Command './uv' -ErrorAction 'Ignore') {
        $OrigForceColor = $Env:FORCE_COLOR
        $Env:FORCE_COLOR = $null
        (./uv self version) -Match 'uv ([\d.]+)' | Out-Null
        $Env:FORCE_COLOR = $OrigForceColor
        if ($Matches[1] -eq $Env:UV_VERSION) { return }
        $Matches = $null
    }
    if (Get-Command 'uvx' -ErrorAction 'Ignore') {
        uvx --from "rust-just@$Env:JUST_VERSION" just inst uv
        return
    }
    if ($IsWindows) {
        $InstallUv = "Invoke-RestMethod https://astral.sh/uv/$Env:UV_VERSION/install.ps1 | Invoke-Expression"
        powershell -ExecutionPolicy 'ByPass' -Command $InstallUv
        return
    }
    curl -LsSf "https://astral.sh/uv/$Env:UV_VERSION/install.sh" | sh
}

function Sync-Env {
    <#.SYNOPSIS
    Write environment variables to the development environment used e.g. in `j.ps1`.#>
    Param([Hashtable]$ExtraVars = [ordered]@{})
    $Env:DEV_ENV = 'contrib'
    #? Set and track environment variables
    $EnvVars = Get-Content 'env.json' | ConvertFrom-Json
    $ExtraVars.GetEnumerator() | ForEach-Object {
        $K, $V = $_.Key, $_.Value
        if ($null -ne $V) { $EnvVars | Add-Member -NotePropertyName $K -NotePropertyValue $V }
    }
    $DevEnv = [ordered]@{}
    $EnvVars.PsObject.Properties | Sort-Object 'Name' | ForEach-Object {
        $K, $V = $_.Name, $_.Value
        if ($null -ne $V) {
            Set-Item "Env:$K" $V
            $DevEnv[$K] = $V
        }
    }
    return $DevEnv
}

function Sync-ContribEnv {
    <#.SYNOPSIS
    Write environment variables to VSCode contributor environment.#>
    $DevEnvSettingsJson = ''
    $DevEnvWorkflowYaml = ''
    (Sync-Env).GetEnumerator() | ForEach-Object {
        $K, $V = $_.Key, $_.Value
        $DevEnvSettingsJson += "`n    `"$K`": `"$V`","
        $DevEnvWorkflowYaml += "`n      $($K.ToLower()): { value: `"$V`" }"
    }
    $DevEnvSettingsJson = "{$($DevEnvSettingsJson.TrimEnd(','))`n  }"
    $Settings = '.vscode/settings.json'
    $SettingsContent = Get-Content $Settings -Raw
    foreach ($Plat in ('linux', 'osx', 'windows')) {
        $Pat = "(?m)`"terminal\.integrated\.env\.$Plat`"\s*:\s*\{[^}]*\}"
        $Repl = "`"terminal.integrated.env.$Plat`": $DevEnvSettingsJson"
        $SettingsContent = $SettingsContent -Replace $Pat, $Repl
    }
    Set-Content $Settings $SettingsContent -NoNewline
    $Workflow = '.github/workflows/env.yml'
    $WorkflowPat = '(?m)^\s{4}outputs:(?:\s\{\}|(?:\n^\s{6}.+$)+)'
    $WorkflowRepl = "    outputs:$DevEnvWorkflowYaml"
    $WorkflowContent = (Get-Content $Workflow -Raw) -Replace $WorkflowPat, $WorkflowRepl
    Set-Content $Workflow $WorkflowContent -NoNewline
    return Sync-Env $ExtraConVars
}

function Sync-CiEnv {
    <#.SYNOPSIS
    Sync CI environment path and environment variables.#>
    $Env:DEV_ENV = 'ci'
    #? Add `.venv` tools to CI path. Needed for some GitHub Actions like pyright
    $PathFile = $Env:GITHUB_PATH ? $Env:GITHUB_PATH : '.dummy-ci-path-file'
    if (!(Test-Path $PathFile)) { New-Item $PathFile }
    if ( !(Get-Content $PathFile | Select-String -Pattern '.venv') ) {
        $Workdir = $PWD -Replace '\\', '/'
        Add-Content $PathFile ("$Workdir/.venv/bin", "$Workdir/.venv/scripts")
    }
    #? Write environment variables to CI environment file
    $CiEnv = Sync-Env $ExtraCiVars
    $CiEnvText = ''
    $CiEnv.GetEnumerator() | ForEach-Object {
        $K, $V = $_.Key, $_.Value
        $CiEnvText += "$K=$V`n"
    }
    $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.dummy-ci-env-file'
    if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
    if (!(Get-Content $EnvFile | Select-String -Pattern 'DEV_ENV_SET')) {
        $CiEnvText | Add-Content $EnvFile
    }
    return $CiEnv
}
