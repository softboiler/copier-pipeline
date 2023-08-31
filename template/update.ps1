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

# Install dev requirements.
python -m pip install --requirement '.tools/requirements/requirements_core.txt'
python .tools/scripts/core_update.py
python -m pip install --upgrade --requirement '.tools/requirements/requirements_dev.txt' --requirement '.tools/requirements/requirements.txt'
python -m pip install --no-deps --requirement '.tools/requirements/requirements_nodeps.txt' --editable '.'

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

# * -------------------------------------------------------------------------------- * #
# * Changes below should persist in significant template updates.
