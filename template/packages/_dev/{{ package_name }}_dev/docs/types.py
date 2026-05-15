"""Types."""

from typing import NamedTuple

# * MARK: intersphinx


class IspxMappingValue(NamedTuple):
    """Intersphinx mapping value."""

    url: str
    path: str | None = None


# * MARK: docstrings
type SeeAlsoReference = tuple[str, None]
"""In all examples given, there is a "None" here, like (numpy.dot, None)."""
type SeeAlsoRelationship = list[str]
"""The (optional) relationship is empty if not provided, else one str per line."""
type SingleSeeAlso = tuple[list[SeeAlsoReference], SeeAlsoRelationship]
"""One "entry" in the See Also section."""
type SeeAlsoSection = list[SingleSeeAlso]
"""The full "See Also" section, as returned by `numpydoc.docscrape.NumpyDoc`."""
type RegularSection = list[str]
"""One list element per (unstripped) line of input."""
