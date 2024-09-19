<#.SYNOPSIS
Sync with template.#>
Param(
    # Specific template VCS reference.
    [string]$Ref = 'HEAD',
    # Prompt for new answers.
    [switch]$Prompt,
    # Recopy, ignoring prior diffs instead of a smart update.
    [switch]$Recopy,
    # Stay on the current template version when updating.
    [switch]$Stay
)

. scripts/Common.ps1
. scripts/Initialize-Shell.ps1

$Copier = "copier@$(Get-Content '.copier-version')"
$Ref = $Stay ? (Get-Content '.copier-answers.yml' | Find-Pattern '^_commit:\s.+([^-]+)$') : $Ref
if ($Recopy) {
    if ($Prompt) { return uvx $Copier $Subcommand $Defaults --vcs-ref=$Ref }
    return uvx $Copier recopy --overwrite --defaults --vcs-ref=$Ref
}
if ($Prompt) { return uvx $Copier update --vcs-ref=$Ref }
return uvx $Copier update --defaults --vcs-ref=$Ref
