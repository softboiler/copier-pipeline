"""Copy bumped workflows to the template folder, appending the `.jinja` suffix."""

from pathlib import Path
from shutil import copy

source_folder = Path(".github/workflows")
destination_folder = Path("template/.github/workflows")

for source in source_folder.iterdir():
    if source.name == "bump_workflows.yml":
        continue
    destination = destination_folder / f"{source.name}.jinja"
    copy(source, destination)
