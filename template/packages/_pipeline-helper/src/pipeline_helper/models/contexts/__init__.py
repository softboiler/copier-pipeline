"""Contexts."""

from pathlib import Path
from typing import Annotated as Ann
from typing import TypeAlias

from context_models.types import Context
from pydantic import (
    BaseModel,
    DirectoryPath,
    Field,
    FilePath,
    SerializerFunctionWrapHandler,
    WrapSerializer,
)

from pipeline_helper.config import const
from pipeline_helper.models.contexts.types import Kinds

pipeline_helper = "pipeline_helper"
"""Context name for `pipeline_helper`."""


def resolve_path(value: Path | str, nxt: SerializerFunctionWrapHandler) -> str:
    """Resolve paths and serialize POSIX-style."""
    return nxt(Path(value).resolve().as_posix())


FilePathSerPosix = Ann[FilePath, WrapSerializer(resolve_path)]
"""Directory path that serializes as POSIX."""
DirectoryPathSerPosix: TypeAlias = Ann[DirectoryPath, WrapSerializer(resolve_path)]
"""Directory path that serializes as POSIX."""


class Roots(BaseModel):
    """Root directories."""

    data: DirectoryPathSerPosix | None = None
    """Data."""
    docs: DirectoryPathSerPosix | None = None
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
