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
if (!(Get-Command 'uv' -ErrorAction 'Ignore')) { Install-Uv -Update }
$Copier = "copier@$Env:COPIER_VERSION"
$Ref = $Stay ? (Get-Content '.copier-answers.yml' | Find-Pattern '^_commit:\s.+-(.+)$') : $Ref
if ($Recopy) {
    if ($Prompt) { return ./uvx $Copier recopy $Defaults --vcs-ref=$Ref }
    return ./uvx $Copier recopy --overwrite --defaults
}
if ($Prompt) { return ./uvx $Copier update --vcs-ref=$Ref }
return ./uvx $Copier update --defaults --vcs-ref=$Ref
