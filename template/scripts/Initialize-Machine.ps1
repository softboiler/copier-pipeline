<#.SYNOPSIS
Finish machine initialization (cross-platform).#>

. scripts/Common.ps1
. scripts/Initialize-Shell.ps1

if (! (gh auth status)) {
    'LOGGING IN TO GITHUB API' | Write-Progress
    gh auth login
    'GITHUB API LOGIN COMPLETE' | Write-Progress -Done
}
