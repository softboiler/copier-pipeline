"""Copy bumped workflows to the template folder, appending the `.jinja` suffix."""


from pathlib import Path

source_folder = Path("bump/workflows")
destination_folder = Path("template/.github/workflows")

replace = {
    # "    runs-on: ubuntu-latest": "    runs-on: {{ actions_runner }}",
    # "          python-version:": '          python-version: "{{ python_version }}"',
    # "          github_token:": "          github_token: {% raw %}${{ secrets.GITHUB_TOKEN }}{% endraw %}",
    # "          FLIT_PASSWORD:": "          FLIT_PASSWORD: {% raw %}${{ secrets.PYPI_TOKEN }}{% endraw %}",
    # "          languages:": "          languages: {% raw %}${{ matrix.language }}{% endraw %}",
}

for source in source_folder.iterdir():
    text = source.read_text(encoding="utf-8")
    lines = text.split("\n")
    for line_no, line in enumerate(lines):
        if replacement := replace.get(line):
            lines[line_no] = replacement
    destination = destination_folder / f"{source.name}.jinja"
    destination.write_text("\n".join(lines))
