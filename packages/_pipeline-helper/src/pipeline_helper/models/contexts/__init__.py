"""Contexts."""

from pathlib import Path

from context_models.types import Context
from pydantic import BaseModel, Field

from pipeline_helper.config import const
from pipeline_helper.models.contexts.types import Kinds

pipeline_helper = "pipeline_helper"
"""Context name for `pipeline_helper`."""


class Roots(BaseModel):
    """Root directories."""

    data: Path | None = None
    """Data."""
    docs: Path | None = None
    """Docs."""


ROOTED = Roots(data=const.root / const.data, docs=const.root / const.docs)
"""Paths rooted to their directories."""


class PipelineHelperContext(BaseModel):
    """Root directory context."""

    roots: Roots = Field(default_factory=Roots)
    """Root directories for different kinds of paths."""
    kinds: Kinds = Field(default_factory=dict)
    """Kind of each path."""
    track_kinds: bool = False
    """Whether to track kinds."""


class PipelineHelperContexts(Context):
    """AMSL LabJack pipeline context."""

    pipeline_helper: PipelineHelperContext
