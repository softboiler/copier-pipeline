# Get filepaths
$original_answers_file = '.copier-answers.yml'
$original_answers = Get-Content -Delimiter \0 -Path $original_answers_file
$new_answers_file = "$(Split-Path -LeafBase $original_answers_file).yml"

# Building blocks for two regex replacements
$commit_lookbehind = '(?<=_commit: )'  # (have to use \s instead of \n)
$repo_lookbehind = '(?<=_src_path: )'  # (have to use \s instead of \n)
$match = '\S+'  # anything in-between
$lookahead = '(?=\s)'  # "#]]\n" (have to use \s instead of \n)
# The regexes
$commit = "${commit_lookbehind}${match}${lookahead}"
$repo = "${repo_lookbehind}${match}${lookahead}"
# The replacements
$commit_replacement = '7a47a0330ec259a93dde925ca8b2bb88b06b40d3'
$repo_replacement = 'gh:blakeNaccarato/copier-python-init'

# Make two replacements in series, then write to file
$new_answers = $original_answers -replace $commit, $commit_replacement
$new_answers = $new_answers -replace $repo, $repo_replacement
$new_answers | Set-Content -NoNewline -Path $new_answers_file
