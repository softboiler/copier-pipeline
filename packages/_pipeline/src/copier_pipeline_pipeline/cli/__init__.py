"""Command-line interface."""

from __future__ import annotations

from cappa.base import command
from cappa.subcommand import Subcommands
from pipeline_helper.sync_dvc import SyncDvc


@command(name="copier-pipeline-pipeline")
class Pipeline:
    """Run the research data pipeline."""

    commands: Subcommands[SyncDvc]
