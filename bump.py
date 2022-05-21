# """Copy bumped workflows to the template folder, appending the `.jinja` suffix."""

# from pathlib import Path
# from shutil import copy

# source_folder = Path(".github/workflows")
# destination_folder = Path("template/.github/workflows")

# d = {
#     '          python-version: "python_version"': '          python-version: "{{ python_version }}"',
#     "          github_token: secrets.GITHUB_TOKEN": "          github_token: ${{ secrets.GITHUB_TOKEN }}",
#     '          FLIT_PASSWORD: "secrets.PYPI_TOKEN"': '          FLIT_PASSWORD: "{% raw %}${{ secrets.PYPI_TOKEN }}{% endraw %}"',
# }


# for source in source_folder.iterdir():
#     if source.name == "bump_workflows.yml":
#         continue
#     destination = destination_folder / f"{source.name}.jinja"
#     copy(source, destination)
