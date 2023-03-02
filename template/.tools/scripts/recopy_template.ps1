git submodule update --init --remote --merge template
git add -A
git commit -m "Update template digest to $(git rev-parse HEAD:template)"
git submodule deinit --all
copier gh:blakeNaccarato/copier-python .
