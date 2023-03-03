<#.SYNOPSIS
Update the local virtual environment to the latest tracked dependencies.
#>

$VENV_ACTIVATE_WINDOWS = '.venv/Scripts/activate'
$VENV_ACTIVATE_UNIX = '.venv/bin/Activate.ps1'
if ( Test-Path $VENV_ACTIVATE_WINDOWS ) { . $VENV_ACTIVATE_WINDOWS }
elseif ( Test-Path $VENV_ACTIVATE_UNIX ) { . $VENV_ACTIVATE_UNIX }
else {
throw [System.Management.Automation.ItemNotFoundException] 'Could not find a virtual environment.'
}
python -m pip install --upgrade pip # instructed to do this by pip
pip install --upgrade setuptools wheel # must be done separately from above
pip install --upgrade -r 'requirements.txt' -r '.tools/requirements/requirements_dev.txt'
python '.tools/scripts/bump_pyproject.py'
pip install --no-deps --editable '.'
pre-commit install --install-hooks
