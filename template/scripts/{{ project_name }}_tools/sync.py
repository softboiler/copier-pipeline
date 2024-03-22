"""Sync tools."""

from pathlib import Path
from platform import platform
from sys import version_info

# ! For local dev config tooling
PYRIGHTCONFIG = Path("pyrightconfig.json")
"""Resulting pyright configuration file."""
PYTEST = Path("pytest.ini")
"""Resulting pytest configuration file."""

# ! Dependencies
PYPROJECT = Path("pyproject.toml")
"""Path to `pyproject.toml`."""
REQS = Path("requirements")
"""Requirements."""
SYNC = REQS / "sync.in"
"""Core dependencies for syncing."""
DEV = REQS / "dev.in"
"""Other development tools and editable local dependencies."""
NODEPS = REQS / "nodeps.in"
"""Dependencies appended to locks without compiling their dependencies."""

# ! Platform
PLATFORM = platform(terse=True)
"""Platform identifier."""
match PLATFORM.casefold().split("-")[0]:
    case "macos":
        _runner = "macos-13"
    case "windows":
        _runner = "windows-2022"
    case "linux":
        _runner = "ubuntu-22.04"
    case _:
        raise ValueError(f"Unsupported platform: {PLATFORM}")
RUNNER = _runner
"""Runner associated with this platform."""
match version_info[:2]:
    case (3, 11):
        _python_version = "3.11"
    case (3, 12):
        _python_version = "3.12"
    case (3, 13):
        _python_version = "3.13"
    case _:
        _python_version = ".".join(str(v) for v in version_info[:2])
        raise ValueError(f"Unsupported Python version: {_python_version}")
VERSION = _python_version
"""Python version associated with this platform."""

# ! Compilation and locking
COMPS = Path(".comps")
"""Platform-specific dependency compilations."""
COMPS.mkdir(exist_ok=True, parents=True)
LOCK = Path("lock.json")
"""Locked set of dependency compilations for different runner/Python combinations."""


def get_comp_path(high: bool) -> Path:
    """Get a dependency compilation.

    Args:
        high: Highest dependencies.
    """
    return COMPS / f"{get_comp_name(high)}.txt"


def get_comp_name(high: bool) -> str:
    """Get name of a dependency compilation.

    Args:
        high: Highest dependencies.
    """
    return "_".join(["requirements", RUNNER, VERSION, *(["high"] if high else [])])
