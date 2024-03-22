<#.SYNOPSIS
Sync project with template.#>
Param(
    # Prompt for new answers.
    [switch]$Prompt,
    # Recopy, ignoring prior diffs instead of a smart update.
    [switch]$Recopy,
    # Bump to the latest template.
    [switch]$Latest,
    # Skip verifification when committing changes.
    [switch]$NoVerify
)
if ( $Recopy ) {
    if ($Prompt) { return copier recopy --overwrite }
    return copier recopy --overwrite --defaults
}
if ( $Latest ) {
    git submodule update --init --remote --merge submodules/template
    git add --all
    $msg = "Update template digest to $head"
    if ($NoVerify) { git commit --no-verify -m $msg }
    else { git commit -m $msg }
}
$head = git rev-parse HEAD:submodules/template
if ($Prompt) { return copier update --vcs-ref=$head }
copier update --vcs-ref=$head --defaults
