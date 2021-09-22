"""Copy bumped workflows to the template folder, appending the `.jinja` suffix."""

from pathlib import Path
from shutil import copy

COMMON_PATH = ".github/workflows"
source_folder = Path("./dependabot") / COMMON_PATH
destination_folder = Path("./template/") / COMMON_PATH

for source in source_folder.iterdir():
    destination = destination_folder / (source.name + ".jinja")
    copy(source, destination)
