"""Documentation utilities."""

from dataclasses import dataclass
from os import chdir
from pathlib import Path
from shutil import copy, copytree

from IPython.display import display  # type: ignore
from matplotlib.pyplot import style
from numpy import set_printoptions
from pandas import options
from seaborn import set_theme

DOCS = Path("docs")
"""Docs."""
DEPS = Path("tests/root")
"""Dependencies shared with tests."""
FONT_SCALE = 1.3
"""Plot font scale."""
PRECISION = 4
"""The desired precision."""
FLOAT_SPEC = f"#.{PRECISION}g"
"""The desired float specification for formatted output."""
HIDE = display()
"""Hide unsuppressed output. Can't use semicolon due to black autoformatter."""
DISPLAY_ROWS = 20
"""The number of rows to display in a dataframe."""


@dataclass
class Paths:
    root: Path
    docs: Path
    deps: Path


def init(font_scale: float = FONT_SCALE) -> Paths:
    """Initialize a documentation notebook."""
    path = Path().cwd()
    while not is_root(path):
        if path == (path := path.parent):
            raise RuntimeError("Either documentation or dependencies are missing.")
    paths = Paths(*[p.resolve() for p in (path, path / DOCS, path / DEPS)])
    set_display_options(font_scale)
    return paths


def is_root(path: Path) -> bool:
    """Check if the path is the root of the project."""
    return (path / DOCS).exists() and (path / DEPS).exists()


def copy_deps(src, dst):
    """Copy dependencies to the destination directory."""
    chdir(dst)
    copy(src / "params.yaml", dst)
    copytree(src / "data", dst / "data", dirs_exist_ok=True)


def set_display_options(font_scale):
    # The triple curly braces in the f-string allows the format function to be
    # dynamically specified by a given float specification. The intent is clearer this
    # way, and may be extended in the future by making `float_spec` a parameter.
    options.display.float_format = f"{{:{FLOAT_SPEC}}}".format
    options.display.min_rows = options.display.max_rows = DISPLAY_ROWS
    set_printoptions(precision=PRECISION)
    set_theme(
        context="notebook",
        style="whitegrid",
        palette="deep",
        font="sans-serif",
        font_scale=font_scale,
    )
    style.use("data/plotting/base.mplstyle")
