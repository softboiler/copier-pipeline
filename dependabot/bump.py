"""Copy bumped workflows to the template folder, appending the `.jinja` suffix."""

from pathlib import Path

COMMON_PATH = ".github/workflows"
source_folder = Path("./dependabot") / COMMON_PATH
destination_folder = Path("./tooling/") / COMMON_PATH

for file in source_folder.iterdir():
    file.rename(source_folder / (file.name + ".jinja"))
