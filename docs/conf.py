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
# https://sphinx-book-theme.readthedocs.io/en/stable/reference.html#reference-of-theme-options
html_theme_options = {
    "path_to_docs": "docs",
    "repository_url": "https://github.com/blakeNaccarato/copier-python",
    "repository_branch": "main",
    "use_download_button": True,
    "use_fullscreen_button": True,
    "use_repository_button": True,
}
