"""Startup for Python.

Avoid activating Rich features that break functionality outside of the REPL.
"""

from itertools import chain
from pathlib import Path
from typing import Literal, NamedTuple, TypeAlias
from warnings import filterwarnings


def init():
    filter_certain_warnings()

    from rich import inspect, traceback  # noqa: F401

    traceback.install()

    if not is_notebook_or_ipython():
        from rich import pretty, print  # noqa: F401

        pretty.install()


# https://stackoverflow.com/a/39662359
def is_notebook_or_ipython() -> bool:
    try:
        shell = get_ipython().__class__.__name__  # type: ignore  # pyright 1.1.308, dynamic
    except NameError:
        return False  # Probably standard Python interpreter
    else:
        return shell == "TerminalInteractiveShell"


Action: TypeAlias = Literal["default", "error", "ignore", "always", "module", "once"]


class WarningFilter(NamedTuple):
    """A warning filter, e.g. to be unpacked into `warnings.filterwarnings`."""

    action: Action = "ignore"
    message: str = ""
    category: type[Warning] = Warning
    module: str = ""
    lineno: int = 0
    append: bool = False


def filter_certain_warnings():
    """Filter certain warnings for a package."""
    filterwarnings("default")
    for filt in chain.from_iterable(
        get_default_warnings_for_src(category)
        for category in [DeprecationWarning, PendingDeprecationWarning, EncodingWarning]
    ):
        filterwarnings(*filt)


def get_default_warnings_for_src(
    category: type[Warning]
) -> tuple[WarningFilter, WarningFilter]:
    """Get filter which sets default warning behavior only for the package in `src`."""
    package = next(path for path in Path("src").iterdir() if path.is_dir()).name
    all_package_modules = rf"{package}\..*"
    return (
        WarningFilter(action="ignore", category=category),
        WarningFilter(action="default", category=category, module=all_package_modules),
    )


init()
