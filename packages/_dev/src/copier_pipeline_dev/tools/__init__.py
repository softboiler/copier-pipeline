"""Tools."""

from base64 import b64encode
from json import dumps
from pathlib import Path
from re import finditer, sub
from shlex import join, split
from tomllib import loads

from copier_pipeline_dev import log
from copier_pipeline_dev.cli import ElevatePyrightWarnings
from copier_pipeline_dev.tools import add_changes
from copier_pipeline_dev.tools.types import ChangeType


def add_change(change: ChangeType = "change"):
    """Add change."""
    add_changes.add_change(change)


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


def sync_local_dev_configs():
    """Synchronize local dev configs to shadow `pyproject.toml`, with some changes.

    Duplicate pytest configuration from `pyproject.toml` to `pytest.ini`. These files
    shadow the configuration in `pyproject.toml`, which drives CI or if shadow configs
    are not present. Shadow configs are in `.gitignore` to facilitate local-only
    shadowing. Concurrent test runs are disabled in the local pytest configuration which
    slows down the usual local, granular test workflow.
    """
    config = loads(Path("pyproject.toml").read_text("utf-8"))
    pytest = config["tool"]["pytest"]["ini_options"]
    pytest["addopts"] = disable_concurrent_tests(pytest["addopts"])
    Path("pytest.ini").write_text(
        encoding="utf-8",
        data="\n".join(["[pytest]", *[f"{k} = {v}" for k, v in pytest.items()], ""]),
    )


def disable_concurrent_tests(addopts: str) -> str:
    """Normalize `addopts` string and disable concurrent pytest tests."""
    return sub(pattern=r"-n\s[^\s]+", repl="-n 0", string=join(split(addopts)))


def elevate_pyright_warnings(args: ElevatePyrightWarnings):
    """Elevate Pyright warnings to errors."""
    config = loads(Path("pyproject.toml").read_text("utf-8"))
    pyright = config["tool"]["pyright"]
    for k, v in pyright.items():
        if (rule := k).startswith("report") and (_level := v) == "warning":
            pyright[rule] = "error"
    Path(args.path or "pyrightconfig.json").write_text(
        encoding="utf-8", data=dumps(pyright, indent=2)
    )


def encode_powershell_script(script: str) -> bytes:
    """Encode a PowerShell script to Base64 for passing to `-EncodedCommand`."""
    return b64encode(bytearray(script, "utf-16-le"))
