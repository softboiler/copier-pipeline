import re
from pathlib import Path

gitignore_to_merge = Path("tooling/tests/gitignore_to_merge")
gitignore = Path(".gitignore")
re.search(r"^#\[\[\n\n(?P<contents>[\s\S]+)\n\n#\]\]", gitignore.read_text(), re.MULTILINE)["contents"]
