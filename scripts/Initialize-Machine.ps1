<#.SYNOPSIS
Finish machine initialization (cross-platform).#>

. scripts/Common.ps1
. scripts/Initialize-Shell.ps1

# Set Git username if missing
try { $name = git config --global 'user.name' }
catch [System.Management.Automation.NativeCommandExitException] { $name = '' }
if (!$name) {
    git config --global 'user.name' "$((Get-Content '.copier-answers.yml' |
    Select-String -Pattern '^project_owner_github_username:\s(.+)$').Matches.Groups[1].value)"
    # Have Git auto set up local branches to track remote branches if not yet configured
    try { $name = git config --global 'push.autoSetupRemote' }
    catch [System.Management.Automation.NativeCommandExitException] { $name = '' }
    if (!$name) { git config --global 'push.autoSetupRemote' 'true' }
}

# Set Git email if missing
try { $name = git config --global 'user.email' }
catch [System.Management.Automation.NativeCommandExitException] { $name = '' }
if (!$name) {
    git config --global 'user.email' "$((Get-Content '.copier-answers.yml' |
    Select-String -Pattern '^project_email:\s(.+)$').Matches.Groups[1].value)"
}

# Log in to GitHub API
if (! (gh auth status)) {
    'LOGGING IN TO GITHUB API' | Write-Progress
    gh auth login
    'GITHUB API LOGIN COMPLETE' | Write-Progress -Done
}
