# copier-python

The tooling for this repo is managed in a Copier template, separately from this repo. This facilitates duplication and updating of tooling across projects. Use `pipx` to be able to access Copier from the command line.

```Shell
py -m pip install pipx
py -m pipx ensurepath
py -m pipx install git+https://github.com/blakeNaccarato/copier.git@v6.0.0a7patch
```

## Note

The reason that we are installing from a wheel is that `copier-6.0.0a7-py3-none-any.whl` was "patched" by modifying a line in "copier-6.0.0a7-py3-none-any.whl\copier-6.0.0a7.dist-info\METADATA" to read as below. This sidesteps an issue with building one of Copier's dependencies on Windows.

```Text
Requires-Dist: iteration_utilities (>=0.11.0,<0.12.0)
```
