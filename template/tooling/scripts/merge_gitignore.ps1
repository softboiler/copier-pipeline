$original = Get-Content -Delimiter \0 -Path .gitignore
$replace = Get-Content -Delimiter \0 -Path tooling/scripts/gitignore_to_merge

$multiline = '(?m)'
$lookbehind = '(?<=^#\[\[\n)'
$match = '[\s\S]*'
$lookahead = '(?=^#\]\]\n)'

$original -replace ($multiline + $lookbehind + $match + $lookahead), $replace |
    Set-Content -Path .gitignore
