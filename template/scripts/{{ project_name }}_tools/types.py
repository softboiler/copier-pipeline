"""Types."""

from typing import Literal, TypeAlias, TypedDict

PythonVersion: TypeAlias = Literal["3.9", "3.10", "3.11", "3.12"]
"""Python version."""
SubmoduleInfoKind = Literal["paths", "urls"]
"""Submodule info kind."""
Op = Literal[" @ ", "=="]
"""Allowable operator."""
ops: tuple[Op, ...] = (" @ ", "==")
"""Allowable operators."""
ChangeType: TypeAlias = Literal["breaking", "deprecation", "change"]
"""Type of change to add to changelog."""


class Dep(TypedDict):
    """Dependency."""

    op: Op
    """Operator."""
    rev: str
    """Revision."""
