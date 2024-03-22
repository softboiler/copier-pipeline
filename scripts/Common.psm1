<#.SYNOPSIS
Common utilities.#>

function Test-CommandLock {
    <#.SYNOPSIS
    Test whether the file handle to a command is locked.#>
    Param ([parameter(Mandatory, ValueFromPipeline)][string]$Name)
    process {
        if (!($Name | Get-Command -ErrorAction Ignore)) { return $false }
        return Get-Command $Name | Test-FileLock
    }
}

function Test-FileLock {
    <#.SYNOPSIS
    Test whether a file handle is locked.#>
    Param ([parameter(Mandatory, ValueFromPipeline)][string]$Path)
    process {
        if ( !($Path | Test-Path) ) { return $false }
        try {
            $handle = (
                New-Object 'System.IO.FileInfo' $Path).Open([System.IO.FileMode]::Open,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None
            )
            if ($handle) { $handle.Close() }
            return $false
        }
        catch [System.IO.IOException], [System.UnauthorizedAccessException] { return $true }
    }
}

function Write-Progress {
    <#.SYNOPSIS
    Write progress and completion messages.#>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)][string]$Message,
        [switch]$Done,
        [switch]$Info
    )
    begin {
        $InProgress = !$Done -and !$Info
        if ($Info) { $Color = 'Magenta' }
        elseif ($Done) { $Color = 'Green' }
        else { $Color = 'Yellow' }
    }
    process {
        if ($InProgress) { Write-Host }
        "$Message$($InProgress ? '...' : '')" | Write-Host -ForegroundColor $Color
    }
}
