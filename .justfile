#* Project
copier_version :=\
  env('COPIER_VERSION', empty)
github_repo_name :=\
  env('GITHUB_REPO_NAME', empty)
output_file :=\
  env('OUTPUT_FILE', empty)
project_name :=\
  env('PROJECT_NAME', empty)
project_owner_github_username :=\
  env('PROJECT_OWNER_GITHUB_USERNAME', empty)
project_version :=\
  env('PROJECT_VERSION', empty)
template_ref :=\
  env('TEMPLATE_REF', empty)

#* Settings
set dotenv-load
set unstable

#* Imports
import 'scripts/common.just'

#* Modules
#? 🌐 Install
mod inst 'scripts/inst.just'

#* Shells
set shell :=\
  ['pwsh', '-NonInteractive', '-NoProfile', '-CommandWithArgs']
set script-interpreter :=\
  ['pwsh', '-NonInteractive', '-NoProfile']

#* Reusable shell preambles
pre :=\
  pwsh_pre + ';'
script_pre :=\
  pwsh_pre

#* Python dev package
_dev :=\
  _uvr + sp + quote(project_name + '-dev')

#* ♾️  Self

# 📃 [DEFAULT] List recipes
[group('♾️  Self')]
list:
  {{pre}} {{_just}} --list
alias l := list

# ♾️  Run Just recipes...
[group('♾️  Self')]
just *args:
  {{pre}} {{_just}} {{args}}
alias j := just

#* ⛰️ Environments

# 🏃 Run shell commands with UV synced...
[group('⛰️ Environments')]
run *args: uv-sync
  @{{ if args==empty { quote(YELLOW+'No command given'+NORMAL) } else {empty} }}
  {{ if args!=empty { pre + sp + args } else {empty} }}
alias r := run

# 👥 Run recipes as a contributor...
[group('⛰️ Environments')]
con *args: con-pre-commit-hooks uv-sync
  {{pre}} Sync-ContribEnv
  @{{ if args==empty {_no_recipe_given} else {empty} }}
  {{ if args!=empty { pre + _just + sp + args } else {empty} }}
alias c := con

# 🤖 Run recipes in CI...
[group('⛰️ Environments')]
ci *args: uv-sync
  {{pre}} Sync-CiEnv
  {{pre}} {{_dev}} elevate-pyright-warnings
  {{ if args!=empty { pre + _just + sp + args } else {empty} }}

# 📦 Run recipes in a devcontainer
[script, group('⛰️ Environments')]
@devcontainer *args:
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Devcontainers need submodules explicitly marked as safe directories'+NORMAL}}
  $Repo = Get-ChildItem '/workspaces'
  $Packages = Get-ChildItem "$Repo/packages"
  $SafeDirs = @($Repo) + $Packages
  foreach ($Dir in $SafeDirs) {
    if (!($SafeDirs -contains $Dir)) { git config --global --add safe.directory $Dir }
  }
  {{ if args==empty { 'return' } else { '#?'+BLUE+sp+'Run recipe'+NORMAL } }}
  {{ if args==empty {empty} else { _just + sp + args } }}
alias dc := devcontainer

_no_recipe_given :=\
  quote(BLACK+'No recipe given'+NORMAL)

#* 🟣 uv

#? Uv invocations
_uv_options :=\
  '--all-packages' \
  + sp + '--python' + ( \
    if python_version==empty {empty} else { sp + quote(python_version) } \
  )
_uvr :=\
  _uv + sp + 'run' + sp + _uv_options
_uvs :=\
  _uv + sp + 'sync' + sp + _uv_options

# 🟣 uv ...
[group('🟣 uv')]
uv *args:
  {{pre}} {{_uv}} {{args}}

# 🏃 uv run ...
[group('🟣 uv')]
uv-run *args:
  {{pre}} {{_uvr}} {{args}}
alias uvr := uv-run

# 🏃 uvx ...
[group('🟣 uv')]
uvx *args:
  {{pre}} {{_uv}} {{args}}

# 🔃 uv sync ...
[group('🟣 uv')]
uv-sync *args:
  {{pre}} {{_uvs}} {{args}}
alias uvs := uv-sync
alias sync := uv-sync

#* 🐍 Python

# 🐍 python ...
[group('🐍 Python')]
py *args:
  {{pre}} {{_uvr}} 'python' {{args}}
alias py- := py

# 📦 uv run --module ...
[group('🐍 Python')]
py-module module *args:
  {{pre}} {{_uvr}} '--module' {{quote(module)}} {{args}}
alias pym := py-module

# 🏃 uv run python -c '...'
[group('🐍 Python')]
py-command cmd:
  {{pre}} {{_uvr}} 'python' '-c' {{quote(cmd)}}
alias pyc := py-command

# 📄 uv run --script ...
[group('🐍 Python')]
py-script script *args:
  {{pre}} {{_uvr}} '--script' {{quote(script)}} {{args}}
