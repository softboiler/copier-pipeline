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
    $TemplateExists = $Template | Test-Path
    function Get-Ref {
        <#.SYNOPSIS
        Get VCS reference.
        #>
        Param($Ref)
        if ($TemplateExists) {
            return ($Ref -eq 'HEAD') ? $(git rev-parse $Template) : $Ref
        }
        return $Ref
    }
}
process {
    if ($TemplateExists) {
        if (!$Stay) {
            $Ref = Get-Ref $Ref
            git submodule update --init --remote --merge $Template
            git add .
            $Msg = "Update template digest to $Ref"
            $origPreference = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            if ($NoVerify) { git commit --no-verify -m $Msg }
            else { git commit -m $Msg }
            $ErrorActionPreference = $origPreference
        }
        $Ref = Get-Ref $Ref
    }
    else {
        if ($Stay) { return }
        $Ref = Get-Ref $Ref
    }
    if ($Recopy) {
        if ($Prompt) { return copier recopy --overwrite --vcs-ref=$Ref }
        return copier recopy --overwrite --defaults --vcs-ref=$Ref
    }
    if ($Prompt) { return copier update --vcs-ref=$Ref }
    return copier update --defaults --vcs-ref=$Ref
}
