python -m pip install --upgrade pip
pip install --upgrade setuptools wheel
pip install --requirement .tools/requirements/requirements_cicd.txt
pip install --no-deps .
pip install --upgrade --requirement 'requirements.txt'
