# * Settings
set unstable
set working-directory :=\
  '..'

# * Imports
import 'common.just'

# * Shells
set windows-shell :=\
  ['pwsh', '-NonInteractive', '-NoProfile', '-CommandWithArgs']
set shell :=\
  ['bash', '--noprofile', '--norc', '--posix', '-c']
set script-interpreter :=\
  ['bash', '--noprofile', '--norc', '--posix']

# * Reusable shell preamble
pre :=\
  if os_family()=='windows' { pwsh_pre + ';' } else { empty } \
  || 'set -o errexit -o nounset -o pipefail -o xtrace;'

# * Messages
_installed :=\
  'already installed.'

# * Installers
_just_inst :=\
  _just + sp + '--justfile' + sp + quote('scripts/inst.just') + sp
win_inst :=\
  pre \
  + sp + 'winget install' \
  + sp + '--accept-package-agreements' \
  + sp + '--accept-source-agreements' \
  + sp + '--disable-interactivity' \
  + sp + '--exact' \
  + sp + '--no-upgrade' \
  + sp + '--silent' \
  + sp + '--source' + sp + quote('winget') \
  + sp + '--id '
mac_inst :=\
  pre + sp + brew_bin + sp + 'update;' + sp + brew_bin + sp + 'install' + sp
mac_inst_cask :=\
  mac_inst + '--cask' + sp
linux_inst :=\
  _linux_pre + pkg_bin + sp \
  + ( \
    if which('apt')!=empty { 'update' } else { empty } \
    || if which('dnf')!=empty { 'makecache' } else { empty } \
    || null \
  ) \
  + ';' + sp \
  + sudo + pkg_bin + sp + 'install -y' + sp
linux_inst_snap :=\
  _linux_pre + snap_bin + sp + 'install' + sp
end_snap :=\
  sp + '--classic'
_linux_pre :=\
  pre + sp + sudo

# * Linux package managers
pkg_bin :=\
  which('apt') || which('dnf') || null
sudo :=\
  'sudo' + sp

# 🌐 [DEFAULT] Install Homebrew as needed, then install VSCode, GitHub CLI, Git, and cross-platform PowerShell.
[macos,group('🌐 Install')]
all: code git gh pwsh wt
# 🌐 [DEFAULT] Install Snap as needed, then install VSCode, GitHub CLI, Git, and cross-platform PowerShell.
[linux, group('🌐 Install')]
all: code git gh pwsh wt
# 🌐 [DEFAULT] Install VSCode, GitHub CLI, Git, Windows Terminal, and cross-platform PowerShell.
[windows, group('🌐 Install')]
all: code git gh pwsh wt

# 🌐 Install VSCode.
[group('🌐 Install')]
code:
  @{{ if code_found==true { _code_found_msg } else { empty } }}
  {{ if code_found==false { inst_code } else { empty } }}
code_found :=\
  if code_bin!=null { true } else { false }
inst_code :=\
  _just_inst + 'brew snap;' + sp \
  + ( \
    if os_family()=='windows' { win_inst + quote('Microsoft.VisualStudioCode') } else { empty } \
    || if os()=='macos' { mac_inst_cask + quote('visual-studio-code') } else { empty } \
    || linux_inst_snap + quote('code') + end_snap \
  )
code_bin :=\
  which('code' + bin_ext) || which('code' + cmd_ext) || null
_code_found_msg :=\
  quote(GREEN+_code_name+sp+_installed+NORMAL)
_code_name :=\
  'VSCode'

# 🌐 Install GitHub CLI.
[group('🌐 Install')]
gh:
  @{{ if gh_found==true { _gh_found_msg } else { empty } }}
  {{ if gh_found==false { inst_gh } else { empty } }}
gh_found :=\
  if gh_bin!=null { true } else { false }
inst_gh :=\
  _just_inst + 'brew;' + sp \
  + ( \
    if os_family()=='windows' { win_inst + quote('GitHub.cli') } else { empty } \
    || if os()=='macos' { mac_inst + 'gh' } else { empty } \
    || linux_inst + 'gh' \
  )
gh_bin :=\
  which('gh' + bin_ext) || null
