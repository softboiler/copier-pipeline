"""Copy bumped pre-commit to the template folder, appending the `.jinja` suffix."""

from pathlib import Path

source_file = Path("bump/pre-commit-config.yaml")
destination_file = Path(
    "template/{% if not override_precommit %}.pre-commit-config.yaml{% endif %}.jinja"
)

replace = {
    "#  {% if use_dvc -%}": "  {% if use_dvc -%}",
    "#  {% endif -%}": "  {% endif -%}",
}

text = source_file.read_text(encoding="utf-8")
lines = text.split("\n")
for line_no, line in enumerate(lines):
    if replacement := replace.get(line):
        lines[line_no] = replacement
destination_file.write_text("\n".join(lines))
