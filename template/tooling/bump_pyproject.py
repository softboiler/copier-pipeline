"""Bump `pyproject.toml` with changes in `requirements.txt`"""

import toml
from pathlib import Path

REQUIREMENTS = Path("requirements.txt")
PYPROJECT = Path("pyproject.toml")

with open(REQUIREMENTS) as file:
    dependencies = [line.rstrip() for line in file if not line.startswith("#")]

with open(PYPROJECT) as file:
    content = toml.load(file)
    content["project"]["dependencies"] = dependencies

with open(PYPROJECT, "w") as file:
    toml.dump(content, file)
