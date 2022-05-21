"""Copy bumped workflows to the template folder, appending the `.jinja` suffix."""

from pathlib import Path
from shutil import copy

source_folder = Path(".github/template")
destination_folder = Path("template/.github/workflows")

for source in source_folder.iterdir():
    destination = destination_folder / f"{source.name}.jinja"
    copy(source, destination)
