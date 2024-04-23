<#.SYNOPSIS
Sync with template.#>
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
. scripts/Initialize-Shell.ps1
$template = 'submodules/template'
$templateExists = $template | Test-Path
if (!$templateExists -and $Stay) { return }
if ($Recopy) {
    $head = git rev-parse HEAD:submodules/template
    if ($Prompt) { return copier recopy --overwrite --vcs-ref=$head }
    return copier recopy --overwrite --defaults --vcs-ref=$head
}
if ($templateExists) {
    if (!$Stay) {
        git submodule update --init --remote --merge $template
        git add --all
        $msg = "Update template digest to $(git rev-parse HEAD:submodules/template)"
        $origPreference = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        if ($NoVerify) { git commit --no-verify -m $msg }
        else { git commit -m $msg }
        $ErrorActionPreference = $origPreference
    }
    $head = git rev-parse HEAD:submodules/template
    if ($Prompt) { return copier update --vcs-ref=$head }
    return copier update --vcs-ref=$head --defaults
}
if ($Prompt) { return copier update }
copier update --defaults
