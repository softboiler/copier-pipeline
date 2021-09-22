"""Bump `pyproject.toml` with changes in `tooling/requirements_pyproject.txt`"""

import toml
from pathlib import Path

REQUIREMENTS = Path("requirements.txt")
PYPROJECT = Path("pyproject.toml")

with open(REQUIREMENTS) as file:
    dependencies = [line.rstrip() for line in file]

with open(PYPROJECT) as file:
    content = toml.load(file)
    content["project"]["dependencies"] = dependencies

with open(PYPROJECT, "w") as file:
    toml.dump(content, file)
