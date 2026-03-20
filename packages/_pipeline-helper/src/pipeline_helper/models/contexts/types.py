"""Types."""

from pathlib import Path
from typing import Literal, TypeAlias

Kind: TypeAlias = Literal["Path", "DataFile", "DocsDir"]
"""File or directory kind."""
Kinds: TypeAlias = dict[Path, Kind]
"""Paths and their kinds."""
