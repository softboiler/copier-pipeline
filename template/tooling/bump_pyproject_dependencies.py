import toml
from pathlib import Path

REQUIREMENTS = Path("tooling/requirements.txt")
with open(REQUIREMENTS) as file:
    DEPENDENCIES = [line.rstrip() for line in file]

PYPROJECT = Path("pyproject.toml")
with open(PYPROJECT) as file:
    content = toml.load(file)
    content["project"]["dependencies"] = DEPENDENCIES

with open(PYPROJECT, "w") as file:
    toml.dump(content, file)
