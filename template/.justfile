#* Settings
set unstable

#* Imports
import 'scripts/common.just'

#* Modules
#? ✨ Project-specific
mod proj 'scripts/proj.just'
#? 🌐 Install
mod inst 'scripts/inst.just'

#* Shells
set shell :=\
  ['pwsh', '-NonInteractive', '-NoProfile', '-CommandWithArgs']
set script-interpreter :=\
  ['pwsh', '-NonInteractive', '-NoProfile']

#* Python packages
dev :=\
  uvr + sp + quote(env("PROJECT_NAME") + '-dev')
pipeline :=\
  uvr + sp + quote(env("PROJECT_NAME") + '-pipeline')

#* Prek
prek :=\
  'prek --config prek.toml'
prek_run :=\
  prek + sp + 'run --verbose'

#* ♾️ Self

# 📃 [DEFAULT] List recipes
[group('♾️  Self')]
list:
  {{j}} --list

[group('♾️  Self')]
just *args:
  {{j}} {{args}}

#* ⛰️ Environments

# 🏃 Run shell commands with uv synced...
[group('⛰️ Environments')]
run *args: uv-sync
  @{{ if args==empty { quote(YELLOW+'No command given'+NORMAL) } else {empty} }}
  -{{ if args!=empty { j + ';' + sp + args } else {empty} }}

# 👥 Run recipes as a contributor...
[group('⛰️ Environments')]
con *args: uv-sync
  {{j}} _sync_settings_json _sync_env_yml{{ if env("PREK", empty)=='1' { \
    sp + 'con-git-submodules' \
  } else {empty} }}{{ if env("VSCODE_FOLDER_OPEN_TASK_RUNNING", empty)=='1' { \
    sp + 'con-git-submodules' + sp + 'con-prek-hooks' \
  } else {empty} }}
  {{ if args!=empty { j + sp + args } else {empty} }}

# 🤖 Run recipes in CI...
[group('⛰️ Environments')]
ci *args: uv-sync
  {{j}} _sync-ci-path-file _sync-ci-env-file; \
  {{ if args!=empty { ';' + sp + j + sp + args } else {empty} }}

# TODO: The below was needed previously for pyright, might not be needed anymore

# Add `.venv` tools to CI path. Needed for some GitHub Actions
[script, group('⛰️ Environments')]
_sync-ci-path-file:
  {{script_pre}}
  $DevCiPathFile = {{quote(env("DEV_CI_PATH_FILE"))}}
  if (!(Test-Path $DevCiPathFile)) { New-Item $DevCiPathFile | Out-Null }
  if ( !(Get-Content $DevCiPathFile | Select-String -Pattern '.venv') ) {
    $Workdir = $PWD -replace '\\', '/'
    Add-Content $DevCiPathFile ("$Workdir/.venv/bin", "$Workdir/.venv/scripts")
  }

# Write environment vars to CI environment file
[script, group('⛰️ Environments')]
_sync-ci-env-file:
  {{script_pre}}
  $DevCiEnvFile = {{quote(env("DEV_CI_ENV_FILE"))}}
  $CiEnv = Merge-Envs (('base', 'ci') | Get-Env) | Format-Env -Upper
  $CiEnvText = ''
  $CiEnv['CI_ENV_SET'] = '1'
  $CiEnv.GetEnumerator() | ForEach-Object { $CiEnvText += "$($_.Name)=$($_.Value)`n" }
  if (!(Test-Path $DevCiEnvFile)) { New-Item $DevCiEnvFile | Out-Null }
  if (!(Get-Content $DevCiEnvFile | Select-String -Pattern 'CI_ENV_SET')) {
      $CiEnvText | Add-Content -NoNewline $DevCiEnvFile
  }

# 👥 Write environment vars to temporary `.env`-like environment file
[script, group('⛰️ Environments')]
sync-contrib-env-file:
  {{script_pre}}
  $DevEnvFile = New-TemporaryFile
  $Environ = Merge-Envs (('base', 'contrib') | Get-Env) | Format-Env -Upper
  $EnvironText = ''
  $Environ.GetEnumerator() | ForEach-Object { $EnvironText += "$($_.Name)=$($_.Value)`n" }
  $EnvironText | Set-Content -NoNewline $DevEnvFile
  "$DevEnvFile"