alias pys := py-script

# 📺 uv run --gui-script ...
[windows, group('🐍 Python')]
py-gui script *args:
  {{pre}} {{_uvr}} '--gui-script' {{quote(script)}} {{args}}
alias pyg := py-gui
# ❌ uv run --gui-script ...
[linux, macos, group('❌ Python (N/A for this OS)')]
py-gui:
  @{{quote(GREEN+'GUI scripts'+sp+_na+NORMAL)}}

#* ⚙️ Tools

# 🧪 pytest ...
[group('⚙️  Tools')]
tool-pytest *args:
  {{pre}} {{_uvr}} pytest {{args}}
alias pytest := tool-pytest

# 📖 preview docs
[group('⚙️  Tools')]
tool-docs-preview:
  {{pre}} {{_uvr}} sphinx-autobuild --show-traceback docs _site \
    {{ prepend( '--ignore', "'**/temp' '**/data' '**/apidocs' '**/*schema.json'" ) }}

# 📖 build docs
[group('⚙️  Tools')]
tool-docs-build:
  {{pre}} {{_uvr}} sphinx-build -EaT 'docs' '_site'

# 🔵 pre-commit run ...
[group('⚙️  Tools')]
tool-pre-commit *args: con
  {{pre}} {{_uvr}} pre-commit run --verbose {{args}}
alias pre-commit := tool-pre-commit
alias pc := tool-pre-commit

# 🔵 pre-commit run --all-files ...
[group('⚙️  Tools')]
tool-pre-commit-all *args:
  {{pre}} {{_just}} pre-commit --all-files {{args}}
alias pre-commit-all := tool-pre-commit-all
alias pca := tool-pre-commit-all

# ✔️  fawltydeps ...
[group('⚙️  Tools')]
tool-fawltydeps *args:
  {{pre}} {{_uvr}} fawltydeps {{args}}
alias fawltydeps := tool-fawltydeps

# ✔️  pyright
[group('⚙️  Tools')]
tool-pyright:
  {{pre}} {{_uvr}} pyright
alias pyright := tool-pyright

# ✔️  ruff check ... '.'
[group('⚙️  Tools')]
tool-ruff *args:
  {{pre}} {{_uvr}} ruff check {{args}} .
alias ruff := tool-ruff

#* 📦 Packaging

# 🛞  Build wheel, compile binary, and sign...
[group('📦 Packaging')]
pkg-build *args:
  {{pre}} {{_uvr}} {{project_name}} {{args}}
alias build := pkg-build

# ✨ Release new version
[group('📦 Packaging')]
pkg-release version:
  {{pre}} {{_copier_update}} update --vcs-ref='HEAD' --defaults --data 'project_version={{version}}'
  {{pre}} {{_uvr}} towncrier build --yes --version '{{version}}'
  {{pre}} git add --all
  {{pre}} git commit -m '{{version}}'
  {{pre}} git tag --force --sign -m {{version}} {{version}}
  {{pre}} git push
alias release := pkg-release

#* 👥 Contributor environment setup

# 👥 Update Git submodules
[group('👥 Contributor environment setup')]
con-git-submodules:
  {{pre}} Get-ChildItem '.git/modules' -Filter 'config.lock' -Recurse -Depth 1 | \
      Remove-Item
  {{pre}} git submodule update --init --merge

# 👥 Install pre-commit hooks
[group('👥 Contributor environment setup')]
con-pre-commit-hooks:
  {{pre}} if ( \
    ({{quote(hooks)}} -Split {{quote(sp)}} | \
      ForEach-Object { ".git/hooks/$_" } | \
      Test-Path \
    ) -Contains $False \
  ) { \
    {{_uvr}} pre-commit install --install-hooks | Out-Null; \
    {{quote(GREEN + 'Pre-commit hooks installed.' + NORMAL)}} \
  }
hooks :=\
  'pre-commit'

# 👥 Normalize line endings
[group('👥 Contributor environment setup')]
con-norm-line-endings:
  {{pre}} try { {{_uvr}} pre-commit run mixed-line-ending --all-files | Out-Null } \
  catch [System.Exception] {}

# 👥 Run dev task...
[group('👥 Contributor environment setup')]
con-dev *args:
  {{pre}} {{_dev}} {{args}}
alias dev := con-dev
alias d := con-dev

# 👥 Update changelog
[group('👥 Contributor environment setup')]
con-update-changelog change_type:
 {{pre}} {{_dev}} add-change {{change_type}}

# 👥 Update changelog with the latest commit's message
[group('👥 Contributor environment setup')]
con-update-changelog-latest-commit:
  {{pre}} {{_uvr}} towncrier create \
    "+$((Get-Date).ToUniversalTime().ToString('o').Replace(':','-')).change.md" \
    --content ( \
      "$(git log -1 --format='%s') ([$(git rev-parse --short HEAD)]" \
      + '(' \
        + 'https://github.com/{{project_owner_github_username}}/{{github_repo_name}}' \
        + "/commit/$(git rev-parse HEAD))" \
      + ')' \
      + "`n" \
    )

