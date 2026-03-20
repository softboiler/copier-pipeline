"""Types."""

from typing import Annotated as Ann
from typing import Literal, TypeAlias

from cappa.arg import Arg

from pipeline_helper.models.contexts import PipelineHelperContexts

Key: TypeAlias = Literal["data", "docs"]
"""Data or docs key."""
HiddenContext: TypeAlias = Ann[PipelineHelperContexts, Arg(hidden=True)]
"""Pipeline context as a hidden argument."""