# 📦 Run recipes in devcontainer
[script, group('⛰️ Environments')]
@devcontainer *args:
  {{script_pre}}
  {{'#?'+BLUE+sp+'Devcontainers need submodules explicitly marked as safe directories'+NORMAL}}
  $Repo = Get-ChildItem '/workspaces'
  $Packages = Get-ChildItem "$Repo/packages"
  $SafeDirs = @($Repo) + $Packages
  foreach ($Dir in $SafeDirs) {
    if (!($SafeDirs -contains $Dir)) { git config --global --add safe.directory $Dir }
  }
  {{ if args==empty { 'return' } else { '#?'+BLUE+sp+'Run recipe'+NORMAL } }}
  {{ if args==empty {empty} else { j + sp + args } }}

# Sync environment variables to '.vscode/settings.json'
[script, group('⛰️ Environments')]
_sync_settings_json:
  {{script_pre}}
  $Environ = (Merge-Envs (('base', 'contrib') | Get-Env)) | Format-Env -Upper
  $JsonEnviron = $Environ | ConvertTo-Json -Compress
  $Settings = '.vscode/settings.json'
  $SettingsContent = Get-Content $Settings -Raw
  $AnyChanged = $false
  foreach ($Plat in ('linux', 'osx', 'windows')) {
    $Pat = '(?m)"terminal\.integrated\.env\.' + $Plat + '"\s*:\s*(?<SettingsEnv>\{[^}]*\})'
    $Repl = '"terminal.integrated.env.' + $Plat + '": ' + $JsonEnviron
    if (!($SettingsContent -Match $Pat)) { continue }
    if (
      ($Matches['SettingsEnv'] | ConvertFrom-Json | ConvertTo-Json -Compress) -ne
      $JsonEnviron
    ) {
      $AnyChanged = $true
      $SettingsContent = $SettingsContent -replace $Pat, $Repl
    }
  }
  if ($AnyChanged) {
    Set-Content $Settings $SettingsContent -NoNewline
    try { {{uvr}} {{prek_run}} 'prettier' --files $Settings } catch {}
  }

# Sync environment variables to '.github/workflows/env.yml'
[script, group('⛰️ Environments')]
_sync_env_yml:
  {{script_pre}}
  $Environ = Merge-Envs (('answers', 'base') | Get-Env)
  $LimitedEnviron = [ordered]@{}
  (Limit-Env $Environ '{{ci_variables}}'.Split()).GetEnumerator() |
    ForEach-Object { $LimitedEnviron[$_.Name] = @{ value = $_.Value } }
  $LimitedEnviron = $LimitedEnviron | Format-Env -Lower
  $Workflow = '.github/workflows/env.yml'
  $WorkflowData = Get-Content $Workflow | ConvertFrom-Yaml -Ordered
  if (
    ($WorkflowData.on.workflow_call.outputs | ConvertTo-Json -Compress) -ne
    ($LimitedEnviron | ConvertTo-Json -Compress)
  ) {
    Set-Content $Workflow @'
  # Environment variables
  #! Please only update by modifying `env.json` then running `./j.ps1 con` to sync
  '@
    $WorkflowData.on.workflow_call.outputs = $LimitedEnviron
    $WorkflowData | ConvertTo-Yaml | Add-Content $Workflow -NoNewline
    try { {{uvr}} {{prek_run}} 'trailing-whitespace' --files $Workflow } catch {}
    try { {{uvr}} {{prek_run}} 'mixed-line-ending' --files $Workflow } catch {}
  }

ci_variables :=\
  'actions_runner' \
  + sp + 'project_name' \
  + sp + 'project_version' \
  + sp + 'publish_project' \
  + sp + 'uv_version'

#* 🟣 uv

# 🟣 uv ...
[group('🟣 uv')]
uv *args:
  {{pre}} {{uv}} {{args}}

# 🏃 uv run ...
[group('🟣 uv')]
uv-run *args:
  {{pre}} {{uvr}} {{args}}

# 🏃 uvx ...
[group('🟣 uv')]
uvx *args:
  {{pre}} {{uv}} {{args}}

# 🔃 uv sync ...
[group('🟣 uv')]
uv-sync *args:
  {{pre}} {{uvs}} {{args}}

# ➕ Add Python package to pyproject.toml (uv add ...)
[group('🟣 uv')]
uv-add *args:
  {{pre}} {{uva}} {{args}}

# ➖ Remove Python package from pyproject.toml (uv remove ...)
[group('🟣 uv')]
uv-remove *args:
  {{pre}} {{uvrm}} --no-sync {{args}}
  {{pre}} {{uvs}}

# ➖➕ Re-add Python package to change version in pyproject.toml
[group('🟣 uv')]
uv-re-add *args:
  {{pre}} {{uvrm}} --no-sync {{args}}
  {{pre}} {{uva}} --no-sync {{args}}
  {{pre}} {{uvs}}

