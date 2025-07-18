"""Generated types."""

from re import sub
from shlex import quote
from subprocess import run
from sys import executable
from textwrap import dedent

from astroid import AnnAssign, Const, Subscript, Tuple, extract_node
from pipeline_helper.config import const


def init():
    """Initialize stages."""
    sync_stages()


def sync_stages():
    """Sync generated types prior to their import and usage in models."""
    stages_literals = const.generated_stages
    # ? Append `#@` annotations to tell `astroid` which nodes to extract
    src = sub(
        r"(?m)(?P<line>^StageName: TypeAlias.+$)",
        r"\g<line> #@",
        stages_literals.read_text(encoding="utf-8"),
    )
    # ? `extract_node` unpacks singletons, so wrap in list for consistency
    nodes = nodes if isinstance((nodes := extract_node(src)), list) else [nodes]
    if (
        nodes  # noqa: PLR0916
        and isinstance(nodes[0], AnnAssign)
        and (rhs := nodes[0].value)
        and isinstance(rhs, Subscript)
        and isinstance(rhs.slice, Tuple)
        and (
            (stages := list(const.stages))
            != [
                elt.value
                for elt in rhs.slice.elts
                if isinstance(elt, Const) and isinstance(elt.value, str)
            ]
        )
    ):
        stages_literals.write_text(
            encoding="utf-8",
            data=dedent(f'''
                """Stages."""
                from typing import Literal, TypeAlias
                StageName: TypeAlias = Literal{stages}
                """Stage."""
                '''),
        )
        run(
            check=True,
            args=[
                "pwsh",
                "-Command",
                f"& {quote(executable)} -m ruff format {quote(stages_literals.as_posix())}",
            ],
            capture_output=True,
        )


if __name__ == "__main__":
    init()
