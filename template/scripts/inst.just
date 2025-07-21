#* Variables
just_version :=\
  env('JUST_VERSION', empty)
powershell_yaml_version :=\
  env('POWERSHELL_YAML_VERSION', empty)

#* Settings
set unstable
set working-directory :=\
  '..'

#* Imports
import 'common.just'

#* Shells
set windows-shell :=\
  ['pwsh', '-NonInteractive', '-NoProfile', '-CommandWithArgs']
set shell :=\
  ['bash', '--noprofile', '--norc', '--posix', '-c']
set script-interpreter :=\
  ['bash', '--noprofile', '--norc', '--posix']

#* Shell preamble
inst_pre :=\
  if os_family()=='windows' { j + ';' } else { empty } \
  || 'set -o errexit -o nounset -o pipefail -o xtrace;'

#* Messages
installed :=\
  'already installed.'

#* Installers
just_inst :=\
  uvx + sp + '--from' + sp + quote(\
    'rust-just' + \
    if just_version==empty { empty } else { '@' + just_version } \
  ) \
  + sp + 'just' + sp + '--justfile' + sp + quote('scripts/inst.just') + sp
win_inst :=\
  inst_pre \
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
  inst_pre + sp + brew_bin + sp + 'update;' + sp + brew_bin + sp + 'install' + sp
mac_inst_cask :=\
  mac_inst + '--cask' + sp
linux_inst :=\
  linux_pre + pkg_bin + sp \
  + ( \
    if which('apt')!=empty { 'update' } else { empty } \
    || if which('dnf')!=empty { 'makecache' } else { empty } \
    || null \
  ) \
  + ';' + sp \
  + sudo + pkg_bin + sp + 'install -y' + sp
linux_inst_snap :=\
  linux_pre + snap_bin + sp + 'install' + sp
end_snap :=\
  sp + '--classic'
linux_pre :=\
  inst_pre + sp + sudo

#* Linux package managers
pkg_bin :=\
  which('apt') || which('dnf') || null
sudo :=\
  'sudo' + sp

# 🌐 [DEFAULT] Install Homebrew as needed, then install VSCode, GitHub CLI, Git, and cross-platform PowerShell
[macos,group('🌐 Install')]
all: code git gh pwsh powershell-yaml wt
# 🌐 [DEFAULT] Install Snap as needed, then install VSCode, GitHub CLI, Git, and cross-platform PowerShell
[linux, group('🌐 Install')]
all: code git gh pwsh powershell-yaml wt
# 🌐 [DEFAULT] Install VSCode, GitHub CLI, Git, Windows Terminal, and cross-platform PowerShell
[windows, group('🌐 Install')]
all: code git gh pwsh powershell-yaml wt

# 🌐 Install VSCode
[group('🌐 Install')]
code:
  @{{ if code_found==true { code_found_msg } else { empty } }}
  {{ if code_found==false { inst_code } else { empty } }}
code_found :=\
  if code_bin!=null { true } else { false }
inst_code :=\
  just_inst + 'brew snap;' + sp \
  + ( \
    if os_family()=='windows' { win_inst + quote('Microsoft.VisualStudioCode') } else { empty } \
    || if os()=='macos' { mac_inst_cask + quote('visual-studio-code') } else { empty } \
    || linux_inst_snap + quote('code') + end_snap \
  )
code_bin :=\
  which('code' + bin_ext) || which('code' + cmd_ext) || null
code_found_msg :=\
  quote(GREEN+code_name+sp+installed+NORMAL)
code_name :=\
  'VSCode'

# 🌐 Install GitHub CLI
[group('🌐 Install')]
gh:
  @{{ if gh_found==true { gh_found_msg } else { empty } }}
  {{ if gh_found==false { inst_gh } else { empty } }}
gh_found :=\
  if gh_bin!=null { true } else { false }
inst_gh :=\
  just_inst + 'brew;' + sp \
  + ( \
    if os_family()=='windows' { win_inst + quote('GitHub.cli') } else { empty } \
    || if os()=='macos' { mac_inst + 'gh' } else { empty } \
    || linux_inst + 'gh' \
  )
gh_bin :=\
  which('gh' + bin_ext) || null
gh_found_msg :=\
  quote(GREEN+gh_name+sp+installed+NORMAL)
gh_name :=\
  'GitHub CLI'

# 🌐 Install Git
[group('🌐 Install')]
git:
  @{{ if git_found==true {git_found_msg} else { empty } }}
  {{ if git_found==false {inst_git} else { empty } }}
git_found :=\
  if git_bin!=null { true } else { false }
inst_git :=\
  just_inst + 'brew;' + sp \
  + ( \
    if os_family()=='windows' { inst_pre + sp + inst_git_win } else { empty } \
    || if os()=='macos' { mac_inst + quote('git') } else { empty } \
    || linux_inst + quote('git') \
  )
git_bin :=\
  which('git' + bin_ext) || null
inst_git_win :=\
  win_inst + quote('Git.Git') + sp + '--override' + inst_git_win_overrides
#? Use Git install flags from Git for Windows repo.
#? See: https://github.com/git-for-windows/git-for-windows-automation/blob/67701cdda450b18fc4d410747f60aaa37167afe2/azure-self-hosted-runners/post-deployment-script.ps1#L189
#? Can't use New-TemporaryFile.
#? See: https://github.com/PowerShell/PowerShell/issues/14100
inst_git_win_overrides :=\
  sp \
  + dquote \
  + sp + '/CLOSEAPPLICATIONS' \
  + sp + '/NOCANCEL' \
  + sp + '/NORESTART' \
  + sp + '/RESTARTAPPLICATIONS' \
  + sp + '/SP-' \
  + sp + '/VERYSILENT' \
  + sp + '/LOADINF=$(' + inst_git_win_inf + ')' \
  + dquote
