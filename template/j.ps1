<#.SYNOPSIS
Run recipes.#>
[CmdletBinding()]
Param([Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs)

# ? Source common shell config
. ./scripts/pre.ps1
# ? Set verbosity and CI-specific environment variables
$Verbose = $Env:CI -or ($DebugPreference -ne 'SilentlyContinue') -or ($VerbosePreference -ne 'SilentlyContinue')
$Env:DEV_VERBOSE = $Verbose ? 'true' : $null
$Env:JUST_VERBOSE = $Verbose ? '1' : $null
# ? Set environment variables and uv version
Sync-DevEnv
if ($Env:CI) { $Uvx = 'uvx' }
else { Sync-Uv; $Uvx = './uvx' }
# ? Pass arguments to Just
if ($RemainingArgs) { & $Uvx --from "rust-just@$Env:JUST_VERSION" just @RemainingArgs }
else { & $Uvx --from "rust-just@$Env:JUST_VERSION" just list }
