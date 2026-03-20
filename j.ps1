<#.SYNOPSIS
Run Just recipes.#>
[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs)

#* MARK: Config sourced by recipes
Set-StrictMode -Version '3.0'
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $True
$ErrorView = 'NormalView'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.Encoding]::UTF8

#* MARK: Called at the bottom of this file
function Invoke-Just {
    <#.SYNOPSIS
    Invoke Just.#>
    #? Capture variables set by command line
    $Vars = @{}
    if ($RemainingArgs) {
        $Idx = 0
        for ($Idx = 0; $Idx -lt $RemainingArgs.Count; $Idx++) {
            if ($RemainingArgs[$Idx] -ne '--set') { continue }
            if (($Idx + 2) -ge $RemainingArgs.Count) { break }
            $Vars[$RemainingArgs[$Idx + 1]] = $RemainingArgs[$Idx + 2]
            $Idx += 2
        }
    }

    #? Sync environment variables necessary for bootstrapping
    $Uvx = $Env:CI ? 'uvx' : './uvx'
    $Environ = Merge-Envs ((Get-Env 'base'), $Vars)
    $Just = @('--from', "rust-just@$($Environ['JUST_VERSION'])", 'just')

    #? Just sync CLI vars if calling recursively from inside a recipe
    if ($Env:JUST) { $Vars | Sync-Env }
    else {
        $RawCI = ($Environ['ci'] ? $Environ['ci'] : $Env:CI)
        $CI = ($null -ne $RawCI) -and ($RawCI -ne 0)
        #? Otherwise sync the full environment
        $Environ = Merge-Envs ($Environ, (Get-Env ($CI ? 'ci' : 'contrib')))
        $Environ | Sync-Env
        #? Install YAML parser in CI if missing, sync uv in contrib environment
        if ($CI) { & $Uvx @Just --justfile 'scripts/inst.just' 'powershell-yaml' }
        else { Sync-Uv $Environ['UV_VERSION'] }
        #? Parse template answers YAML data, merge into environment, and sync
        Merge-Envs ((Get-Env 'answers'), $Environ) | Sync-Env
    }
    $Env:JUST = '1'

    #? Invoke Just if arguments passed, otherwise can dot-source in recipes w/o recurse
    try { if ($RemainingArgs) { & $Uvx @Just @RemainingArgs } }
    finally { $Env:JUST = $null }
}

#* MARK: Functions used above and sourced by recipes

function Sync-Uv {
    <#.SYNOPSIS
    Sync uv version.#>
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Version)
    if (Get-Command './uv' -ErrorAction 'Ignore') {
        (./uv --color 'never' self version) -match 'uv ([\d.]+)' | Out-Null
        if ($Matches[1] -eq $Version) { return }
    }
    if ($IsWindows) {
        $InstallUv = "Invoke-RestMethod https://astral.sh/uv/$Version/install.ps1 | Invoke-Expression"
        powershell -ExecutionPolicy 'ByPass' -Command $InstallUv
        return
    }
    curl -LsSf "https://astral.sh/uv/$Version/install.sh" | sh
}

function Sync-Env {
    <#.SYNOPSIS
    Sync environment variables.#>
    param([Parameter(Mandatory, ValueFromPipeline)][hashtable]$Environ)
    process {
        ($Environ | Format-Env -Upper).GetEnumerator() |
            ForEach-Object { Set-Item "Env:$($_.Name)" $_.Value }
    }
}

function Limit-Env {
    <#.SYNOPSIS
    Limit environment to specific variables.#>
    param(
        [Parameter(Mandatory)][hashtable]$Environ,
        [Parameter(Mandatory)][string[]]$Vars
    )
    $Limited = @{}
    $Environ.GetEnumerator() | ForEach-Object {
        if ($Vars -contains $_.Name) { $Limited[$_.Name] = $_.Value }
    }
    return $Limited
}

function Merge-Envs {
    <#.SYNOPSIS
    Merge environment variables.#>
    param([Parameter(Mandatory)][hashtable[]]$Envs)
    $Merged = @{}
    $Envs | ForEach-Object { $_.GetEnumerator() } | ForEach-Object {
        $Merged[$_.Name] = $_.Value
    }
    return Format-Env $Merged
}

function Get-Env {
    <#.SYNOPSIS
    Get environment variables.#>
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Name)
    process {
        $Envs = (Get-Content 'env.json' | ConvertFrom-Json)
        if (($Path = $Envs.$Name) -is [string]) {
            if ($Path.EndsWith('.json')) {
                $RawEnviron = Get-Content $Path | ConvertFrom-Json
            }
            elseif ($Path.EndsWith('.yaml') -or $Path.EndsWith('.yml')) {
                $RawEnviron = Get-Content $Path | ConvertFrom-Yaml
            }
            else { throw "Could not parse environment '$Name' at '$Path'" }
        }
        else { $RawEnviron = $Envs.$Name.PsObject.Properties }
        $Environ = @{}
        $RawEnviron.GetEnumerator() | ForEach-Object {
            $Name = (($_.Name -match '^_.+$') ? "template$($_.Name)" : $_.Name)
            $Value = [string]$_.Value
            if (('false', 'true') -contains $Value.ToLower()) { $Value = $Value.ToLower() }
            if ($Value -match '^Env:.+$') { $Value = Get-EnvVar $Value }
            if (($null -eq $Value) -or ($Value -eq '')) { $Value = $null }
            $Environ[$Name] = $Value
        }
        return $Environ
    }
}

function Format-Env {
    <#.SYNOPSIS
    Sort environment variables by name.#>
    param(
        [Parameter(Mandatory, ValueFromPipeline)][hashtable]$Environ,
        [switch]$Upper,
        [switch]$Lower
    )
    $Formatted = [ordered]@{}
    $Environ.GetEnumerator() | Sort-Object 'Name' | ForEach-Object {
        if ($Upper) { $Name = $_.Name.ToUpper() }
        elseif ($Lower) { $Name = $_.Name.ToLower() }
        else { $Name = $_.Name }
        $Formatted[$Name] = $_.Value
    }
    return $Formatted
}

function Get-EnvVar {
    <#.SYNOPSIS
    Get value of environment variable.#>
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Name)
    process {
        $Var = Get-Item $Name -ErrorAction 'Ignore'
        if (!$Var) { return }
        return $Var | Select-Object -ExpandProperty 'Value'
    }
}

#* MARK: Invoke Just
Invoke-Just
