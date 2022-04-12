import re
from pathlib import Path

gitignore_to_merge = Path("tooling/scripts/gitignore_to_merge")
gitignore = Path(".gitignore")

lookbehind = r"(?<=^#\[\[\n)"  # look behind for line containing only "# [["
match = r"[\s\S]+"  # match everything between the above and below tokens
lookahead = r"(?=^#\]\]\n)"  # look ahead for line containing only "# ]]"

gitignore.write_text(
    re.sub(
        f"{lookbehind}{match}{lookahead}",
        gitignore_to_merge.read_text(),
        gitignore.read_text(),
        flags=re.MULTILINE,
    )
)
