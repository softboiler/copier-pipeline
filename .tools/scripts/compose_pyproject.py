"""Bump `pyproject.toml` with changes in `requirements.txt`."""

from pathlib import Path

import toml

PYPROJECT = Path("pyproject.toml")
SOURCE = ".tools" / PYPROJECT
DESTINATION = Path("pyproject.toml")
source = toml.loads(SOURCE.read_text(encoding="utf-8"))
DESTINATION.write_text(encoding="utf-8", data=toml.dumps(source))
