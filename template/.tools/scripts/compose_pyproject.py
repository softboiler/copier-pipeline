"""Bump `pyproject.toml` and `pre-commit.config` with dependency changes."""

from pathlib import Path

import re
from pathlib import Path

import toml

# Bump `pyproject.toml` based on changes in `requirements.txt`
dependencies = [
    line.rstrip().replace("==", ">=")
    for line in Path("requirements.txt").read_text(encoding="utf-8").splitlines()
    if line and not line.startswith("#")
]
source = toml.loads((".tools" / Path("pyproject.toml")).read_text(encoding="utf-8"))
source["project"]["dependencies"] = dependencies
Path("pyproject.toml").write_text(encoding="utf-8", data=toml.dumps(source))
