<#.SYNOPSIS
Update the project from the project template.#>
Param(
    # Recopy ignoring prior diffs instead of a smart update.
    [switch]$Recopy,
    # Use question defaults.
    [switch]$Defaults,
    # Don't bump the template digest.
    [switch]$NoBump,
    # Skip verifification when committing.
    [switch]$NoVerify
)
Import-Module ./scripts/Common.psm1
$NoBump = [bool]$true
if ( $Recopy ) {
    if ($Defaults) { copier recopy --overwrite --defaults }
    else { copier recopy --overwrite }

}
else {
    $head = git rev-parse HEAD:submodules/template
    if (!$NoBump) {
        git submodule update --init --remote --merge submodules/template
        git add --all
        $msg = "Update template digest to $head"
        if ($NoVerify) { git commit --no-verify -m $msg }
        else { git commit -m $msg }
    }
    if ($Defaults) { copier update --vcs-ref=$head --defaults }
    else { copier update --vcs-ref=$head }
}
