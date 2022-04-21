if(Test-Path -Path .gitignore){
    $original = Get-Content -Delimiter \0 -Path .gitignore
    $replace = Get-Content -Delimiter \0 -Path .tools/scripts/gitignore_to_merge

    $lookbehind = '(?<=\s#\[\[\s)'  # "#[[\n" (have to use \s instead of \n)
    $match = '[\s\S]*'  # anything in-between
    $lookahead = '(?=\s#\]\]\s)'  # "#]]\n" (have to use \s instead of \n)

    $original -replace "$lookbehind$match$lookahead", $replace |
        Set-Content -NoNewline -Path .gitignore
}
else{
    Set-Content .gitignore .tools/scripts/.gitignore_init
}
