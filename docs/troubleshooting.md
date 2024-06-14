# Troubleshooting

## Issues committing in WSL

May need to look into some of this:

- <https://github.com/microsoft/vscode-remote-release/issues/6838>
- <https://code.visualstudio.com/docs/setup/windows#_working-with-unc-paths>

See `WSL: Reopen Folder in WSL`, `WSL: Reopen Folder in Windows`, and possibly setting `"security.allowedUNCHosts": ["wsl.localhost"]` in WSL machine's `settings.json`.

When selecting the box for "Permanently allow host 'wsl.localhost'" in the dialog shown in {numref}`wsl-localhost-warning`, the setting is added to the host machine's `settings.json` file (e.g. on the Windows side). But this setting only works in the WSL machine's `settings.json`, and may not even participate in the commit issue on WSL.

```{figure} _static/wsl-localhost-warning.png
:name: wsl-localhost-warning
:alt: System dialog triggered by VSCode, warning 'The host 'wsl.localhost' was not found in the list of allowed hosts. Do you want to allow it anyway?" It suggests that the project path uses a host that is not allowed.
VSCode warning dialog about `wsl.localhost` issue
```

Maybe the `pre-commit` packages were just taking a long time to initialize, I'm not sure.
