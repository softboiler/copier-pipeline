Set-StrictMode -Version '3.0'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

function Sync-DevEnv {
    <#.SYNOPSIS
    Write environment variables to the development environment used e.g. in `j.ps1`.#>
    #? Set verbosity and CI-specific environment variables
    $Verbose = $Env:CI -or ($DebugPreference -ne 'SilentlyContinue') -or ($VerbosePreference -ne 'SilentlyContinue')
    $Env:DEV_VERBOSE = $Verbose ? 'true' : $null
    $Env:JUST_VERBOSE = $Verbose ? '1' : $null
    $Env:OUTPUT_FILE = $Env:GITHUB_OUTPUT ? $Env:GITHUB_OUTPUT : '.dummy-ci-output-file'
    #? Populate DEV_ENV environment variable for passing environment variables to set
    $EnvVars = Get-Content 'env.json' | ConvertFrom-Json
    @{
        JUST_COLOR     = $Env:CI ? 'always' : $null
        JUST_NO_DOTENV = $Env:CI ? 'true' : $null
        JUST_TIMESTAMP = $Env:CI ? 'true' : $null
    }.GetEnumerator() | ForEach-Object {
        $K, $V = $_.Key, $_.Value
        if ($V) { $EnvVars | Add-Member -NotePropertyName $K -NotePropertyValue $V }
    }
    $DevEnv = ''
    $EnvVars.PsObject.Properties | Sort-Object Name | ForEach-Object {
        $N, $V = $_.Name, $_.Value
        if ($V) {
            Set-Item "Env:$N" $V
            $DevEnv += "$N=$V;"
        }
    }
    $DevEnv = $DevEnv.TrimEnd(';')
    return $DevEnv
}

function Sync-ContribEnv {
    <#.SYNOPSIS
    Write environment variables to VSCode contributor environment.#>
    $DevEnvSettingsJson = ''
    $DevEnvWorkflowYaml = ''
    $DevEnv = Sync-DevEnv
    $DevEnv -Split ';' | Select-String -Pattern '([^=]+)=([^=]+)' | ForEach-Object {
        $K, $V = $_.Matches.Groups[1].Value, $_.Matches.Groups[2].Value
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
    return $DevEnv
}

function Sync-CiEnv {
    <#.SYNOPSIS
    Sync CI environment path and environment variables.#>
    #? Sync the contributor environment. Dirty working tree will fail CI.
    $DevEnv = Sync-ContribEnv
    #? Add `.venv` tools to CI path. Needed for some GitHub Actions like pyright
    $PathFile = $Env:GITHUB_PATH ? $Env:GITHUB_PATH : '.dummy-ci-path-file'
    if (!(Test-Path $PathFile)) { New-Item $PathFile }
    if ( !(Get-Content $PathFile | Select-String -Pattern '.venv') ) {
        Add-Content $PathFile ('.venv/bin', '.venv/scripts')
    }
    #? Write environment variables to CI environment file
    $EnvFile = $Env:GITHUB_ENV ? $Env:GITHUB_ENV : '.dummy-ci-env-file'
    if (!(Test-Path $EnvFile)) { New-Item $EnvFile }
    if (!(Get-Content $EnvFile | Select-String -Pattern 'DEV_ENV_SET')) {
        $DevEnv -Split ';' | Add-Content $EnvFile
    }
    Write-Output $DevEnv
}
