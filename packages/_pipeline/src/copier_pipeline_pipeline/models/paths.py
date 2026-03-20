"""Parameter models for this project."""

from pathlib import Path
from typing import get_args

from copier_pipeline_pipeline.models.generated.types.stages import StageName
from pipeline_helper.models.path import (
    DataDir,
    DocsFile,
    PipelineHelperContextStore,
    get_pipeline_helper_config,
)


class Paths(PipelineHelperContextStore):
    """Pipeline paths."""

    model_config = get_pipeline_helper_config(track_kinds=True)
    notebooks: dict[str | StageName, DocsFile] = {  # noqa: RUF012
        stage_name: Path("notebooks") / f"{stage_name}.ipynb"
        for stage_name in get_args(StageName)
    }
    example: DataDir = Path("example")
    example_out: DataDir = Path("example_out")


paths = Paths()
