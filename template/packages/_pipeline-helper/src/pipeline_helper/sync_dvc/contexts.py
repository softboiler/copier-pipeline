"""Contexts."""

from pathlib import Path
from typing import Any

from context_models.types import Context
from pydantic import BaseModel, Field

from pipeline_helper.sync_dvc.dvc import DvcYamlModel, Stage

DVC = "dvc"
"""DVC context name."""


class DvcContext(BaseModel):
    """DVC context."""

    model: DvcYamlModel = Field(default_factory=DvcYamlModel)
    """Synchronized `dvc.yaml` configuration."""
    params: dict[str, Any] = Field(default_factory=dict)
    """DVC `params.yaml` synchronized to `dvc.yaml`."""
    stage: Stage = Field(default_factory=lambda: Stage(cmd=""))
    """Current stage."""
    only_sample: str = ""
    """The only sample if `only_sample` is enabled."""
    plot_dir: Path | None = None
    """Current plotting directory."""
    plot_names: list[str] = Field(default_factory=list)
    """Current plot names."""


class DvcContexts(Context):
    """DVC contexts."""

    dvc: DvcContext
