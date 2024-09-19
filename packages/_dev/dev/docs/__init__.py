"""Documentation tools."""

import os
from pathlib import Path

DOCS = Path("docs")
"""Docs directory."""
PYPROJECT = Path("pyproject.toml")
"""Path to `pyproject.toml`."""
CHECKS = [DOCS, PYPROJECT]
"""Checks for the root directory."""


def chdir_docs() -> Path:
    """Ensure we are in the `docs` directory and return the root directory."""
    root = get_root()
    os.chdir(root / "docs")
    return root


def get_root() -> Path:
    """Get the project root directory."""
    path = Path().cwd()
    while not all((path / check).exists() for check in CHECKS):
        if path == (path := path.parent):
            raise RuntimeError("Either documentation or `pyproject.toml` is missing.")
    return path
