"""CLI for tools."""

from collections.abc import Collection
from pathlib import Path
from re import finditer
from typing import NamedTuple

from cyclopts import App

from copier_python_tools import sync
from copier_python_tools.sync import COMPS, escape, get_comp_names

APP = App(help_format="markdown")
"""CLI."""


def main():
    """Invoke the CLI."""
    APP()


class Comp(NamedTuple):
    """Dependency compilation."""

    low: Path
    """Path to the lowest direct dependency compilation."""
    high: Path
    """Path to the highest dependency compilation."""


@APP.command()
def lock():
    log(sync.lock())


@APP.command()
def compile():  # noqa: A001
    """Prepare a compilation.

    Args:
        get: Get the compilation rather than compile it.
    """
    comp_paths = Comp(*[COMPS / f"{name}.txt" for name in get_comp_names()])
    COMPS.mkdir(exist_ok=True, parents=True)
    for path, comp in zip(comp_paths, sync.compile(), strict=True):
        path.write_text(encoding="utf-8", data=comp)
    log(comp_paths)


@APP.command()
def get_actions():
    """Get actions used by this repository.

    For additional security, select "Allow <user> and select non-<user>, actions and
    reusable workflows" in the General section of your Actions repository settings, and
    paste the output of this command into the "Allow specified actions and reusable
    workflows" block.

    Args:
        high: Highest dependencies.
    """
    actions: list[str] = []
    for contents in [
        path.read_text("utf-8") for path in Path(".github/workflows").iterdir()
    ]:
        actions.extend([
            f"{match['action']}@*,"
            for match in finditer(r'uses:\s?"?(?P<action>.+)@', contents)
        ])
    log(sorted(set(actions)))


def log(obj):
    """Send object to `stdout`."""
    match obj:
        case str():
            print(obj)  # noqa: T201
        case Collection():
            for o in obj:
                log(o)
        case Path():
            log(escape(obj))
        case _:
            print(obj)  # noqa: T201


if __name__ == "__main__":
    main()
