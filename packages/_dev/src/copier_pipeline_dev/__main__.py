"""Command-line interface."""

from dataclasses import dataclass

from cappa.base import command, invoke
from cappa.subcommand import Subcommands


@command(invoke="copier_pipeline_dev.tools.add_change")
class AddChange:
    """Add change."""


@command(invoke="copier_pipeline_dev.tools.get_actions")
class GetActions:
    """Get actions used by this repository."""


@command(invoke="copier_pipeline_dev.tools.sync_local_dev_configs")
class SyncLocalDevConfigs:
    """Synchronize local dev configs."""


@command(invoke="copier_pipeline_dev.tools.elevate_pyright_warnings")
class ElevatePyrightWarnings:
    """Elevate Pyright warnings to errors."""


@dataclass
class CopierPipelineDev:
    """Dev tools."""

    commands: Subcommands[
        AddChange | GetActions | SyncLocalDevConfigs | ElevatePyrightWarnings
    ]


def main():
    """CLI entry-point."""
    invoke(CopierPipelineDev)


if __name__ == "__main__":
    main()
