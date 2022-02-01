# copier-python

Copier template for Python projects.

## Installing

This Copier template contains all the tooling for my projects. Use `pipx` to be able to access Copier from the command line.

```Shell
py -m pip install pipx
py -m pipx ensurepath
py -m pipx install copier==6.0.0a9
```

Once you have `copier` available at the command line, run the following in a clean (no unstaged changes) git-tracked folder to copy this template over to your project. You will be asked a brief series of questions, then the templated files will be copied over.

```Shell
copier gh:blakeNaccarato/copier-python .
```

If you already had a `.gitignore` in your project prior to copying this template, you may want to manually replace its contents with the contents of [template/.gitignore](https://raw.githubusercontent.com/blakeNaccarato/copier-python/main/template/.gitignore.jinja). This makes sure that tooling configurations are not checked into the project. This template does not overwrite your `.gitignore` if it already exists because you may have customized your `.gitignore` beyond the default Python `.gitignore`.
