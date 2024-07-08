"""CLI for tools."""

from collections.abc import Collection
from json import dumps
from pathlib import Path
from re import finditer
from sys import version_info

from cyclopts import App

from copier_python_tools import add_changes
from copier_python_tools.sync import check_compilation, escape
from copier_python_tools.types import ChangeType

if version_info >= (3, 11):  # noqa: UP036, RUF100
    from tomllib import loads  # pyright: ignore[reportMissingImports]
else:
    from toml import (  # pyright: ignore[reportMissingModuleSource, reportMissingImports]
        loads,
    )

APP = App(help_format="markdown")
"""CLI."""


def main():  # noqa: D103
    APP()


@APP.command
def compile(high: bool = False):  # noqa: A001
    """Compile."""
    log(check_compilation(high))


@APP.command
def add_change(change: ChangeType = "change"):
    """Add change."""
    add_changes.add_change(change)


@APP.command
def get_actions():
    """Get actions used by this repository.

    For additional security, select "Allow <user> and select non-<user>, actions and
    reusable workflows" in the General section of your Actions repository settings, and
    paste the output of this command into the "Allow specified actions and reusable
    workflows" block.

    Parameters
    ----------
    high
        Highest dependencies.
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


@APP.command
def elevate_pyright_warnings():
    """Elevate Pyright warnings to errors."""
    config = loads(Path("pyproject.toml").read_text("utf-8"))
    pyright = config["tool"]["pyright"]
    for k, v in pyright.items():
        if (rule := k).startswith("report") and (_level := v) == "warning":
            pyright[rule] = "error"
    Path("pyrightconfig.json").write_text(
        encoding="utf-8", data=dumps(pyright, indent=2)
    )


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