#* 🐍 Python

# 🐍 python ...
[group('🐍 Python')]
py *args:
  {{pre}} {{uvr}} 'python' {{args}}

# 📦 uv run --module ...
[group('🐍 Python')]
py-module module *args:
  {{pre}} {{uvr}} '--module' {{quote(module)}} {{args}}

# 🏃 uv run python -c '...'
[group('🐍 Python')]
py-command cmd:
  {{pre}} {{uvr}} 'python' '-c' {{quote(cmd)}}

# 📄 uv run --script ...
[group('🐍 Python')]
py-script script *args:
  {{pre}} {{uvr}} '--script' {{quote(script)}} {{args}}

# 📺 uv run --gui-script ...
[windows, group('🐍 Python')]
py-gui script *args:
  {{pre}} {{uvr}} '--gui-script' {{quote(script)}} {{args}}

# ❌ uv run --gui-script ...
[linux, macos, group('❌ Python (N/A for this OS)')]
py-gui:
  @{{quote(GREEN+'GUI scripts'+sp+na+NORMAL)}}

#* ⚙️ Tools

# 🧪 pytest ...
[group('⚙️  Tools')]
tool-pytest *args:
  {{pre}} {{uvr}} pytest {{args}}

# 🧪 pytest fast (pytest -m 'not slow' ...)
[group('⚙️  Tools')]
tool-pytest-fast *args:
  {{pre}} {{uvr}} pytest -m 'not slow' {{args}}

# 📖 preview docs
[group('⚙️  Tools')]
tool-docs-preview:
  {{pre}} {{uvr}} sphinx-autobuild --show-traceback docs _site \
    {{ prepend( '--ignore', "'**/temp' '**/data' '**/apidocs' '**/*schema.json'" ) }}

# 📖 build docs
[group('⚙️  Tools')]
tool-docs-build:
  {{pre}} {{uvr}} sphinx-build -EaT 'docs' '_site'

# 🔵 prek run ...
[group('⚙️  Tools')]
tool-prek *args:
  {{pre}} {{uvr}} {{prek_run}} {{args}}

# 🔵 prek run --all-files ...
[group('⚙️  Tools')]
tool-prek-all *args:
  {{j}} tool-prek --all-files {{args}}

# ✔️  Check that the working tree is clean
[group('⚙️  Tools')]
tool-check-clean:
  {{pre}} if (git status --porcelain) { \
    throw 'Files changed when syncing contributor environment. Please commit and push changes with `./j.ps1 con`.' \
  }

# ✔️  fawltydeps ...
[group('⚙️  Tools')]
tool-fawltydeps *args:
  {{pre}} {{uvr}} fawltydeps --detailed {{args}}

# ✔️  ty
[group('⚙️  Tools')]
tool-ty *args:
  {{pre}} {{uvr}} ty check {{args}}

# ✔️  ruff check ... '.'
[group('⚙️  Tools')]
tool-ruff *args:
  {{pre}} {{uvr}} ruff check {{args}} .

#* 📦 Packaging

# 🛞  Build wheel, compile binary, and sign...
[group('📦 Packaging')]
pkg-build *args:
  {{pre}} {{uvr}} {{env("PROJECT_NAME")}} {{args}}

# 📜 Build changelog for new version
[group('📦 Packaging')]
pkg-build-changelog version:
  {{pre}} {{templ-sync}} --data 'env("PROJECT_VERSION")={{version}}'
  {{pre}} {{uvr}} towncrier build --yes --version '{{version}}'
  {{pre}} {{post_template_task}}
  -{{pre}} try { git stage 'changelog/*.md' } catch {}
  @{{quote(YELLOW+'Changelog draft built. Please finalize it, then run `./j.ps1 pkg-release`.'+NORMAL)}}

# ✨ Release the current version
[group('📦 Packaging')]
pkg-release:
  {{pre}} git add --all
  {{pre}} git commit -m '{{env("PROJECT_VERSION")}}'
  {{pre}} git tag --force --sign -m {{env("PROJECT_VERSION")}} {{env("PROJECT_VERSION")}}
  {{pre}} git push

#* 👥 Contributor environment setup

# 👥 Update Git submodules
[group('👥 Contributor environment setup')]
con-git-submodules:
  {{pre}} Get-ChildItem '.git/modules' -Filter 'config.lock' -Recurse -Depth 1 | \
      Remove-Item
  {{pre}} git submodule update --init --merge

# 👥 Install prek hooks
[group('👥 Contributor environment setup')]
con-prek-hooks:
  {{uvr}} {{prek}} install --install-hooks