_gh_found_msg :=\
  quote(GREEN+_gh_name+sp+_installed+NORMAL)
_gh_name :=\
  'GitHub CLI'

# 🌐 Install Git.
[group('🌐 Install')]
git:
  @{{ if git_found==true {_git_found_msg} else { empty } }}
  {{ if git_found==false {inst_git} else { empty } }}
git_found :=\
  if git_bin!=null { true } else { false }
inst_git :=\
  _just_inst + 'brew;' + sp \
  + ( \
    if os_family()=='windows' { pre + sp + inst_git_win } else { empty } \
    || if os()=='macos' { mac_inst + quote('git') } else { empty } \
    || linux_inst + quote('git') \
  )
git_bin :=\
  which('git' + bin_ext) || null
inst_git_win :=\
  win_inst + quote('Git.Git') + sp + '--override' + _inst_git_win_overrides
# ? Use Git install flags from Git for Windows repo.
# ? See: https://github.com/git-for-windows/git-for-windows-automation/blob/67701cdda450b18fc4d410747f60aaa37167afe2/azure-self-hosted-runners/post-deployment-script.ps1#L189
# ? Can't use New-TemporaryFile.
# ? See: https://github.com/PowerShell/PowerShell/issues/14100
_inst_git_win_overrides :=\
  sp \
  + dquote \
  + sp + '/CLOSEAPPLICATIONS' \
  + sp + '/NOCANCEL' \
  + sp + '/NORESTART' \
  + sp + '/RESTARTAPPLICATIONS' \
  + sp + '/SP-' \
  + sp + '/VERYSILENT' \
  + sp + '/LOADINF=$(' + _inst_git_win_inf + ')' \
  + dquote
# ? Modern defaults for Git installation. Must be supplied through LOADINF interface.
_inst_git_win_inf :=\
'''@'
[Setup]
Components=gitlfs,windowsterminal,scalar
Tasks=
EditorOption=VisualStudioCode
DefaultBranchOption=main
PathOption=Cmd
SSHOption=ExternalOpenSSH
BashTerminalOption=ConHost
'@ |
  Set-Content ( $Path = [System.IO.Path]::GetTempFilename() )
$Path
'''
_git_found_msg :=\
  quote(GREEN+_git_name+sp+_installed+NORMAL)
_git_name :=\
  'Git'

# 🌐 Install cross-platform PowerShell, the shell used for all non-install recipes.
[group('🌐 Install')]
pwsh:
  @{{ if pwsh_found==true { _pwsh_found_msg } else { empty } }}
  {{ if pwsh_found==false { inst_pwsh } else { empty } }}
pwsh_found :=\
  if pwsh_bin!=null { true } else { false }
inst_pwsh :=\
  _just_inst + 'brew snap;' + sp \
  + ( \
    if os_family()=='windows' { win_inst + quote('Microsoft.PowerShell') } else { empty } \
    || if os()=='macos' { mac_inst + quote('powershell/tap/powershell') } else { empty } \
    || linux_inst_snap + quote('powershell') + end_snap \
  )
pwsh_bin :=\
  which('pwsh' + bin_ext) || null
_pwsh_found_msg :=\
  quote(GREEN+_pwsh_name+sp+_installed+NORMAL)
_pwsh_name :=\
  'Cross-platform PowerShell (pwsh)'

# 🌐 Install a project version of uv if you've got global uv
[group('🌐 Install')]
uv:
  @{{ if uv_found==true { _uv_found_msg } else { empty } }}
  {{ if uv_found==false { inst_uv } else { empty } }}
inst_uv :=\
  if os_family()=='windows' { inst_uv_win } else { empty } \
  || inst_uv_unix
uv_found :=\
  if uv_bin!=null { true } else { false }
uv_bin :=\
  if path_exists('./uv' + bin_ext)==true { './uv' + bin_ext } else { empty } \
  || null
_uv_bin :=\
  './uv' + bin_ext
inst_uv_win :=\
  pre + sp + 'Invoke-RestMethod' + sp + _inst_uv_script + sp + '| Invoke-Expression'
