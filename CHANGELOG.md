<!--
Do *NOT* add changelog entries here!

This changelog is managed by towncrier and is compiled at release time.

See https://github.com/python-attrs/attrs/blob/main/.github/CONTRIBUTING.md#changelog for details.
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Calendar Versioning](https://calver.org/). The **first number** of the version is the year. The **second number** is incremented with each release, starting at 1 for each year. The **third number** is for emergencies when we need to start branches for older releases, or for very minor changes.

<!-- towncrier release notes start -->

## [2024.1.1](https://github.com/blakeNaccarato/copier-python/tree/2024.1.1)

### Changes

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
