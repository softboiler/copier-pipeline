"""Contributor environment."""

import subprocess
from collections.abc import Iterable
from contextlib import chdir, nullcontext
from io import StringIO
from pathlib import Path
from shlex import quote
from sys import executable

from dotenv import load_dotenv
from pydantic_settings import (
    BaseSettings,
    PyprojectTomlConfigSettingsSource,
    SettingsConfigDict,
)


def init_shell(path: Path | None = None) -> str:
    """Initialize shell."""
    with chdir(path) if path else nullcontext():
        environment = Environment().model_dump()
        dotenv = "\n".join(f"{k}={v}" for k, v in environment.items())
        load_dotenv(stream=StringIO(dotenv))
        return dotenv


def run(args: str | Iterable[str] | None = None):
    """Run command."""
    sep = " "
    subprocess.run(
        check=True,
        args=[
            "pwsh",
            "-Command",
            sep.join([
                f"& {quote(executable)} -m",
                *(([args] if isinstance(args, str) else args) or []),
            ]),
        ],
    )


class Environment(BaseSettings):
    """Get environment variables from `pyproject.toml:[tool.env]`."""

    model_config = SettingsConfigDict(
        extra="allow", pyproject_toml_table_header=("tool", "env")
    )

    @classmethod
    def settings_customise_sources(cls, settings_cls, **_):  # pyright: ignore[reportIncompatibleMethodOverride]
        """Customize so that all keys are loaded despite not being model fields."""
        return (PyprojectTomlConfigSettingsSource(settings_cls),)


def escape(path: str | Path) -> str:
    """Escape a path, suitable for passing to e.g. {func}`~subprocess.run`."""
    return quote(Path(path).as_posix())
