"""Sync tools."""

from datetime import UTC, datetime
from json import dumps, loads
from pathlib import Path
from platform import platform
from re import finditer, search
from shlex import quote, split
from subprocess import run
from sys import version_info
from typing import NamedTuple

from ruamel.yaml import YAML

from copier_python_tools.types import Platform, Version

# ! Dependencies
COPIER_ANSWERS = Path(".copier-answers.yml")
"""Copier answers file."""
PYTHON_VERSIONS = Path(".python-versions")
"""File containing supported Python versions."""
REQS = Path("requirements")
"""Requirements."""
UV = REQS / "uv.in"
"""UV requirement."""
DEV = REQS / "dev.in"
"""Other development tools and editable local dependencies."""
NODEPS = REQS / "nodeps.in"
"""Dependencies appended to locks without compiling their dependencies."""
OVERRIDE = REQS / "override.txt"
"""Overrides to satisfy otherwise incompatible combinations."""

# ! Template answers
ANS = YAML().load(COPIER_ANSWERS.read_text(encoding="utf-8"))
"""Project template answers."""
AUTHORS = ANS["project_owner_name"]
"""Authors of the project."""
USER = ANS["project_owner_github_username"]
"""Host GitHub user or organization for this repository."""
REPO = ANS["github_repo_name"]
"""GitHub repository name."""
PACKAGE = ANS["project_name"]
"""Package name."""
VERSION = ANS["project_version"]
"""Package version."""

# ! Platforms and Python versions
PLATFORM: Platform = platform(terse=True).casefold().split("-")[0]  # pyright: ignore[reportAssignmentType] 1.1.356
"""Platform identifier."""
VERSION: Version = ".".join([str(v) for v in version_info[:2]])  # pyright: ignore[reportAssignmentType] 1.1.356
"""Python version associated with this platform."""
PLATFORMS: tuple[Platform, ...] = ("linux", "macos", "windows")
"""Supported platforms."""
VERSIONS: tuple[Version, ...] = (  # pyright: ignore[reportAssignmentType] 1.1.356
    tuple(PYTHON_VERSIONS.read_text("utf-8").splitlines())
    if PYTHON_VERSIONS.exists()
    else ("3.9", "3.10", "3.11", "3.12")
)
"""Supported Python versions."""

# ! Compilation and locking
COMPS = Path(".comps")
"""Platform-specific dependency compilations."""
LOCK = Path("lock.json")
"""Locked set of dependency compilations for different runner/Python combinations."""
LOCK_CONTENTS = loads(LOCK.read_text("utf-8")) if LOCK.exists() else {}
"""Contents of the lock file."""

# ! Checking
UV_PAT = r"(?m)^# uv\s(?P<version>.+)$"
"""Pattern for stored `uv` version comment."""
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


def synchronize() -> tuple[Comp, ...]:
    """Sync dependencies. Prefer the existing compilation if compatible."""
    old = get_comps()
    if not old.low:
        return lock()  # Old compilation missing
    if (old_uv := search(UV_PAT, old.low)) and old_uv["version"] != get_uv_version():
        return lock()  # Older `uv` version last used to compile
    directs = comp(high=False, no_deps=True)
    try:
        subs = dict(
            zip(finditer(SUB_PAT, old.low), finditer(SUB_PAT, directs), strict=False)
        )
    except ValueError:
        return lock()  # Submodule missing
    if any(old_sub.groups() != new_sub.groups() for old_sub, new_sub in subs.items()):
        return lock()  # Submodule pinned commit SHA mismatch
    old_directs: list[str] = []
    for direct in finditer(DEP_PAT, directs):
        pat = rf"(?mi)^(?P<name>{direct['name']})==(?P<ver>.+$)"
        if match := search(pat, old.low):
            old_directs.append(match.group())
            continue
        return lock()  # Direct dependency missing
    low = comp(high=False, no_deps=False)
    return lock() if any(d not in low for d in old_directs) else get_all_comps()


