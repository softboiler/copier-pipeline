# copier-python

Copier template for Python projects.

## Installing

This Copier template contains all the tooling for my projects. Use `pipx` to be able to access Copier from the command line.

```Shell
py -m pip install pipx
py -m pipx ensurepath
py -m pipx install copier
```

Once you have `copier` available at the command line, run the following in a clean (no unstaged changes) git-tracked folder to copy this template over to your project. You will be asked a brief series of questions, then the templated files will be copied over.

```Shell
copier gh:blakeNaccarato/copier-python .
```