# 👥 Normalize line endings
[group('👥 Contributor environment setup')]
con-norm-line-endings:
  -{{pre}} try { {{uvr}} {{prek_run}} 'mixed-line-ending' --all-files } catch {}

# 👥 Run dev task...
[group('👥 Contributor environment setup')]
con-dev *args:
  {{pre}} {{dev}} {{args}}

# 👥 Run pipeline stage...
[group('👥 Contributor environment setup')]
con-pipeline *args:
  {{pre}} {{pipeline}} {{args}}

# 👥 Update changelog...
[group('👥 Contributor environment setup')]
con-update-changelog change_type:
 {{pre}} {{dev}} add-change {{change_type}}

# 👥 Update changelog with the latest commit's message
[group('👥 Contributor environment setup')]
con-update-changelog-latest-commit:
  {{pre}} {{uvr}} towncrier create \
    "+$((Get-Date).ToUniversalTime().ToString('o').Replace(':','-')).change.md" \
    --content ( \
      "$(git log -1 --format='%s') ([$(git rev-parse --short HEAD)]" \
      + '(' \
        + 'https://github.com/{{env("PROJECT_OWNER_GITHUB_USERNAME")}}/{{env("GITHUB_REPO_NAME")}}' \
        + "/commit/$(git rev-parse HEAD))" \
      + ')' \
      + "`n" \
    )

#* 📤 CI Output

# 🏷️  Set CI output to latest release
[group('📤 CI Output')]
ci-out-latest-release:
  {{pre}} Set-Content {{env("DEV_CI_OUTPUT_FILE")}} "latest_release=$( \
    ($Latest = gh release list --limit 1 --json tagName | \
      ConvertFrom-Json | Select-Object -ExpandProperty 'tagName' \
    ) ? $Latest : '-1' \
  )"

#* 🧩 Templating

# ⬆️  Update from template
[group('🧩 Templating')]
templ-update:
  {{pre}} {{update_template}} --defaults
  {{pre}} {{post_template_task}}

# ⬆️  Update from template (prompt)
[group('🧩 Templating')]
templ-update-prompt:
  {{pre}} {{update_template}}
  {{pre}} {{post_template_task}}

# 🔃 Sync with current template
[group('🧩 Templating')]
templ-sync:
  {{pre}} {{templ-sync}}
  {{pre}} {{post_template_task}}
templ-sync :=\
  sync_template + sp + '--defaults'

# 🔃 Sync with current template (prompt)
[group('🧩 Templating')]
templ-sync-prompt:
  {{pre}} {{sync_template}}
  {{pre}} {{post_template_task}}

# ➡️  Recopy current template
[group('🧩 Templating')]
templ-recopy:
  {{pre}} {{recopy_template}} --defaults
  {{pre}} {{post_template_task}}

# ➡️  Recopy current template (prompt)
[group('🧩 Templating')]
templ-recopy-prompt:
  {{pre}} {{recopy_template}}
  {{pre}} {{post_template_task}}

update_template :=\
  copier_update + sp + latest_template
sync_template :=\
  copier_update + sp + current_template
recopy_template :=\
  copier_recopy + sp + current_template
post_template_task :=\
  'git add --all; git reset;' + sp + j + sp + 'con'
latest_template :=\
  quote('--vcs-ref=HEAD')
current_template :=\
  quote('--vcs-ref=' + env("TEMPLATE_COMMIT"))
copier_recopy :=\
  copier + sp + 'recopy'
copier_update :=\
  copier + sp + 'update'
copier :=\
  uvx + sp + quote('copier@' + env("COPIER_VERSION"))

#* 🛠️ Repository setup

# 🥾 Initialize repository
[group('🛠️ Repository setup')]
repo-init:
  {{j}} _repo-init-set-up-remote

# Initialize repo and set up remote if repo is fresh
[script, group('🛠️ Repository setup')]
_repo-init-set-up-remote:
  {{script_pre}}
  git init
  try { git rev-parse HEAD } catch {
    gh repo create --public --source '.'
    (Get-Content -Raw '.copier-answers.yml') -Match '(?m)^project_description:\s(.+\n(?:\s{4}.+)*)'
    if ($Matches) {
    }
    gh repo edit --description ($Matches[1] -Replace "`n", ' ' -Replace ' {4}', '')
    $Matches = $null
    gh repo edit --homepage 'https://{{env("PROJECT_OWNER_GITHUB_USERNAME")}}.github.io/{{env("GITHUB_REPO_NAME")}}/'
  }

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
  @{{quote(GREEN+'Allowing local PowerShell scripts to run'+sp+na+NORMAL)}}
