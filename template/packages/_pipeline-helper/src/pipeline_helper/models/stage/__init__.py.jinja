"""Pipeline stage model and models at sub-pipeline stage granularity."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Self

from pydantic import BaseModel, ValidationInfo, field_validator, model_validator
from pydantic.functional_validators import ModelWrapValidatorHandler

from pipeline_helper.sync_dvc.validators import (
    dvc_add_param,
    dvc_prepare_stage,
    dvc_set_stage_path,
)


class Stage(BaseModel):
    """Base of pipeline stage models."""

    @model_validator(mode="wrap")
    @classmethod
    def dvc_prepare_stage(
        cls,
        data: dict[str, Any],
        handler: ModelWrapValidatorHandler[Self],
        info: ValidationInfo,
    ) -> Self:
        """Prepare a pipeline stage for `dvc.yaml`."""
        return dvc_prepare_stage(data, handler, info, model=cls)

    @field_validator("*", mode="after")
    @classmethod
    def dvc_add_param(cls, value: Any, info: ValidationInfo) -> Any:
        """Add param to global parameters and stage command for `dvc.yaml`."""
        return dvc_add_param(value, info, fields=cls.model_fields)


class StagePaths(BaseModel):
    """Paths for stage dependencies and outputs."""

    @field_validator("*", mode="after")
    @classmethod
    def dvc_set_stage_path(cls, path: Path, info: ValidationInfo) -> Path:
        """Set stage path as a stage dep, plot, or out for `dvc.yaml`."""
        return dvc_set_stage_path(
            path, info, kind="deps" if issubclass(cls, Deps) else "outs"
        )


class Deps(StagePaths):
    """Stage dependency paths."""


class Outs(StagePaths):
    """Stage output paths."""


class DfsPlotsOuts(Outs):
    """Stage output paths including data frames and plots."""

    dfs: Path
    """Output data directory for this stage."""
    plots: Path
    """Output plots directory for this stage."""


class DataStage(BaseModel):
    """Data stage in a pipeline stage."""

    src: str = "src"
    """Source data for this stage."""
    dst: str = "dst"
    """Destination data for this stage."""
