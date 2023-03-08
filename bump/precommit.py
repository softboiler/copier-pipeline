"""Copy bumped pre-commit to the template folder, appending the `.jinja` suffix."""

import re
from pathlib import Path

patterns = {
    "black": r"""
  - repo: "https:\/\/github\.com\/psf\/black"
    rev: "v?(?P<version>[\d.]+)"
""",
    "ruff": r"""
  - repo: "https:\/\/github\.com\/charliermarsh\/ruff-pre-commit"
    rev: "v?(?P<version>[\d.]+)"
""",
}

# Bump pre-commit
pre_commit_source = Path("bump/.pre-commit-config.yaml")
pre_commit_destination = Path("template/.pre-commit-config.yaml.jinja")
pre_commit_text = pre_commit_source.read_text(encoding="utf-8")
versions = {
    package: re.search(pattern, pre_commit_text)["version"]  # pyright: ignore
    for package, pattern in patterns.items()
}
pre_commit_replace = {
    '        additional_dependencies: ["black=="]': f'        additional_dependencies: ["black=={versions["black"]}"]',
    '        additional_dependencies: ["ruff=="]': f'        additional_dependencies: ["ruff=={versions["ruff"]}"]',
}
pre_commit_lines = pre_commit_text.split("\n")
for line_number, line in enumerate(pre_commit_lines):
    if replacement := pre_commit_replace.get(line):
        pre_commit_lines[line_number] = replacement
pre_commit_destination.write_text(encoding="utf-8", data="\n".join(pre_commit_lines))

# Bump requirements
requirements = Path("template/.tools/requirements/requirements_dev.txt")
requirements_lines = requirements.read_text(encoding="utf-8").split("\n")
for line_number, line in enumerate(requirements_lines):
    if line.startswith("black"):
        requirements_lines[line_number] = f"black=={versions['black']}"
    if line.startswith("ruff"):
        requirements_lines[line_number] = f"ruff=={versions['ruff']}"
requirements.write_text(encoding="utf-8", data="\n".join(requirements_lines))
