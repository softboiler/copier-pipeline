"""Contributor environment."""

import subprocess
from collections.abc import Sequence
from contextlib import chdir, nullcontext
from io import StringIO
from pathlib import Path
from shlex import quote, split
from sys import platform

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


def run(args: str | Sequence[str]):
    """Build docs."""
    sep = " "
    subprocess.run(
        check=True,
        args=split(
            sep.join([
                "pwsh -Command",
                f"{get_venv_activator()};",
                *([args] if isinstance(args, str) else args),
            ])
        ),
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


def get_venv_activator():
    """Get virtual environment activator."""
    return (
        escape(activate)
        if (
            activate := (
                Path(".venv/scripts/activate.ps1")
                if platform == "win32"
                else Path(".venv/bin/activate.ps1")
            )
        ).exists()
        else ""
    )


def escape(path: str | Path) -> str:
    """Escape a path, suitable for passing to e.g. {func}`~subprocess.run`."""
    return quote(Path(path).as_posix())
