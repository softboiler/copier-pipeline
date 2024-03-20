# copier-python

This is a Copier template for Python projects, allowing for template evolution over time and sharing across projects. It is strongly recommended you follow [dev machine setup](#dev-machine-setup) before following steps for [generating a project from this template](#generate-a-project-from-this-template). In short, you should have Git, VSCode, Copier, Python, and the cross-platform PowerShell (with profile configurations to activate `.env` variables), installed to get the most use out of this template.

## Features

This template should set up tooling that will help you as you code. Contributor and CI workflows in this template are tested on Windows 2022, MacOS 13, and Ubuntu 22.04 runners. Static analysis "moves errors to the left", allowing you to catch issues as soon as possible. Linting and code checks run as you write to catch problems before you run/publish/package your code. Features include:

- [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)/`pyright`: Code refactoring tools, allowing you to move/rename functions and variables around your project, effortlessly refactoring code as your project grows in complexity. Also performs type-checking which will keep you honest if you're using type annotations. But you don't have to use type annotations out of the gate, consier delaying that learning journey until you get the basics down.
- [Sourcery](https://sourcery.ai/): Teaches "Pythonic" behavior as you learn to code, encouraging cleaner ways of writing things.
- [MyST-NB](https://myst-nb.readthedocs.io/en/latest/): Documentation in Markdown, supporting Jupyter notebooks, instead of rST. Having a docs page at project inception should encourage documentation as you go. Don't be afraid to publish incomplete pages, early adopters will appreciate the breadcrumbs. Use docs to help explain the "why" of things.
- `pytest`: Write tests for your code in `tests` that ensure certain functionality works the way you say it does. The more robust your tests, the easier it is to make sweeping changes to your code.
- `pre-commit`: Enforces the above standards at commit time. If you must, skip the check with `git commit --no-verify`, but try to keep `pre-commit` happy and you will be happier in the long run.
- `ruff`: Formats code, enforces code style and best practices. Don't be afraid to suppress Ruff messages if you find them truly inappropriate for your use case, but consider the advice before suppressing messages.

## Account-enhanced features

Projects generated from this template have some features that require certain GitHub apps to be set up. They are not strictly necessary, but bolster code style, Git operations, reproducibility and test coverage efforts:

- [Sourcery](https://sourcery.ai/): Sourcery does a great job of teaching valuable Python lessons as you code. It will suggest alternative wording for given code patterns, gently guiding you towards more "Pythonic" code.
- [GitLens](https://www.gitkraken.com/gitlens): Installed along with recommended extensions. You may be prompted to create an account, which you can just link to your GitHub account if desired. This extension is indispensable for managing git-versioned projects.
- [pre-commit.ci](https://pre-commit.ci/): The GitHub organization/user hosting this project needs `pre-commit.ci` enabled to leverage automatic running of `pre-commit` hooks online. This is not strictly necessary, but encouraged as a way to help keep your code in good shape as you write it.
- [Codecov](https://about.codecov.io/): The GitHub organization/user hosting this project needs this app to check code coverage. A provider for determining test coverage in your CI. Tests are an important part of modern software. This template allows you to write tests when you are ready, but will not penalize you for not using tests early on, though you should configure Codecov for your GitHub user or organization so CI runs properly.
- [Renovate](https://github.com/marketplace/renovate): This tool manages your dependencies automatically. When writing code, it is sensible to pin all of the packages you depend on to exact or minimum versions, and periodically bump those versions when you are certain it won't break your project. Using CI tools and tests, as well as local testing, will increase your confidence in being able to safely upgrade.

## Dev machine setup

These requirements should only need to be installed once on a given machine. Until I unify the documentation, see this [in-depth setup guide](https://github.com/blakeNaccarato/gist-template#in-depth-setup-guide) for details, including an [`Initialize-WindowsDev.ps1`](https://github.com/blakeNaccarato/gist-template#initialize-windowsdevps1) script that magically does all of this for you on Windows (via [`winget`](https://learn.microsoft.com/en-us/windows/package-manager/winget/). Also, make sure you set up a [GitHub](https://github.com/) account. Parts of this template assume you are hosting your project on GitHub. This template sets up GitHub Actions for you, a continuous integration (CI) tool that checks code for correctness, publishes documentation, and more.

- [Git](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup): Git allows for version control of your code and is required for versioning your code with GitHub, and using this template.
- [VSCode](https://code.visualstudio.com/docs/setup/setup-overview): This template focuses on custom configuration and extensions in VSCode to speed up the development process.
- [Copier](https://copier.readthedocs.io/en/stable/#installation): This allows the template to evolve alongside your project(s), and be updated periodically. This is necessary for generating new projects from the template, but will come along with the virtual environment of existing projects using this template.
- [Cross-platform PowerShell](https://github.com/PowerShell/PowerShell#get-powershell): PowerShell is no longer Windows-only. Automations in this template are written for PowerShell, and should run on any platform.
- Python
  - Windows: Install Python from <https://www.python.org/downloads/> rather than the Windows Store! This gives you the Python launcher, invoked with `py`, and facilitates multiple Python versions being installed.
  - MacOS: Install Python from <https://www.python.org/downloads/>. If you encounter issues using this template on Mac, consider filing an [issue](https://github.com/blakeNaccarato/copier-python/issues) and I will update the scripts.
  - Other UNIX-like systems: I recommend you install Python from the [deadsnakes](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa) team. This allows you to install a later Python with all of its extras, e.g. `sudo apt install python3.11 python3.11-dev python3.11-venv python3.11-distutils python3.11-tk`. Make sure you at least install `python#.##-venv` for your chosen Python.
- [Set-PsEnv](https://www.powershellgallery.com/packages/Set-PsEnv/0.0.5): This allows environment variables specified in `.env` files to be loaded into the PowerShell session. This is necessary in this template for various tasks, since VSCode [doesn't handle environment variables very well](https://github.com/microsoft/vscode-python/issues/944).
- Run `code $PROFILE` in a `pwsh` (PowerShell) terminal window. This opens your PowerShell profile in VSCode for editing. Modify it to contain the following:

```PowerShell
function Set-Env {
    <#.SYNOPSIS
    Load environment variables from `.env`, activate virtual environments.
    #>
    Set-PsEnv
    $VENV_ACTIVATE_WINDOWS = '.venv/Scripts/activate'
    $VENV_ACTIVATE_UNIX = '.venv/bin/Activate.ps1'
    if ( Test-Path $VENV_ACTIVATE_WINDOWS ) { . $VENV_ACTIVATE_WINDOWS }
    elseif ( Test-Path $VENV_ACTIVATE_UNIX ) { . $VENV_ACTIVATE_UNIX }
}
Set-Env
```

## Generate a project from this template

Generating a project from this template involves creating a local folder, initializing the project, and publishing the repository on GitHub.

- Create a new project folder, for instance `example`.
- Open that folder in VSCode with `File: Open Folder`.
- Click "Initialize Repository" in the Source Control tab in the sidebar, or run `git init`.
- Run `copier copy gh:blakeNaccarato/copier-python .` and answer the questions.
- Run `.tools/scripts/Initialize_Repo.ps1`. You can inspect the [setup script](https://github.com/blakeNaccarato/copier-python/blob/main/template/.tools/scripts/Initialize-Repo.ps1) if you like. It does the following:
  - Adds a `template` submodule for later updating.
  - Adds a `typings` submodule to synchronize `pyright` in GitHub Actions with Pylance.
  - Sets up a Python virtual environment specific to this project. This may take a little while.
- Restart VSCode to refresh the "Source Control" sidebar, removing duplicate buttons/submodules which have already been deinitialized. This can be done easily with the "Developer: Reload Window" command.
- There should be only one button in the "Source Control" sidebar now, indicating "Publish Branch". Press that button.
- When prompted, select the option "Publish to GitHub public repository". The repository will adopt the same name as the folder. Some features of this template require the repository to be public, which will not work in case of "private" publishing.
- VSCode will also prompt you to install recommended extensions at some point (usually on startup). Accept this prompt.

The templated project is now published on GitHub. The project owner will have to set a few more options in the GitHub repository settings to enable documentation and GitHub Actions workflows to work.

## Final GitHub repository setup

Visit the newly-published GitHub repository, navigate to repository "Settings", and configure the following:

- In "Actions > General" settings, set "Workflow permissions" (the last set of options) to "Read and write permissions". This will be necessary when using this template until the workflows have their permissions explicitly scoped in a future update.
- In "Pages" settings, select "GitHub Actions" as the "Source" for "Build and deployment". This template should automatically publish a project documentation website for you when you change `docs`, `README.md`, and `CHANGELOG.md`.
- Navigate back to your GitHub project, click the cog next to "About", and tick the box for "Use your GitHub Pages website" to direct users to your generated documentation. The page will be broken until the first time the `sphinx.yml` action runs on detected changes to documentation files. Also manually enter a "Description" and other info here if you like.

## Roadmap

There is a lot still to do in this template, but the big one is the concept of "meta-templating". The saying that "one size fits all" doesn't hold in project templating. Rather, "many sizes fit most". I encourage you to fork this template and change the relevant links in your fork to take ownership of the template and modify it for your own needs.

I intend to set up a meta-templating solution over in [copyit](https://github.com/copyit-org) to automate this, facilitating the forking of templates from templates, to allow anyone to maintain their own template, periodically updating from whatever parent template they chose. This pattern allows individuals or teams to benefit from the templates of others, without being constrained by the opinionated choices of that template.

Other notable to-dos:

- [ ] Cut a release to signal template stability. Since using it for my own projects, I have mainly updated to `HEAD` of the template, but releases are known stable points and are better for forking.
- [x] Ground-up script to handle "one-time setup" across platforms. (Implemented in `scripts/Sync-Py.ps1`)
- [x] Detailed documentation
- [ ] More detailed documentation
- [x] Explicitly set permissions across workflows to account for [the newly read-only by default GITHUB_TOKEN](https://github.blog/changelog/2023-02-02-github-actions-updating-the-default-github_token-permissions-to-read-only/) since February 2, 2023.
- [ ] Test this template with the strict `GITHUB_TOKEN` defaults
- [ ] Facilitate propagation of individual project changes back to the shared template through scheduled PRs. Planned in [copyit](https://github.com/copyit-org).

## Alternatives

This template uses [Copier](https://readthedocs.org/projects/copier/) to do the heavy lifting. An alternative Copier template I came across recently is [pawamoy/copier-uv](https://github.com/pawamoy/copier-uv), which also uses `uv` like this template, and is slimmer in scope and approach. My template grew out of a need to ensure reproducibility for research code and facilitates "multi-repo" workflows, which is good for research code that incorporates lots of dependencies and acts as a "leaf" in the tree that is the Python ecosystem. To that end, my template features unique full-dependency-chain locking for every combination of operating system and Python version, a useful signal of research code reproducibility.

[Pawamoy's template](https://github.com/pawamoy/copier-uv) is a good choice for library development, where you are intentionally limiting your dependencies, and working on being a "branch" in the tree that is the Python ecosystem. There is no locking, but `uv` compiles and installs dependencies all the same. See their [copier-pdm](https://github.com/pawamoy/copier-pdm) also for some locking capabilities.

See [this comparison of Copier to other project generators](https://copier.readthedocs.io/en/stable/comparisons/) to get an idea as to why you would use a Copier-based template over something like [Cookiecutter](https://github.com/cookiecutter/cookiecutter) or [Yeoman](https://yeoman.io/). See also, [PyScaffold](https://pyscaffold.org/en/stable/). In summary, Copier facilitates template evolution and periodic project updating from the template, rather than a one-time scaffold for your project. This encourages continual updating of the template to suit your project needs.