def lock() -> tuple[Comp, ...]:
    """Lock dependencies for all platforms and Python versions."""
    LOCK.write_text(
        encoding="utf-8",
        data=dumps(
            indent=2,
            sort_keys=True,
            obj={
                **LOCK_CONTENTS,
                **{
                    get_comp_key(comp.stem): comp.read_text("utf-8")
                    for comp in COMPS.iterdir()
                },
            },
        )
        + "\n",
    )
    return tuple(
        recompile(platform, version) for platform in PLATFORMS for version in VERSIONS
    )


def recompile(platform: Platform = PLATFORM, version: Version = VERSION) -> Comp:
    """Recompile dependencies.

    Parameters
    ----------
    platform
        Platform to compile for.
    version
        Python version to compile for.
    """
    return Comp(
        comp(high=False, no_deps=False, platform=platform, version=version),
        comp(high=True, no_deps=False, platform=platform, version=version),
    )


def get_all_comps() -> tuple[Comp, ...]:
    """Get all existing dependency compilations."""
    return tuple(
        get_comps(platform, version) for platform in PLATFORMS for version in VERSIONS
    )


def get_comps(platform: Platform = PLATFORM, version: Version = VERSION) -> Comp:
    """Get existing dependency compilations.

    Parameters
    ----------
    platform
        Platform to compile for.
    version
        Python version to compile for.
    """
    if not LOCK.exists():
        return Comp("", "")
    return Comp(*[
        LOCK_CONTENTS.get(get_comp_key(name)) or ""
        for name in get_comp_names(platform, version)
    ])


def get_comp_key(name: str) -> str:
    """Get the key to a dependency compilation in the lock.

    Parameters
    ----------
    name
        Name of the dependency compilation.
    """
    return name.removeprefix("requirements_")


def get_all_comp_names() -> tuple[Comp, ...]:
    """Get all compilation names."""
    return tuple(
        get_comp_names(platform, version)
        for platform in PLATFORMS
        for version in VERSIONS
    )


def get_comp_names(platform: Platform = PLATFORM, version: Version = VERSION) -> Comp:
    """Get names of a dependency compilation.

    Parameters
    ----------
    platform
        Platform to compile for.
    version
        Python version to compile for.
    """
    sep = "_"
    base = sep.join(["requirements", platform, version])
    return Comp(base, sep.join([base, "high"]))


def comp(
    high: bool, no_deps: bool, platform: Platform = PLATFORM, version: Version = VERSION
) -> str:
    """Compile system dependencies.

    Parameters
    ----------
    high
        Highest dependencies.
    no_deps
        Without transitive dependencies.
    platform
        Platform to compile for.
    version
        Python version to compile for.
    """
    sep = " "
    result = run(
        args=split(
            sep.join([
                "bin/uv pip compile",
                f"--exclude-newer {datetime.now(UTC).isoformat().replace('+00:00', 'Z')}",
                f"--python-platform {platform} --python-version {version}",
                f"--resolution {'highest' if high else 'lowest-direct'}",
                f"--override {escape(OVERRIDE)}",
                f"--all-extras {'--no-deps' if no_deps else ''}",
                *[
                    escape(path)
                    for path in [
                        DEV,
                        *[
                            Path(editable["path"]) / "pyproject.toml"
                            for editable in finditer(
                                r"(?m)^(?:-e|--editable)\s(?P<path>.+)$",
                                DEV.read_text("utf-8"),
                            )
                        ],
                    ]
                ],
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
            f"# uv {get_uv_version()}",
            *[f"# {sub} {rev}" for sub, rev in submodules.items()],
            *[line.strip() for line in deps.splitlines()],
            *[line.strip() for line in NODEPS.read_text("utf-8").splitlines()],
        ])
        + "\n"
    )


def get_uv_version() -> str:
    """Get the installed version of `uv`."""
    result = run(args="bin/uv --version", capture_output=True, check=False, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout.split(" ")[1]


def escape(path: str | Path) -> str:
    """Path escape suitable for all operating systems.

    Parameters
    ----------
    path
        Path to escape.
    """
    return quote(Path(path).as_posix())
