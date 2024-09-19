"""Intersphinx URL handlers."""

from dev.docs.types import IspxMappingValue


def get_url(url: str, latest: bool = False):
    """Get Intersphinx mapping value for generic URLs."""
    return get_ispx(url, latest)


def get_rtd(pkg: str, latest: bool = False):
    """Get Intersphinx mapping value for ReadTheDocs-styled links."""
    return get_ispx(f"{pkg.replace('_', '-')}.readthedocs.io/en", latest)


def get_ispx(url: str, latest: bool | None = None):
    """Get Intersphinx mapping value."""
    subpath = f"/{'latest' if latest else 'stable'}" if latest is not None else ""
    return IspxMappingValue(f"https://{url}{subpath}", None)
