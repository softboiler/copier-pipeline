<!--
Please don't add changelog entries here. This changelog is managed by towncrier and is compiled at release time. Edits to existing changelog entries associated with already released versions are okay.

See https://github.com/python-attrs/attrs/blob/main/.github/CONTRIBUTING.md#changelog for details.
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Calendar Versioning](https://calver.org/). The **first number** of the version is the year. The **second number** is incremented with each release of the year. The **third number** is for very minor changes or for emergencies when we need to start branches for older releases.

<!-- towncrier release notes start -->

## [2025.1.3](https://github.com/softboiler/copier-pipeline/tree/2025.1.3)

- Retire the hacky "custom" lockfile approach and stabilize around now standardized `uv.lock`
- Migrate to `packages` and `uv` workspaces layout
- Introduce `pipeline` workflow package in preparation for migrating reproducible research pipelines from PhD work
- Improve setup for first-timers, new machines, fresh repos, implemented as `just` recipes
- Synchronize environment variables in a few places, unifying contrib/CI config by choosing the lesser of two evils, compared with a truly "single source of truth"
- The above facilitated minimizing directly templated files (e.g. `template/**/*.jinja` files), reducing diffs on template updates
- Install and use `uv` locally with a project-specific version instead of hijacking global uv and forcing it to a certain version
- Funnel almost all useful actions through the `just` command runner via e.g. `./j.ps1 <recipe> <args> ...`
- Retire PowerShell scripts except for `./j.ps1` and `scripts/pre.ps1` which thinly wrap `just` invocations and handle the few things `just` cannot do (or cannot do neatly)
- Base most of CI on these `just` recipes, allowing local testing and debugging of CI actions. Only the potentially sensitive release workflow is "hard-coded" in the workflow file
- Implement artifact attestation and PyPI publishing via OIDC in release workflows
- After a few false starts (see the latest flurry of releases), implement release workflow that requires normal CI to pass, optionally publishes to PyPI, and updates release notes
- Derive the optional VSCode layer's Tasks from the `just` recipes, and generally make the template more VSCode-optional
- Modernize Renovate dependency management configuration, by default make it less noisy
- Try generating CI environment workflow and separating changelog drafting from releasing ([75edd78](https://github.com/softboiler/copier-pipeline/commit/75edd78e299915e3faec08172df70e9ade8d009e))
- Unify behavior of Pyright (or optional Pylance) locally and in CI without resorting to a platform-specific local extension approach

## [2025.1.2](https://github.com/softboiler/copier-pipeline/tree/2025.1.2)

Released while attempting to stabilize the release workflow, maintained here only to match the immutable Zenodo-tracked release record. Significant changes documented in `2025.1.3` above.

## [2025.1.1](https://github.com/softboiler/copier-pipeline/tree/2025.1.1)

Released while attempting to stabilize the release workflow, maintained here only to match the immutable Zenodo-tracked release record. Significant changes documented in `2025.1.3` above.

## [2025.1.0](https://github.com/softboiler/copier-pipeline/tree/2025.1.0)

Released while attempting to stabilize the release workflow, maintained here only to match the immutable Zenodo-tracked release record. Significant changes documented in `2025.1.3` above.

## [2024.2.0](https://github.com/softboiler/copier-pipeline/tree/2024.2.0)

This release stabilizes the core mechanics of the template, including environment setup and synchronization, CI/CD workflows, documentation and tests, and more. The template now wraps `uv run` in `./dev.ps1` as `Invoke-Uv`, aliased to `iuv`, which keeps environment variables and hooks in sync in addition to the syncing done by `uv` itself.

- Restructure template as a modern `uv` project with workspace layout and lockfiles
- Add TOML and Prettier formatting to `prek`
- Introduce `Invoke-Uv.ps1` and `iuv` alias which wraps `uv run`, but also syncs submodules, environment variables, ensures prek hooks are installed
- Have `Invoke-Uv.ps1` also work correctly in CI, invoking `--locked` and `--frozen` when appropriate and generating artifacts for inspecting the packages installed in CI runs
- Transition Renovate dependency management to maintain PEP 621 requirements in `pyproject.toml` by automatically re-locking with `uv`
- Simplify CI pipelines, don't commit during them, allowing this template to function in repos where `main` has push protection
- Leverage `uv`'s Python executable management to avoid having to install it
- Finalize the complete machine setup scripts for Windows, Linux, and MacOS
- Fix Codecov integration ([#437](https://github.com/softboiler/copier-pipeline/issues/437))
- Elevate Pyright warnings to errors in CI ([37d079c5](https://github.com/blakeNaccarato/copier-python/commit/37d079c52e8cdcefcef40dc780d70cf46b85d8e4))
- Generate appropriate coverage report format for Codecov ([c22b475b](https://github.com/blakeNaccarato/copier-python/commit/c22b475b7d43af82d80aa230c3607c2607d8a256))
- Handle locked submodule configs ([75d4cb02](https://github.com/blakeNaccarato/copier-python/commit/75d4cb02a7c158396579067e280a4069c2f48df9))
- Only run coverage in task and CI, not in VSCode test runner (Fixes #447) ([bb19a367](https://github.com/blakeNaccarato/copier-python/commit/bb19a3679b3023716032ea54468344beb8171379))
- Remove Pylance bundled stubs instead of synchronizing `submodules/typings` ([8579ca8c](https://github.com/blakeNaccarato/copier-python/commit/8579ca8c9211549dd0cbb04863952f002d604c5b))
- Require docs build to pass before updating lock (Fixes #445) ([1d78af44](https://github.com/blakeNaccarato/copier-python/commit/1d78af443a55ba0cae080ed95b004a9086980e13))
- Run winget more safely and facilitate commit-pinned changelog entries.
- Require `exact` and `winget` source, and run winget silently for safter Windows machine initialization.
- Add task for timestamped ad-hoc/orphan changelog entries. [34dede3f](https://github.com/blakeNaccarato/copier-python/commit/34dede3f6726fac7f0ea450b1a37a32acc708103)
- Single-source Pylance version ([5e878127](https://github.com/blakeNaccarato/copier-python/commit/5e878127462d24d818a8d42bf05d5b726a880b14))

## [2024.1.1](https://github.com/blakeNaccarato/copier-python/tree/2024.1.1)

- Make first release
- Actually compare directs ([#397](https://github.com/blakeNaccarato/copier-python/issues/397))
- Specify automation profile ([#406](https://github.com/blakeNaccarato/copier-python/issues/406))
- Fix splatting in Windows install script in contributing guide ([#413](https://github.com/blakeNaccarato/copier-python/issues/413))
- Fix `sync.py` for `lock.json` existing but empty ([#415](https://github.com/blakeNaccarato/copier-python/issues/415))
- Fix `powershell` invocation for paths containing spaces ([#416](https://github.com/blakeNaccarato/copier-python/issues/416))
- Produce an output `requirements.txt` with all requirements ([#417](https://github.com/blakeNaccarato/copier-python/issues/417))
- Mitigate CVE-2024-37891 by setting `urllib3>=2.2.2` ([#421](https://github.com/blakeNaccarato/copier-python/issues/421))
- Add changelog entry step to contribution flow ([#423](https://github.com/blakeNaccarato/copier-python/issues/423))
- Added towncrier
- Fix `changerelease` workflow and reduce duplication
