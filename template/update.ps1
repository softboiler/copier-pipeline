<#.SYNOPSIS
Update the local virtual environment to the latest tracked dependencies.
#>

# * -------------------------------------------------------------------------------- * #
# * Changes below may be lost in significant template updates.

# Activate environment
$VENV_ACTIVATE_WINDOWS = '.venv/Scripts/activate'
$VENV_ACTIVATE_UNIX = '.venv/bin/Activate.ps1'
if ( Test-Path $VENV_ACTIVATE_WINDOWS ) { . $VENV_ACTIVATE_WINDOWS }
elseif ( Test-Path $VENV_ACTIVATE_UNIX ) { . $VENV_ACTIVATE_UNIX }
else {
    throw [System.Management.Automation.ItemNotFoundException] 'Could not find a virtual environment.'
}

# Install dev requirements
python -m pip install --upgrade pip # Instructed to do this by pip
pip install --upgrade setuptools wheel # Must be done separately from above
pip install --upgrade --requirement '.tools/requirements/requirements_dev.txt'
# Need `toml` in dev requirements prior to bumping `pyproject.toml`
python '.tools/scripts/compose_pyproject.py'

# Install the package and the lower bound of its requirements
pip install --no-deps --editable '.'
pip install --upgrade --requirement 'requirements.txt'

# Install all types of pre-commit hooks
$h = '--hook-type'
$AllHookTypes = @(
    $h, 'commit-msg'
    $h, 'post-checkout'
    $h, 'post-commit'
    $h, 'post-merge'
    $h, 'post-rewrite'
    $h, 'pre-commit'
    $h, 'pre-merge-commit'
    $h, 'pre-push'
    $h, 'pre-push'
    $h, 'prepare-commit-msg'
)
pre-commit install --install-hooks @AllHookTypes

# Ensure type stubs are synchronized
git submodule update --init --merge typings

# * -------------------------------------------------------------------------------- * #
# * Changes below should persist in significant template updates.
