"""Types."""

from typing import Literal, TypeAlias

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