#? Modern defaults for Git installation. Must be supplied through LOADINF interface.
inst_git_win_inf :=\
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
git_found_msg :=\
  quote(GREEN+git_name+sp+installed+NORMAL)
git_name :=\
  'Git'

# 🌐 Install cross-platform PowerShell, the shell used for all non-install recipes
[group('🌐 Install')]
pwsh:
  @{{ if pwsh_found==true { pwsh_found_msg } else { empty } }}
  {{ if pwsh_found==false { inst_pwsh } else { empty } }}
pwsh_found :=\
  if pwsh_bin!=null { true } else { false }
inst_pwsh :=\
  just_inst + 'brew snap;' + sp \
  + ( \
    if os_family()=='windows' { win_inst + quote('Microsoft.PowerShell') } else { empty } \
    || if os()=='macos' { mac_inst + quote('powershell/tap/powershell') } else { empty } \
    || linux_inst_snap + quote('powershell') + end_snap \
  )
pwsh_bin :=\
  which('pwsh' + bin_ext) || null
pwsh_found_msg :=\
  quote(GREEN+pwsh_name+sp+installed+NORMAL)
pwsh_name :=\
  'Cross-platform PowerShell (pwsh)'

# 🌐 Install YAML utilities for cross-platform PowerShell
[group('🌐 Install')]
powershell-yaml:
  pwsh -Command '{{inst_powershell_yaml}}'
inst_powershell_yaml :=\
  "if (!(Get-InstalledModule -ErrorAction 'Ignore' 'powershell-yaml')) {" \
    + sp + '$InstallationPolicy = Get-PSRepository' + sp + quote('PSGallery') + sp + '|' \
    + sp + 'Select-Object -ExpandProperty' + sp + quote('InstallationPolicy') + ';' \
    + sp + 'try {' \
      + sp + 'Set-PSRepository' + sp + quote('PSGallery') \
        + sp + '-InstallationPolicy' + sp + quote('Trusted') + ';' \
      + sp + 'Install-Module' \
        + sp + '-Name' + sp + quote('powershell-yaml') \
        + sp + '-RequiredVersion' + sp + quote(powershell_yaml_version) \
    + sp + '}' \
    + if ci!=empty { 'finally {} }' } \
    else { \
      sp + 'finally {' \
      + sp + 'Set-PSRepository' + sp + quote('PSGallery') \
      + sp + '-InstallationPolicy $InstallationPolicy' \
      + sp + '} }' \
    }

# 🌐 Install Windows Terminal
[windows, group('🌐 Install')]
wt:
  @{{ if wt_found==true { wt_found_msg } else { empty } }}
  {{ if wt_found==false { inst_wt } else { empty } }}
wt_found :=\
  if wt_bin!=null { true } else { false }
inst_wt :=\
  win_inst + quote('Microsoft.WindowsTerminal')
wt_bin :=\
  which('wt.exe') || null
wt_found_msg :=\
  quote(GREEN+wt_name+sp+installed+NORMAL)
wt_name :=\
  'Windows Terminal'
# ❌ Install Windows Terminal
[linux, macos, group('❌ Install (N/A for this OS)')]
wt:
  @{{quote(GREEN+wt_name+sp+na+NORMAL)}}

# 🌐 Install Snap
[script, linux, group('🌐 Install')]
@snap:
  {{check_snap}}
  #? Request sudo up-front
  sudo -v
  #? Handle WSL-specific systemd issue
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
  #? Install snap
  if [ "$(command -v apt)" ]; then
    #? Install snap on Ubuntu-like systems
    sudo apt update
    sudo apt install -y snapd
  elif [ "$(command -v dnf)" ]; then
    #? Install snap on Fedora-like systems
    sudo dnf makecache
    sudo dnf install -y snapd
    #? Perform Fedora-specific snap setup
    sudo systemctl enable --now 'snapd.socket'
    sudo ln -s '/var/lib/snapd/snap' '/snap'
check_snap :=\
  if snap_bin!=null { 'return ' + quote(GREEN+snap_name+sp+installed+NORMAL) } else { empty }
wsl_conf_extra :=\
'''EOF
[boot]
systemd=true
EOF'''
wsl_snap_warn :=\
  quote( \
    YELLOW \
    + 'Enabled systemd in WSL. Run `wsl --shutdown` in host, restart WSL, then re-run this recipe.' \
    + installed+sp+NORMAL \
  )
snap_bin :=\
  which('snap') \
  || if path_exists('/usr/bin/snap')==true { '/usr/bin/snap' } else { empty } \
  || null
# ❌ Install Snap
[windows, macos, group('❌ Install (N/A for this OS)')]
snap:
  @{{snap_found_msg}}
snap_found_msg :=\
  quote(GREEN+brew_name+sp+installed+NORMAL)
snap_name :=\
  'Snap'

# 🌐 Install Homebrew
[macos, group('🌐 Install')]
brew:
  @{{ if brew_found==true {brew_found_msg} else { empty } }}
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
# ❌ Install Homebrew
[windows, linux, group('❌ Install (N/A for this OS)')]
brew:
  @{{brew_found_msg}}
brew_found_msg :=\
  quote(GREEN+brew_name+sp+installed+NORMAL)
brew_name :=\
  'Homebrew'
