<#.SYNOPSIS
Run recipes.#>
[CmdletBinding()]
Param([Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs)

#? Source common shell config
. ./scripts/pre.ps1
#? Set environment variables and uv version
Sync-DevEnv | Out-Null
if ($Env:CI) { $Uvx = 'uvx' }
else { Sync-Uv; $Uvx = './uvx' }
#? Pass arguments to Just
if ($RemainingArgs) { & $Uvx --from "rust-just@$Env:JUST_VERSION" just @RemainingArgs }
else { & $Uvx --from "rust-just@$Env:JUST_VERSION" just list }
