"""Pipeline stages model."""

from __future__ import annotations

from IPython.display import display

from pipeline_helper.models.stage import Stage


class Params[Deps_T, Outs_T](Stage):
    """Stage parameters."""

    deps: Deps_T
    """Stage dependencies."""
    outs: Outs_T
    """Stage outputs."""

    @classmethod
    def hide(cls):
        """Hide unsuppressed output in notebook cells."""
        display()
