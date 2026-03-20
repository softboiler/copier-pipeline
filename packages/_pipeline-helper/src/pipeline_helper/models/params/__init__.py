"""Pipeline stages model."""

from __future__ import annotations

from typing import Generic

from IPython.display import display

from pipeline_helper.models.params.types import Deps_T, Outs_T
from pipeline_helper.models.stage import Stage


class Params(Stage, Generic[Deps_T, Outs_T]):
    """Stage parameters."""

    deps: Deps_T
    """Stage dependencies."""
    outs: Outs_T
    """Stage outputs."""

    @classmethod
    def hide(cls):
        """Hide unsuppressed output in notebook cells."""
        display()
