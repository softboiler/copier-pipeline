<#.SYNOPSIS
Common utilities.#>
function Find-Pattern {
    <#.SYNOPSIS
    Find the first match to a pattern in a string.#>
    Param(
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory, ValueFromPipeline)][string]$String
    )
    process {
        if ($Groups = ($String | Select-String -Pattern $Pattern).Matches.Groups) {
            return $Groups[1].value
        }
    }
}
