<#.SYNOPSIS
Update the project from the project template.#>
Param(
    # Whether to recopy the template, ignoring prior diffs, or update in a smart manner.
    [switch]$Recopy,
    # Whether to use default values for unanswered questions.
    [switch]$Defaults,
    # Whether to skip verifification when committing.
    [switch]$NoVerify
)
# ? Stop on first error and enable native command error propagation.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$PSNativeCommandUseErrorActionPreference | Out-Null
if ( $Recopy ) {
    copier recopy --overwrite --defaults=$Defaults
}
else {
    git submodule update --init --remote --merge submodules/template
    git add --all
    $head = git rev-parse HEAD:submodules/template
    $msg = "Update template digest to $head"
    git commit $($NoVerify ? '--no-verify': $null) -m "Update template digest to $msg"
    copier update --vcs-ref=$head --defaults=$Defaults
}
