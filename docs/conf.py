from datetime import date

project = ""
html_title = "copier-python"
copyright = f"{date.today().year}, Blake Naccarato"  # noqa: A001
version = "0.0.0"
master_doc = "index"
language = "en"
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]
html_theme = "sphinx_book_theme"
extensions = ["myst_parser", "sphinx_design"]
