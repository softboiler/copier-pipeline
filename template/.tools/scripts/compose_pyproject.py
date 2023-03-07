"""Bump `pyproject.toml` with changes in `requirements.txt`."""

from pathlib import Path

import toml

PYPROJECT = Path("pyproject.toml")
REQUIREMENTS = Path("requirements.txt")
SOURCE = ".tools" / PYPROJECT
DESTINATION = Path("pyproject.toml")
requirements = REQUIREMENTS.read_text(encoding="utf-8").splitlines()
dependencies = [
    line.rstrip().replace("==", ">=")
    for line in requirements
    if line != "\n" and not line.startswith("#")
]
source = toml.loads(SOURCE.read_text(encoding="utf-8"))
source["project"]["dependencies"] = dependencies
DESTINATION.write_text(encoding="utf-8", data=toml.dumps(source))
