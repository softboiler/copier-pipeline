"""Bump `pyproject.toml` with changes in `requirements.txt`."""

from pathlib import Path

import toml

REQUIREMENTS = Path("requirements.txt")
PYPROJECT = Path("pyproject.toml")

with Path(REQUIREMENTS).open() as file:
    dependencies = [
        line.rstrip().replace("==", ">=")
        for line in file
        if line != "\n" and not line.startswith("#")
    ]

with Path(PYPROJECT).open() as file:
    content = toml.load(file)
    content["project"]["dependencies"] = dependencies

with Path(PYPROJECT).open("w") as file:
    toml.dump(content, file)