inst_uv_unix :=\
  pre + sp + "curl --proto '=https' --tlsv1.2 -LsSf" + sp + _inst_uv_script
_inst_uv_script :=\
  quote('https://astral.sh/uv/' + uv_version + '/install' + sh_ext)
_uv_found_msg :=\
  quote(GREEN+_uv_name+sp+_installed+NORMAL)
_uv_name :=\
  'uv'

# 🌐 Install Windows Terminal.
[windows, group('🌐 Install')]
wt:
  @{{ if wt_found==true { _wt_found_msg } else { empty } }}
  {{ if wt_found==false { inst_wt } else { empty } }}
wt_found :=\
  if wt_bin!=null { true } else { false }
inst_wt :=\
  win_inst + quote('Microsoft.WindowsTerminal')
wt_bin :=\
  which('wt.exe') || null
_wt_found_msg :=\
  quote(GREEN+_wt_name+sp+_installed+NORMAL)
_wt_name :=\
  'Windows Terminal'
# ❌ Install Windows Terminal.
[linux, macos, group('❌ Install (N/A for this OS)')]
wt:
  @{{quote(GREEN+_wt_name+sp+_na+NORMAL)}}

# 🌐 Install Snap.
[script, linux, group('🌐 Install')]
@snap:
  {{check_snap}}
  # ? Request sudo up-front
  sudo -v
  # ? Handle WSL-specific systemd issue
  if \
    grep -iq 'microsoft' '/proc/version' \
    && (
      -f '/etc/wsl.conf' && grep -q 'systemd=true' '/etc/wsl.conf' \
      || ! -f '/etc/wsl.conf'
    )
  then
    sudo tee -a '/etc/wsl.conf' > '/dev/null' << {{wsl_conf_extra}}
    return {{ wsl_snap_warn }}
  fi
  # ? Install snap
  if [ "$(command -v apt)" ]; then
    # ? Install snap on Ubuntu-like systems
    sudo apt update
    sudo apt install -y snapd
  elif [ "$(command -v dnf)" ]; then
    # ? Install snap on Fedora-like systems
    sudo dnf makecache
    sudo dnf install -y snapd
    # ? Perform Fedora-specific snap setup
    sudo systemctl enable --now 'snapd.socket'
    sudo ln -s '/var/lib/snapd/snap' '/snap'
check_snap :=\
  if snap_bin!=null { 'return ' + quote(GREEN+snap_name+sp+_installed+NORMAL) } else { empty }
wsl_conf_extra :=\
'''EOF
[boot]
systemd=true
EOF'''
wsl_snap_warn :=\
  quote( \
    YELLOW \
    + 'Enabled systemd in WSL. Run `wsl --shutdown` in host, restart WSL, then re-run this recipe.' \
    + _installed+sp+NORMAL \
  )
snap_bin :=\
  which('snap') \
  || if path_exists('/usr/bin/snap')==true { '/usr/bin/snap' } else { empty } \
  || null
# ❌ Install Snap.
[windows, macos, group('❌ Install (N/A for this OS)')]
snap:
  @{{_snap_found_msg}}
_snap_found_msg :=\
  quote(GREEN+_brew_name+sp+_installed+NORMAL)
snap_name :=\
  'Snap'

# 🌐 Install Homebrew.
[macos, group('🌐 Install')]
brew:
  @{{ if brew_found==true {_brew_found_msg} else { empty } }}
  {{ if brew_found==false {inst_brew} else { empty } }}
brew_found :=\
  if brew_bin!=null { true } else { false }
inst_brew :=\
  'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
brew_bin :=\
  which('brew') \
  || if path_exists('/usr/local/bin/brew')==true { '/usr/local/bin/brew' } else { empty } \
  || if path_exists('/opt/homebrew/bin/brew')==true { '/opt/homebrew/bin/brew' } else { empty } \
  || null
# ❌ Install Homebrew.
[windows, linux, group('❌ Install (N/A for this OS)')]
brew:
  @{{_brew_found_msg}}
_brew_found_msg :=\
  quote(GREEN+_brew_name+sp+_installed+NORMAL)
_brew_name :=\
  'Homebrew'
