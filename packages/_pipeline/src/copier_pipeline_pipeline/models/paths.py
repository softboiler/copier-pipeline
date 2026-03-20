"""Parameter models for this project."""

from pathlib import Path
from typing import get_args

from pydantic import BaseModel

from copier_pipeline_pipeline.models.generated.types.stages import StageName


class Paths(BaseModel):
    """Pipeline paths."""

    notebooks: dict[str | StageName, Path] = {
        stage_name: Path("notebooks") / f"{stage_name}.ipynb"
        for stage_name in get_args(StageName)
    }
    example: Path = Path("example")
    example_out: Path = Path("example_out")


paths = Paths()
