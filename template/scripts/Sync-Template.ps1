<#.SYNOPSIS
Sync project with template.#>
Param(
    # Prompt for new answers.
    [switch]$Prompt,
    # Recopy, ignoring prior diffs instead of a smart update.
    [switch]$Recopy,
    # Stay on the current template version when updating.
    [switch]$Stay,
    # Skip verifification when committing changes.
    [switch]$NoVerify
)
$template = 'submodules/template'
$templateExists = $template | Test-Path
if ( $Recopy -or (!$templateExists -and $Stay) ) {
    if ($Prompt) { return copier recopy --overwrite }
    return copier recopy --overwrite --defaults
}
if ($templateExists) {
    if (!$Stay) {
        git submodule update --init --remote --merge $template
        git add --all
        $msg = "Update template digest to $(git rev-parse HEAD:submodules/template)"
        if ($NoVerify) { git commit --no-verify -m $msg }
        else { git commit -m $msg }
    }
    $head = git rev-parse HEAD:submodules/template
    if ($Prompt) { return copier update --vcs-ref=$head }
    return copier update --vcs-ref=$head --defaults
}
if ($Prompt) { return copier update }
copier update --defaults
