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
    [switch]$Stay
)
begin {
    . scripts/Initialize-Shell.ps1
    $Template = 'submodules/template'
    $Copier = 'copier@9.2.0'
    $TemplateExists = $Template | Test-Path
    $Template = $TemplateExists ? $Template : 'origin/main'
    function Get-Ref {
        Param($Ref = 'HEAD')
        $TemplateRev = $TemplateExists ? "HEAD:$Template" : 'origin/main'
        return ($Ref -eq 'HEAD') ? (git rev-parse $TemplateRev) : $Ref
    }
}
process {
    if ($TemplateExists -and !$Stay) {
        git submodule update --init --remote --merge $Template
        git add .
        try { git commit --no-verify -m "Update template digest to $(Get-Ref $Ref)" }
        catch [System.Management.Automation.NativeCommandExitException] { $AlreadyUpdated = $true }
    }
    elseif (!$TemplateExists -and $Stay) { return }
    $Ref = Get-Ref $Ref
    if ($Recopy) {
        if ($Prompt) { return uvx $Copier recopy --overwrite --vcs-ref=$Ref }
        return uvx $Copier recopy --overwrite --defaults --vcs-ref=$Ref
    }
    if ($Prompt) { return uvx $Copier update --vcs-ref=$Ref }
    return uvx $Copier update --defaults --vcs-ref=$Ref
}
