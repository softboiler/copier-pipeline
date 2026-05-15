"""Sync `dvc.yaml` and `params.yaml` with pipeline specification."""

from pathlib import Path

from cappa.base import command
from pydantic import BaseModel, Field


class Constants(BaseModel):
    """Constants."""

    table_key: str = "stage"
    """Key for the global parameters table."""


const = Constants()


@command(default_long=True, invoke="pipeline_helper.sync_dvc.__main__.main")
class SyncDvc(BaseModel):
    """Sync `dvc.yaml` and `params.yaml` with pipeline specification."""

    root: Path = Path.cwd()
    """Root directory for synced DVC configurations."""
    pipeline: Path = Path("dvc.yaml")
    """Primary config file describing the DVC pipeline."""
    params: Path = Path("params.yaml")
    """DVC's primary parameters YAML file."""
    stages: str = "notes_pipeline.stages"
    """Dotted module path to the package containing stages."""
    update_param_values: bool = Field(default=False)
    """Update values of parameters in the parameters YAML file."""
