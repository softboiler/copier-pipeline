import toml
from pathlib import Path

DEPENDENCIES = ["fire~=0.4"]
PATH = Path("pyproject.toml")

with open(PATH) as file:
    content = toml.load(file)
    content["project"]["dependencies"] = DEPENDENCIES

with open(PATH, "w") as file:
    toml.dump(content, file)
