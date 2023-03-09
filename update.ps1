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

# Ensure pre-commit hooks are applied and updated
pre-commit install --install-hooks

# * -------------------------------------------------------------------------------- * #
# * Changes below should persist in significant template updates.
