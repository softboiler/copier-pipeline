from pathlib import Path
from typing import Annotated as Ann

from cappa.arg import Arg
from cappa.base import command
from pipeline_helper.models import stage
from pipeline_helper.models.params import Params
from pipeline_helper.models.path import DataDir, DirectoryPathSerPosix, DocsFile
from pydantic import Field

from copier_pipeline_pipeline.models.paths import paths


class Deps(stage.Deps):
    stage: DirectoryPathSerPosix = Path(__file__).parent
    nb: DocsFile = paths.notebooks[stage.stem]
    example: DataDir = paths.example


class Outs(stage.Outs):
    example_out: DataDir = paths.example_out


@command(default_long=True, invoke="copier_pipeline_pipeline.stages.example.__main__.main")
class Example(Params[Deps, Outs]):
    """Run example pipeline stage."""

    deps: Ann[Deps, Arg(hidden=True)] = Field(default_factory=Deps)
    outs: Ann[Outs, Arg(hidden=True)] = Field(default_factory=Outs)
