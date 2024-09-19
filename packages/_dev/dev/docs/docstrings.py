"""Helpers for parsing and rendering docstrings in Sphinx.

References
----------
Copyright 2023 Digital Biology, Inc., SPDX-License-Identifier: Apache-2.0, https://github.com/sphinx-extensions2/sphinx-autodoc2/issues/33#issuecomment-1817348449
"""

import re
import textwrap
from typing import Final

from docutils import nodes
from myst_parser.parsers.sphinx_ import MystParser
from numpydoc.docscrape import NumpyDocString, Parameter

from dev.docs.types import RegularSection, SeeAlsoSection, SingleSeeAlso

_PARAMETERS_SECTIONS: Final[tuple[str, ...]] = (
    "Parameters",
    "Returns",
    "Yields",
    "Receives",
    "Other Parameters",
    "Raises",
    "Warns",
    "Attributes",
)
_REGULAR_SECTIONS: Final[tuple[str, ...]] = (
    "Warnings",
    "Notes",
    "References",
    "Examples",
)
_OTHER_PARAMETERS = re.compile(".*Other Parameters *\n *--+ *\n")
"""
Regular expression to check if the "Other Parameters" section has been used.

We cannot allow users to include "Other Parameters" section, because we hijack it to
easily render our "Output Files" section without having to patch the NumpyDoc parser.

Matches text that looks like:

```
Other Parameters
----------------
```
"""
_OUTPUT_SECTION_TITLE = re.compile(
    "(?P<before>.*?)(?P<padding> *)Output Files\n *-+(?P<after>.*)",
    re.MULTILINE | re.DOTALL,
)
"""
Regular expression to extract the "Output Files" section title in rST format.

We use this to pretend the "Output Files" section title is actually "Other Parameters"
before passing it to the NumpyDoc parser.

Matches text that looks like:

```
{before}
{padding}Output Files
    -------
{after}
```
"""


def render_see_also(see_also: SingleSeeAlso) -> str:
    """Render a single NumpyDoc "See Also" reference."""
    references, relationship_lines = see_also
    output = ", ".join(ref_name for ref_name, _ in references)
    if relationship_lines:
        output += ": " + " ".join(relationship_lines)
    return output


def render_see_also_section(section: SeeAlsoSection) -> str:
    """Render the full "See Also" section from parsed output of NumpyDoc."""
    return "\n".join(f"- {render_see_also(p)}" for p in section)


def render_regular_section(section: RegularSection) -> str:
    """Render any other section."""
    return textwrap.dedent("\n".join(section))


def render_parameter(parameter: Parameter) -> str:
    """Render a single NumpyDoc Parameter as Markdown."""
    output = ""
    if parameter.name:
        escaped_name = parameter.name.replace("*", r"\*")
        output += f"**{escaped_name}**"
    if parameter.type:
        escaped_type = parameter.type.replace("_", r"\_")
        output += f" (_{escaped_type}_)"
    if parameter.desc:
        output += ": " + " ".join(parameter.desc)
    return output


def render_parameter_section(section: list[Parameter]) -> str:
    """Convert parsed parameters into final markdown we want to render."""
    return "\n".join(f"- {render_parameter(p)}" for p in section)


def report_errors_in_docstring(doc: str, document: nodes.document) -> None:
    """Warn for docstring errors."""
    parsed = NumpyDocString(doc)
    for section_title in _PARAMETERS_SECTIONS:
        for parameter in parsed[section_title]:
            if ":" in parameter.name and (source := document.current_source):  # pyright: ignore[reportAttributeAccessIssue]
                document.reporter.warning(
                    f"Found colon in parameter name ({parameter.name}), please leave a space between the parameter name and the colon if you meant this to be a type annotation.",  # pyright: ignore[reportAttributeAccessIssue]
                    # If we don't explicitly pass "source" here, then
                    # `docutils.utils.system_message` will try to find both the source
                    # and line number. Unfortunately, `autodoc2.sphinx.docstring`
                    # patches the `get_source_and_line` function, causing this to fail
                    # for our message since we aren't tracking the line the same way
                    # `autodoc2` does. To prevent all this mess, we just pass "source".
                    source=source,
                )


def to_pure_markdown(doc: str, use_other_params_as_outputs: bool = True) -> str:
    """Convert a hybrid NumpyDoc/MyST docstring to pure Markdown."""
    parsed = NumpyDocString(doc)
    result = ""
    if summary := parsed["Summary"]:
        # Can be multiple lines
        result += render_regular_section(summary)  # pyright: ignore[reportArgumentType]
    if extended_summary := parsed["Extended Summary"]:
        result += "\n\n" + render_regular_section(extended_summary)  # pyright: ignore[reportArgumentType]
    for section_title in _PARAMETERS_SECTIONS:
        section = parsed[section_title]
        if not section:
            continue
        if section_title == "Other Parameters" and use_other_params_as_outputs:
            section_title = "Output Files"
        result += f"\n\n# {section_title}\n\n{render_parameter_section(section)}"  # pyright: ignore[reportArgumentType]
    for section_title in _REGULAR_SECTIONS:
        if section := parsed[section_title]:
            result += f"\n\n# {section_title}\n\n{render_regular_section(section)}"  # pyright: ignore[reportArgumentType]
    return result


def replace_output_files_title(doc: str, source: str | None) -> str:
    """
    Replace "Output Files" section name with "Other Parameters", as a parsing hack.

    As a side effect, this means we cannot allow users to use the "Other Parameters"
    section.

    Parameters
    ----------
    doc : str
        The docstring to cleanup.
    source : str
        A string describing the source file, if available. Otherwise '[UNKNOWN]' will be
        printed.

    Returns
    -------
    str : A docstring ready to hand to `numpydoc.docscrape.NumpyDocString`.
    """
    if _OTHER_PARAMETERS.match(doc):
        source = source or "[UNKNOWN]"
        raise ValueError(
            f"Encountered illegal section title 'Other Parameters' when processing source file: {source}\n"
            "At Digital Biology, we do not use this section. Put **all** parameters in the main 'Parameters' section."
        )
    if to_replace := _OUTPUT_SECTION_TITLE.match(doc):
        group_dict = to_replace.groupdict()
        before = group_dict["before"]
        padding = group_dict["padding"]
        after = group_dict["after"]
        doc = f"{before}{padding}Other Parameters\n{padding}----------------\n{after}"
    return doc


class MystNumpyDocHybridParser(MystParser):
    """Hybrid docstring. Use NumpyDoc style, but allow Markdown instead of rST."""

    def parse(self, inputstring: str, document: nodes.document) -> None:
        """
        Parse source text.

        Parameters
        ----------
        inputstring : str
            The docstring to parse. Name intentionally chosen to match internal Sphinx
            usage.
        document : nodes.document
            The root docutils node to add AST elements to.
        """
        inputstring = replace_output_files_title(inputstring, document.source)
        report_errors_in_docstring(inputstring, document)
        inputstring = to_pure_markdown(inputstring, use_other_params_as_outputs=True)
        return super().parse(inputstring, document)


Parser = MystNumpyDocHybridParser
