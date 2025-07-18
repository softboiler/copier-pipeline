"""Notebook namespaces."""

import ast
from ast import NodeVisitor
from collections import defaultdict
from functools import partial
from inspect import getsource
from textwrap import dedent
from types import SimpleNamespace

from cachier import cachier  # pyright: ignore[reportMissingImports]
from nbformat import NO_CONVERT, reads
from ploomber_engine._util import parametrize_notebook
from ploomber_engine.ipython import PloomberClient

from pipeline_helper.hashes import hash_args
from pipeline_helper.types import Attributes, Params, SimpleNamespaceReceiver

NO_ATTRS = []
NO_PARAMS = {}


def get_ns_attrs(receiver: SimpleNamespaceReceiver) -> list[str]:
    """Get the list of attribute accesses in the `ns` namespace in the receiver."""
    attributes = AccessedAttributesVisitor()
    attributes.visit(ast.parse(dedent(getsource(receiver))))
    return list(attributes.names["ns"])


def get_nb_ns(
    nb: str, params: Params = NO_PARAMS, attributes: Attributes = NO_ATTRS
) -> SimpleNamespace:
    """Get notebook namespace, optionally parametrizing or limiting returned attributes.

    Args:
        nb: Notebook contents as text.
        params: Parameters to inject below the first `parameters`-tagged code cell.
        attributes: If given, limit the notebook attributes to return in the namespace.

    Returns
    -------
        Notebook namespace.

    Example:
        ```Python
        ns = get_nb_ns(
            nb=Path("notebook.ipynb").read_text(encoding="utf-8"),
            params={"some_parameter": 3, "other_parameter": [0, 1]},
            attributes=["results", "other_attribute_to_return"],
        )
        ```
    """
    nb_client = get_nb_client(nb)
    # We can't just `nb_client.execute(params=...)` since`nb_client.get_namespace()`
    # would execute all over again
    if params:
        parametrize_notebook(nb_client._nb, parameters=params)  # noqa: SLF001
    namespace = nb_client.get_namespace()
    return SimpleNamespace(
        **(
            {
                attr: namespace[attr]
                for attr in attributes
                if namespace.get(attr) is not None
            }
            if attributes
            else namespace
        )
    )


@cachier(hash_func=partial(hash_args, get_nb_ns))
def get_cached_nb_ns(
    nb: str, params: Params = NO_PARAMS, attributes=NO_ATTRS
) -> SimpleNamespace:
    """Get cached notebook namespace, optionally parametrizing or limiting attributes.

    This caches the return values and avoids execution if the hash of input argument
    values matches an earlier call.

    Args:
        nb: Notebook contents as text.
        params: Parameters to inject below the first `parameters`-tagged code cell.
        attributes: If given, limit the notebook attributes to return in the namespace.

    Returns
    -------
        Notebook namespace.

    Example:
        ```Python
        ns = get_cached_nb_ns(
            nb=Path("notebook.ipynb").read_text(encoding="utf-8"),
            params={"some_parameter": 3, "other_parameter": [0, 1]},
            attributes=["results", "other_attribute_to_return"],
        )
        ```
    """
    return get_nb_ns(nb, params, attributes)


def get_nb_client(nb: str) -> PloomberClient:
    """Get notebook client."""
    return PloomberClient(reads(nb, as_version=NO_CONVERT))


class AccessedAttributesVisitor(NodeVisitor):
    """Map accessed attributes to their namespaces."""

    def __init__(self):
        self.names: dict[str, set[str]] = defaultdict(set)

    def visit_Attribute(self, node: ast.Attribute):  # noqa: N802
        if isinstance(node.value, ast.Name) and not node.attr.startswith("__"):
            self.names[node.value.id].add(node.attr)
        self.generic_visit(node)
