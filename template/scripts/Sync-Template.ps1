<#.SYNOPSIS
Sync with template.#>
Param(
    # Specific template VCS reference.
    [Parameter(ValueFromPipeline)]$Ref = 'HEAD',
    # Prompt for new answers.
    [switch]$Prompt,
    # Recopy, ignoring prior diffs instead of a smart update.
    [switch]$Recopy,
    # Stay on the current template version when updating.
    [switch]$Stay,
    # Skip verifification when committing changes.
    [switch]$NoVerify
)
begin {
    . scripts/Initialize-Shell.ps1
    $Template = 'submodules/template'
    $Copier = 'copier@9.2.0'
}
process {
    if (($Template | Test-Path) -and !$Stay) {
        git submodule update --init --remote --merge $Template
        git add .
        $Msg = "Update template digest to $(git rev-parse "HEAD:$Template")"
        $origPreference = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        if ($NoVerify) { git commit --no-verify -m $Msg }
        else { git commit -m $Msg }
        $ErrorActionPreference = $origPreference
    }
    elseif (!$TemplateExists -and $Stay) { return }
    if ($Recopy) {
        if ($Prompt) { return uvx $Copier recopy --overwrite --vcs-ref=$Ref }
        return uvx $Copier recopy --overwrite --defaults --vcs-ref=$Ref
    }
    if ($Prompt) { return uvx $Copier update --vcs-ref=$Ref }
    return uvx $Copier update --defaults --vcs-ref=$Ref
}
