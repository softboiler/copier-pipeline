<#.SYNOPSIS
Initialize Windows machine.#>

$origPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
# Common winget options
$Install = @(
    'install',
    '--accept-package-agreements',
    '--accept-source-agreements',
    '--disable-interactivity'
    '--exact',
    '--no-upgrade',
    '--silent',
    '--source=winget'
)
# Install Python
winget @Install --id='Python.Python.3.11' --override='/quiet PrependPath=0'
# Install VSCode
winget @Install --id='Microsoft.VisualStudioCode'
# Install Windows Terminal
winget @Install --id='Microsoft.WindowsTerminal'
# Install GitHub CLI
winget @Install --id='GitHub.cli'
# Install git
@'
[Setup]
Lang=default
Dir=C:/Program Files/Git
Group=Git
NoIcons=0
SetupType=default
Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,autoupdate,windowsterminal,scalar
Tasks=
EditorOption=VisualStudioCode
CustomEditorPath=
DefaultBranchOption=main
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=OpenSSL
CRLFOption=CRLFAlways
BashTerminalOption=MinTTY
GitPullBehaviorOption=Merge
UseCredentialManager=Enabled
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Disabled
EnablePseudoConsoleSupport=Disabled
EnableFSMonitor=Enabled
'@ | Out-File ($inf = New-TemporaryFile)
winget @Install --id='Git.Git' --override="/SILENT /LOADINF=$inf"
$ErrorActionPreference = $origPreference
