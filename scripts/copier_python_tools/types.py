"""Types."""

from typing import Literal, TypeAlias, TypedDict

Platform: TypeAlias = Literal["linux", "macos", "windows"]
"""Platform."""
PythonVersion: TypeAlias = Literal["3.9", "3.10", "3.11", "3.12"]
"""Python version."""
Lock: TypeAlias = dict[
    str, dict[str, str | bool | tuple[str, ...] | dict[str, dict[str, str]]]
]
"""Lockfile."""
SubmoduleInfoKind = Literal["paths", "urls"]
"""Submodule info kind."""
Op = Literal[" @ ", "=="]
"""Allowable operator."""
ops: tuple[Op, ...] = (" @ ", "==")
"""Allowable operators."""
ChangeType: TypeAlias = Literal["breaking", "deprecation", "change"]
"""Type of change to add to changelog."""


class Dep(TypedDict):
    """Dependency specification."""

    op: Op
    """Operator."""
    rev: str
    """Revision."""


class Meta(TypedDict):
    """Metadata."""

    time: str
    uv: str
    project_platform: Platform
    project_python_version: PythonVersion
    no_deps: bool
    high: bool
    paths: tuple[str, ...]
    overrides: str
    directs: dict[str, Dep]
    requirements: str


class SpecificLock(TypedDict):
    """Lock for a given platform and Python version."""

    time: str
    requirements: str
