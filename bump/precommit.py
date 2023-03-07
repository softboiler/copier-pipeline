"""Copy bumped pre-commit to the template folder, appending the `.jinja` suffix."""

import re
from pathlib import Path

source_file = Path("bump/.pre-commit-config.yaml")
destination_file = Path("template/.pre-commit-config.yaml.jinja")
text = source_file.read_text(encoding="utf-8")
pattern = re.compile(
    r"""
  - repo: https:\/\/github\.com\/psf\/black
    hooks:
      - id: black
    rev: "(?P<black_version>[\d.]+)"
"""
)
black_version = pattern.search(text)["black_version"]  # pyright: ignore
replace = {
    '        additional_dependencies: ["black=="]': f'        additional_dependencies: ["black=={black_version}"]',
}
lines = text.split("\n")
for line_no, line in enumerate(lines):
    if replacement := replace.get(line):
        lines[line_no] = replacement
destination_file.write_text("\n".join(lines[:-1]))
