"""Copy bumped workflows to the template folder, appending the `.jinja` suffix."""

from pathlib import Path
from shutil import copy

source_folder = Path("template_workflows")
destination_folder = Path("template/.github/workflows")

replace = {
    '          python-version: "python_version"': '          python-version: "{{ python_version }}"',
    "          github_token: secrets.GITHUB_TOKEN": "          github_token: ${{ secrets.GITHUB_TOKEN }}",
    '          FLIT_PASSWORD: "secrets.PYPI_TOKEN"': '          FLIT_PASSWORD: "{% raw %}${{ secrets.PYPI_TOKEN }}{% endraw %}"',
}


for source in source_folder.iterdir():
    if source.name == "bump_workflows.yml":
        continue
    text = source.read_text(encoding="utf-8")
    lines = text.split("\n")
    for line_no, line in enumerate(lines):
        if replacement := replace.get(line):
            lines[line_no] = replacement
    destination = destination_folder / f"{source.name}.jinja"
    destination.write_text("\n".join(lines))
