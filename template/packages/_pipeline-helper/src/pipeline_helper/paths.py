"""Paths and modules."""

from collections.abc import Iterable
from contextlib import closing
from dataclasses import dataclass
from datetime import datetime
from importlib.machinery import ModuleSpec
from os import walk
from pathlib import Path
from re import NOFLAG, VERBOSE, Match, compile  # noqa: A004
from shlex import quote
from string import Template
from types import ModuleType

from dulwich.porcelain import status, submodule_list
from dulwich.repo import Repo


def get_package_dir(package: ModuleType) -> Path:
    """Get the directory of a package given the top-level module."""
    return Path(package.__spec__.submodule_search_locations[0])  # type: ignore


def get_module_name(module: ModuleType | ModuleSpec | Path | str) -> str:
    """Get an unqualified module name.

    Example: `get_module_name(__spec__ or __file__)`.
    """
    if isinstance(module, ModuleType | ModuleSpec):
        return get_qualified_module_name(module).split(".")[-1]
    path = Path(module)
    return path.parent.name if path.stem in ("__init__", "__main__") else path.stem


def get_qualified_module_name(module: ModuleType | ModuleSpec) -> str:  # type: ignore
    """Get a fully-qualified module name.

    Example: `get_module_name(__spec__ or __file__)`.
    """
    if isinstance(module, ModuleType):
        module: ModuleSpec = module.__spec__  # type: ignore
    return module.name


def dt_fromisolike(match: Match[str], century: int | str = 20) -> datetime:
    """Get datetime like ISO 8601 but with flexible delimeters and missing century."""
    m: dict[str, str] = {
        **{grp: val or "00" for grp, val in match.groupdict().items()},
        **{grp: match.group(grp) for grp in ("century", "tz", "sym")},
    }
    tz = m["tz"] or ""
    if tz and tz.casefold() != "z":
        tz = (
            f"{m['sym']}{m['tz_hour']}:{m['tz_minute']}:{m['tz_second']}"
            f".{m['tz_fraction']}"
        )
    return datetime.fromisoformat(
        Template("$year-$month-${day}T$hour:$minute:$second.$fraction$tz").substitute(
            year=f"{m['century'] or str(century)}{m['decade']}",
            tz=tz,
            **{
                name: m[name]
                for name in ["month", "day", "hour", "minute", "second", "fraction"]
            },
        )
    )


GROUP = Template(r"(?P<$name>\d{$n})")
SUBSTITUTIONS = {
    "D": r"[^TtZz+\d]",  # A valid digit delimeter is not T, Z, +, or a digit
    **{
        # Fractional seconds have at least one digit
        name: GROUP.substitute(name=name, n="1,")
        for name in ["fraction", "tz_fraction"]
    },
    **{
        # All other groups have exactly two digits
        name: GROUP.substitute(name=name, n="2")
        for name in [
            "century",
            "decade",
            "month",
            "day",
            "hour",
            "minute",
            "second",
            "tz_hour",
            "tz_minute",
            "tz_second",
        ]
    },
}
ISOLIKE_PATTERN = Template(
    r"""
        $century?$decade  # Century is optional
        $D$month
        $D$day
        (?:  # Time is optional
            [Tt]
            $hour  # Only the hour is required
            (?:$D$minute)?
            (?:$D$second)?
            (?:$D$fraction)?
            (?P<tz>  # Timezone information is optional
                [Zz]  # It can be Z or z
                |(?:  # Or it can be a delta
                    (?P<sym>[\+-])$tz_hour  # Only the delta hour is required
                    (?:$D$tz_minute)?
                    (?:$D$tz_second)?
                    (?:$D$tz_fraction)?
                )
            )?
        )?
    """
).substitute(SUBSTITUTIONS)
ISOLIKE = compile(flags=VERBOSE, pattern=ISOLIKE_PATTERN)

DEFAULT_SUFFIXES = [".py"]


def map_stages(package: Path, suffixes=DEFAULT_SUFFIXES) -> dict[str, Path]:
    """Map stage module names to their paths."""
    modules: dict[str, Path] = {}
    for path in walk_module_paths(package, suffixes):
        module = get_module_rel(
            get_qualified_module_name_from_paths(path, package), package.name
        )
        if module == ".":
            continue
        modules[module.replace(".", "_")] = path
    return modules


def get_module_rel(module: str, relative: str) -> str:
    """Get module name relative to another module."""
    if relative not in module:
        raise ValueError(f"{module} not relative to {relative}.")
    return (
        "."
        if module == relative
        else compile(rf"^.*{relative}\.").sub(repl="", string=module)
    )


