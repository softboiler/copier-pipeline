git add -A
git commit -m "Prepare template using blakeNaccarato/copier-python"
git submodule add https://github.com/blakeNaccarato/copier-python.git template
git submodule add https://github.com/blakeNaccarato/pylance-stubs-unofficial.git typings
git add -A
git commit -m "Add template and type stub submodules"
git submodule deinit --all
& ./setup.ps1
git add -A
git commit -m "Initialize template using blakeNaccarato/copier-python"
