<#.SYNOPSIS
Run recipes.#>
[CmdletBinding()]
Param([Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs)

#? Source common shell config
. './scripts/pre.ps1'
#? Set environment variables and uv
if ($Env:CI) {
    $Uvx = 'uvx'
    Sync-Env $ExtraCiVars | Out-Null
}
else {
    Sync-Env $ExtraConVars | Out-Null
    Sync-Uv; $Uvx = './uvx'
}
#? Pass arguments to Just
if ($RemainingArgs) { & $Uvx --from "rust-just@$Env:JUST_VERSION" just @RemainingArgs }
else { & $Uvx --from "rust-just@$Env:JUST_VERSION" just list }
