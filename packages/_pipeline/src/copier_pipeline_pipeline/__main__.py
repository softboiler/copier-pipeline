"""Command-line interface."""

from copier_pipeline_pipeline.cli import Pipeline
from copier_pipeline_pipeline.parser import invoke


def main():
    """CLI entry-point."""
    invoke(Pipeline)


if __name__ == "__main__":
    main()
