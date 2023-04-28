# copier-python

Copier template for Python projects.

## Overview

- Create a new folder, for instance `example`
- Open the folder in VSCode with `File: Open Folder`
- Click "Initialize Repository" in the Source Control tab in the sidebar
- Run `copier gh:blakeNaccarato/copier-python-init .` and answer the questions
- Run `./first_time_setup.ps1`
- Make the first commit, e.g `git commit -m 'Generate project from template'`
- Publish to GitHub, either

## Usage

It is still heavily tuned for my use-case, but the principles in practice there
See my example/sandbox repository copier-python-test, which has been created from my template. See boilercv for this template applied to an actual project of mine (there are more examples besides this one).
I encourage a philosophy of "one size does not fit all", or "many sizes fit most". You may find my template doesn't meet your lab's needs exactly, but by forking and modifying parts of it, you can roll your own template with modifications from my own.
Requirements for my template as-is:Cross-platform PowerShell: The template features scripted setup/installation/update of a virtual environment, as well as scripted management of `pyproject.toml` in various `*.ps1` scripts. This is cross-platform, scripts should run on Windows and Linux (`setup.ps1` attempts to detect flavor of OS by looking at the venv file structure, for instance).VSCode: The template has a `.vscode` folder with useful settings, debug configurations, and most importantly, recommended extensions, and most importantly, tasks. Consider binding the command "Tasks: Run task" as lots of user automation is handled this way. Alternatives: grunt, gulp, jake, etc.
