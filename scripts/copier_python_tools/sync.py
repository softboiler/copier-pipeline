"""Sync tools."""

from datetime import UTC, datetime
from json import dumps, loads
from pathlib import Path
from platform import platform
from re import finditer, search
from shlex import quote, split
from subprocess import run
from sys import executable, version_info
from typing import NamedTuple

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
        _python_version = "3.13.0-alpha.5"
    case _:
        _python_version = ".".join(str(v) for v in version_info[:2])
        raise ValueError(f"Unsupported Python version: {_python_version}")
VERSION = _python_version
"""Python version associated with this platform."""

# ! Compilation and locking
COMPS = Path(".comps")
"""Platform-specific dependency compilations."""
LOCK = Path("lock.json")
"""Locked set of dependency compilations for different runner/Python combinations."""

# ! Checking
SUB_PAT = r"(?m)^# submodules/(?P<name>[^\s]+)\s(?P<rev>[^\s]+)$"
"""Pattern for stored submodule revision comments."""
DEP_PAT = r"(?mi)^(?P<name>[A-Z0-9]|[A-Z0-9][A-Z0-9._-]*[A-Z0-9])==.+$"
"""Pattern for compiled dependencies.

See: https://packaging.python.org/en/latest/specifications/name-normalization/#name-format
"""


class Comp(NamedTuple):
    """Dependency compilation."""

    low: str
    """Name of lowest direct dependency compilation or the compilation itself."""
    high: str
    """Name of highest dependency compilation or the compilation itself."""


def lock() -> Path:
    """Lock all local dependency compilations."""
    LOCK.write_text(
        encoding="utf-8",
        data=dumps(
            indent=2,
            sort_keys=True,
            obj={
                **(loads(LOCK.read_text("utf-8")) if LOCK.exists() else {}),
                **{
                    get_comp_key(comp.stem): comp.read_text("utf-8")
                    for comp in COMPS.iterdir()
                },
            },
        )
        + "\n",
    )
    return LOCK


def compile() -> Comp:  # noqa: A001
    """Compile dependencies. Prefer the existing compilation if compatible."""
    old = get_comps()
    if not old.low:
        return recomp()
    directs = comp(high=False, no_deps=True)
    try:
        subs = dict(
            zip(finditer(SUB_PAT, old.low), finditer(SUB_PAT, directs), strict=False)
        )
    except ValueError:
        return recomp()
    if any(old_sub.groups() != new_sub.groups() for old_sub, new_sub in subs.items()):
        return recomp()
    old_directs: list[str] = []
    for direct in finditer(DEP_PAT, directs):
        pat = rf"(?mi)^(?P<name>{direct['name']})==(?P<ver>.+$)"
        if match := search(pat, old.low):
            old_directs.append(match.group())
            continue
        return recomp()
    new = recomp()
    return old if all(direct in new.low for direct in old_directs) else new


def recomp() -> Comp:
    """Recompile system dependencies."""
    return Comp(comp(high=False, no_deps=False), comp(high=True, no_deps=False))


def get_comps() -> Comp:
    """Get existing dependency compilations."""
    if not LOCK.exists():
        return Comp("", "")
    return Comp(*[
        loads(LOCK.read_text("utf-8")).get(get_comp_key(name)) or ""
        for name in get_comp_names()
    ])


def get_comp_key(name: str) -> str:
    """Get the key to a dependency compilation in the lock."""
    return name.removeprefix("requirements_")


def get_comp_names() -> Comp:
    """Get names of a dependency compilation."""
    sep = "_"
    base = sep.join(["requirements", RUNNER, VERSION])
    return Comp(base, sep.join([base, "high"]))


def comp(high: bool, no_deps: bool) -> str:
    """Compile system dependencies.

    Args:
        high: Highest dependencies.
        no_deps: Without transitive dependencies.
    """
    sep = " "
    result = run(
        args=split(
            sep.join([
                f"{escape(executable)} -m uv",
                f"pip compile --python-version {VERSION}",
                f"--resolution {'highest' if high else 'lowest-direct'}",
                f"--exclude-newer {datetime.now(UTC).isoformat().replace('+00:00', 'Z')}",
                f"--all-extras {'--no-deps' if no_deps else ''}",
                sep.join([escape(path) for path in [PYPROJECT, DEV, SYNC]]),
            ])
        ),
        capture_output=True,
        check=False,
        text=True,
    )
    if result.returncode:
        raise RuntimeError(result.stderr)
    deps = result.stdout
    submodules = {
        sub.group(): run(
            split(f"git rev-parse HEAD:{sub.group()}"),  # noqa: S603
            capture_output=True,
            check=True,
            text=True,
        ).stdout.strip()
        for sub in finditer(r"submodules/.+\b", DEV.read_text("utf-8"))
    }
    return (
        "\n".join([
            *[f"# {sub} {rev}" for sub, rev in submodules.items()],
            *[line.strip() for line in deps.splitlines()],
            *[line.strip() for line in NODEPS.read_text("utf-8").splitlines()],
        ])
        + "\n"
    )


def escape(path: str | Path) -> str:
    """Path escape suitable for all operating systems."""
    return quote(Path(path).as_posix())
