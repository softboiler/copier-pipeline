"""Bump template `.pre-commit-config.yaml` and `requirements.txt`.

Synchronize `black` and `ruff` in pre-commit and `requirements.txt`.
"""

import re
from pathlib import Path

PRE_COMMIT = Path("template/.pre-commit-config.yaml")
REQUIREMENTS = Path("template/.tools/requirements/requirements_both.txt")

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
pre_commit_text = PRE_COMMIT.read_text(encoding="utf-8")
versions = {
    package: re.search(pattern, pre_commit_text)["version"]  # pyright: ignore
    for package, pattern in patterns.items()
}
# fmt: off
# Visually align these long lines before mapping them below
black_find =  '        additional_dependencies: ["black=='
black_repl = f'        additional_dependencies: ["black=={versions["black"]}"]'
ruff_find =   '        additional_dependencies: ["ruff=='
ruff_repl =  f'        additional_dependencies: ["ruff=={versions["ruff"]}"]'
# fmt: on
pre_commit_replace = {black_find: black_repl, ruff_find: ruff_repl}
pre_commit_lines = pre_commit_text.split("\n")
for line_number, line in enumerate(pre_commit_lines):
    if line.startswith(black_find):
        pre_commit_lines[line_number] = black_repl
    elif line.startswith(ruff_find):
        pre_commit_lines[line_number] = ruff_repl
PRE_COMMIT.write_text(encoding="utf-8", data="\n".join(pre_commit_lines))

# Bump requirements
requirements_lines = REQUIREMENTS.read_text(encoding="utf-8").split("\n")
for line_number, line in enumerate(requirements_lines):
    if line.startswith("black"):
        requirements_lines[line_number] = f"black=={versions['black']}"
    if line.startswith("ruff"):
        requirements_lines[line_number] = f"ruff=={versions['ruff']}"
REQUIREMENTS.write_text(encoding="utf-8", data="\n".join(requirements_lines))
