import subprocess
from collections.abc import Iterable
from shlex import quote
from sys import executable


def run(
    args: str | Iterable[str] | None = None,
    check: bool = True,
    capture_output: bool = False,
):
    """Run command."""
    sep = " "
    subprocess.run(
        check=check,
        capture_output=capture_output,
        args=[
            "pwsh",
            "-Command",
            sep.join([
                f"& {quote(executable)} -m",
                *(([args] if isinstance(args, str) else args) or []),
            ]),
        ],
    )