#* 📤 CI Output

# 🏷️  Set CI output to latest release
[group('📤 CI Output')]
ci-out-latest-release:
  {{pre}} Set-Content {{output_file}} "latest_release=$( \
    ($Latest = gh release list --limit 1 --json tagName | \
      ConvertFrom-Json | Select-Object -ExpandProperty 'tagName' \
    ) ? $Latest : '-1' \
  )"

# * 🧩 Templating

# ⬆️  Update from template
[group('🧩 Templating')]
templ-update:
  {{pre}} {{_update_template}} --defaults
  {{pre}} {{_handle_stale_git_status}}

# ⬆️  Update from template (prompt)
[group('🧩 Templating')]
templ-update-prompt:
  {{pre}} {{_update_template}}
  {{pre}} {{_handle_stale_git_status}}

# 🔃 Sync with current template
[group('🧩 Templating')]
templ-sync:
  {{pre}} {{_sync_template}} --defaults
  {{pre}} {{_handle_stale_git_status}}

# 🔃 Sync with current template (prompt)
[group('🧩 Templating')]
templ-sync-prompt:
  {{pre}} {{_sync_template}}
  {{pre}} {{_handle_stale_git_status}}

# ➡️  Recopy current template
[group('🧩 Templating')]
templ-recopy:
  {{pre}} {{_recopy_template}} --defaults
  {{pre}} {{_handle_stale_git_status}}

# ➡️  Recopy current template (prompt)
[group('🧩 Templating')]
templ-recopy-prompt:
  {{pre}} {{_recopy_template}}
  {{pre}} {{_handle_stale_git_status}}

_update_template :=\
  _copier_update + sp + _latest_template
_sync_template :=\
  _copier_update + sp + _current_template
_recopy_template :=\
  _copier_recopy + sp + _current_template
_handle_stale_git_status :=\
  'git add --all; git restore --staged .'
_latest_template :=\
  quote('--vcs-ref=HEAD')
_current_template :=\
  quote('--vcs-ref=' + template_ref)
_copier_recopy :=\
  _copier + sp + 'recopy'
_copier_update :=\
  _copier + sp + 'update'
_copier :=\
  _uvx + sp + quote('copier@' + copier_version)

#* 🛠️ Repository setup

# 🥾 Initialize repository
[script, group('🛠️ Repository setup')]
@repo-init:
  {{'#?'+BLUE+sp+'Source common shell config'+NORMAL}}
  {{script_pre}}
  {{'#?'+BLUE+sp+'Initialize repo and set up remote if repo is fresh'+NORMAL}}
  git init
  try { git rev-parse HEAD }
  catch [System.Exception] {
    gh repo create --public --source '.'
    (Get-Content -Raw '.copier-answers.yml') -Match '(?m)^project_description:\s(.+\n(?:\s{4}.+)*)'
    if ($Matches) {
    }
    gh repo edit --description ($Matches[1] -Replace "`n", ' ' -Replace ' {4}', '')
    $Matches = $null
    gh repo edit --homepage 'https://{{project_owner_github_username}}.github.io/{{github_repo_name}}/'
  }
  {{'#?'+BLUE+sp+'Set up repo and push'+NORMAL}}
  git submodule add --force --name 'typings' 'https://github.com/softboiler/python-type-stubs.git' 'typings'
  {{_just}} con
  git add --all
  try { git commit --no-verify -m 'Prepare template using softboiler/copier-pipeline' }
  catch [System.Exception] {}
  git push

#* 💻 Machine setup

# 👤 Set Git username and email
[group('💻 Machine setup')]
setup-git username email:
  {{pre}} git config --global user.name {{quote(username)}}
  {{pre}} git config --global user.email {{quote(email)}}

# 👤 Configure Git as recommended
[group('💻 Machine setup')]
setup-git-recs:
  {{pre}} git config --global fetch.prune true
  {{pre}} git config --global pull.rebase true
  {{pre}} git config --global push.autoSetupRemote true
  {{pre}} git config --global push.followTags true

# 🔑 Log in to GitHub API
[group('💻 Machine setup')]
setup-gh:
  {{pre}} gh auth login

# 🔓 Allow running local PowerShell scripts
[windows, group('💻 Machine setup')]
setup-scripts:
  {{pre}} Set-ExecutionPolicy -Scope 'CurrentUser' 'RemoteSigned'
# ❌ Allow running local PowerShell scripts
[linux, macos, group('❌ Machine setup (N/A for this OS)')]
setup-scripts:
  @{{quote(GREEN+'Allowing local PowerShell scripts to run'+sp+_na+NORMAL)}}
