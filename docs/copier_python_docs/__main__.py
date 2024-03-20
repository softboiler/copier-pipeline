"""Insert `hide-input` tag to all documentation notebooks."""

from pathlib import Path
from textwrap import dedent

from nbformat import NO_CONVERT, NotebookNode, read, write


def main():
    for path in Path("docs").rglob("*.ipynb"):
        nb: NotebookNode = read(path, NO_CONVERT)  # type: ignore  # pyright 1.1.348,  # nbformat: 5.9.2
        # Insert tags to all code cells
        for i, cell in enumerate(nb.cells):
            if cell.cell_type != "code":
                continue
            nb.cells[i] = insert_tag(cell, ["hide-input", "parameters"])
        # Write the notebook back
        write(nb, path)


def insert_tag(cell: NotebookNode, tags_to_insert: list[str]) -> NotebookNode:
    """Insert tags to a notebook cell.

    See: https://jupyterbook.org/en/stable/content/metadata.html?highlight=python#add-tags-using-python-code
    """
    tags = cell.get("metadata", {}).get("tags", [])
    cell["metadata"]["tags"] = tags_to_insert + list(set(tags) - set(tags_to_insert))
    return cell


def get_first(nb: NotebookNode, cell_type: str) -> tuple[int, NotebookNode]:
    """Get the first cell of a given type."""
    return next((i, c) for i, c in enumerate(nb.cells) if c.cell_type == cell_type)


def patch(src: str, content: str, end: str = "\n\n") -> str:
    """Prepend source lines to cell source if not there already."""
    content = dedent(content).strip()
    return src if src.startswith(content) else f"{content}{end}{src}"


main()