def walk_modules(
    package: Path, suffixes: list[str] = DEFAULT_SUFFIXES
) -> Iterable[str]:
    """Walk modules from a given submodule path and the top level library directory."""
    for module, _ in walk_module_map(package, suffixes=suffixes):
        yield module


def walk_module_map(
    package: Path, suffixes: list[str] = DEFAULT_SUFFIXES
) -> Iterable[tuple[str, Path]]:
    """Walk the map of modules to their paths."""
    for module in walk_module_paths(package, suffixes=suffixes):
        yield get_qualified_module_name_from_paths(module, package), module


def get_qualified_module_name_from_paths(module: Path, package: Path) -> str:
    """Get the qualified name of a module file relative to a package file."""
    module = module.parent if module.stem in ("__init__", "__main__") else module
    return (
        str(module.relative_to(package.parent).with_suffix(""))
        .replace("\\", ".")
        .replace("/", ".")
    )


def walk_module_paths(
    package: Path, suffixes: list[str] = DEFAULT_SUFFIXES
) -> Iterable[Path]:
    """Walk the paths of a Python package."""
    yield from sorted(
        match
        for match in walk_matches(
            package,
            regex=rf"""^
                 [^\.]*  # Match file stem
                 {get_suffixes_re(suffixes)}  # Match suffixes
                 $""",
            root_regex=r"^(?!__).*$",  # Exclude dunder folders
            flags=VERBOSE,
        )
        if match.stem != "__init__"
    )


def get_suffixes_re(suffixes: list[str]) -> str:
    """Get the regex pattern string for file suffixes."""
    suffixes_re = f"({get_suffix_re(suffixes[0])}"
    for suffix in suffixes[1:]:
        suffixes_re += f"|{get_suffix_re(suffix)}"
    suffixes_re += ")"
    return suffixes_re


def get_suffix_re(suffix: str) -> str:
    """Get the regex pattern string for a file suffix."""
    suffix = suffix.replace(r"\.", ".")
    if not suffix.startswith("."):
        suffix = f".{suffix}"
    return suffix.replace(".", r"\.")


def walk_matches(
    path: Path,
    glob: str | None = None,
    regex: str | None = None,
    root_regex: str | None = None,
    flags=NOFLAG,
) -> Iterable[Path]:
    """Walk a directory returning regex or glob matches."""
    glob = glob or "*"
    path_re = compile(regex or "^.*$", flags=flags)
    root_re = compile(root_regex or "^.*$", flags=flags)
    for root, _dirs, files in walk(path):
        if not root_re.match(Path(root).name):
            continue
        files = [Path(root) / file for file in files]
        for path in Path(root).glob(glob):
            if path in files and path_re.match(path.name):
                yield path


def fold(path: Path, resolve: bool = True) -> str:
    """Resolve and normalize a path to a POSIX string path with forward slashes."""
    return quote(str(path.resolve() if resolve else path).replace("\\", "/"))


def modified(nb: Path | str) -> bool:
    """Check whether notebook is modified."""
    return Path(nb) in (change.resolve() for change in get_changes())


def get_changes() -> list[Path]:
    """Get pending changes."""
    staged, unstaged, _ = status(untracked_files="no")
    changes = {
        # Many dulwich functions return bytes for legacy reasons
        Path(path.decode("utf-8")) if isinstance(path, bytes) else path
        for change in (*staged.values(), unstaged)
        for path in change
    }
    # Exclude submodules from the changeset (submodules are considered always changed)
    return sorted(
        change
        for change in changes
        if change not in {submodule.path for submodule in get_submodules()}
    )


@dataclass
class Submodule:
    """Represents a git submodule."""

    _path: str | bytes
    """Submodule path as reported by the submodule source."""
    commit: str
    """Commit hash currently tracked by the submodule."""
    path: Path = Path()
    """Submodule path."""
    name: str = ""
    """Submodule name."""

    def __post_init__(self):
        """Handle byte strings reported by some submodule sources, like dulwich."""
        # Many dulwich functions return bytes for legacy reasons
        self.path = Path(
            self._path.decode("utf-8") if isinstance(self._path, bytes) else self._path
        )
        self.name = self.path.name


def get_submodules() -> list[Submodule]:
    """Get the special template and typings submodules, as well as the rest."""
    with closing(repo := Repo(str(Path.cwd()))):
        return [Submodule(*item) for item in list(submodule_list(repo))]
