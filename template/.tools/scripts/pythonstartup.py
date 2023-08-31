"""Startup for Python.

Avoid activating Rich features that break functionality outside of the REPL.
"""

from collections.abc import Sequence
from contextlib import contextmanager
from typing import Literal, NamedTuple
from warnings import catch_warnings, filterwarnings


def init():
    filterwarnings("error")
    filter_certain_warnings(ALL_WARNINGS)

    from rich import inspect, traceback  # noqa: F401

    traceback.install()

    if not is_notebook_or_ipython():
        from rich import pretty, print  # noqa: F401

        pretty.install()


# https://stackoverflow.com/a/39662359
def is_notebook_or_ipython() -> bool:
    try:
        shell = get_ipython().__class__.__name__  # type: ignore  # pyright 1.1.308, dynamic
    except NameError:
        return False  # Probably standard Python interpreter
    else:
        return shell == "TerminalInteractiveShell"


class WarningFilter(NamedTuple):
    """A warning filter, e.g. to be unpacked into `warnings.filterwarnings`."""

    action: Literal["default", "error", "ignore", "always", "module", "once"] = "ignore"
    message: str = ""
    category: type[Warning] = Warning
    module: str = ""
    lineno: int = 0
    append: bool = False


@contextmanager
def catch_certain_warnings(warnings: Sequence[WarningFilter]):
    """Catch certain warnings."""
    with catch_warnings() as context:
        filter_certain_warnings(warnings)
        yield context


def filter_certain_warnings(warnings: Sequence[WarningFilter]):
    """Filter certain warnings."""
    for filt in warnings:
        filterwarnings(*filt)


ENCODING_WARNINGS = [
    *(
        WarningFilter(
            message=r"'encoding' argument not specified",
            category=(category := EncodingWarning),
            module=module,
        )
        for module in (
            *(
                f"copier.{submodule}"
                for submodule in (
                    "subproject",
                    "template",
                )
            ),
            "cv2.load_config_py3",
            "dask.config",
            "dill._dill",
            "dvc_objects.fs.local",
            "fawltydeps.extract_imports",
            "fsspec.spec",
            "matplotlib.font_manager",
            "ploomber_core.config",
            "pyvisa.util",
            "ruamel.yaml.main",
            "sqltrie.sqlite.sqlite",
            "zc.lockfile",
        )
    ),
    *(
        WarningFilter(
            message=r"UTF-8 Mode affects locale\.getpreferredencoding\(\)\. Consider locale\.getencoding\(\) instead\.",
            category=category,
            module=module,
        )
        for module in ("dill.logger", "scmrepo.git.backend.pygit2")
    ),
]
"""Encoding warnings."""

OTHER_WARNINGS = (
    # Warn for all warnings, even `DeprecationWarning`
    *(
        WarningFilter(
            message=message,
            category=category,
            module=module,
        )
        for message, category, module in (
            # pkg_resources: https://github.com/blakeNaccarato/copier-python/issues/319#issue-1609228740
            (
                "Deprecated call to `pkg_resources.declare_namespace",
                DeprecationWarning,
                "",
            ),
            # Creating a LegacyVersion: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1454209165
            (
                "Creating a LegacyVersion has been deprecated and will be removed in the next major release",
                DeprecationWarning,
                "pip._vendor.packaging.version",
            ),
            # pre_commit read_text and open_text: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1455177114
            (
                "read_text is deprecated",
                DeprecationWarning,
                "pre_commit.util",
            ),
            (
                "open_text is deprecated",
                DeprecationWarning,
                "importlib.resources._legacy",
            ),
            # imp module and ABCs: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1455183241
            (
                "the imp module is deprecated in favour of importlib",
                DeprecationWarning,
                "googlecloudsdk.core.util.importing",
            ),
            (
                "Using or importing the ABCs",
                DeprecationWarning,
                "jsonschema.compat",
            ),
            # dpath...pkg_resources: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1457219723
            (
                "The dpath.util package is being deprecated.",
                DeprecationWarning,
                "dvc.dependency.param",
            ),
            # unclosed file...plumbum: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1458742412
            (
                "unclosed file",
                ResourceWarning,
                "dvc.stage.cache",
            ),
            (
                "the imp module is deprecated",
                DeprecationWarning,
                "ansiwrap.core",
            ),
            (
                "unclosed file",
                ResourceWarning,
                "ansiwrap.core",
            ),
            (
                "Jupyter is migrating its paths to use standard platformdirs",
                DeprecationWarning,
                "jupyter_client.connect",
            ),
            (
                "the file is not specified with any extension",
                UserWarning,
                "papermill.iorw",
            ),
            (
                "Passing unrecognized arguments to super",
                DeprecationWarning,
                "traitlets.config.configurable",
            ),
            (
                "pkg_resources is deprecated as an API",
                DeprecationWarning,
                "",
            ),
            (
                "unclosed file",
                ResourceWarning,
                "plumbum.commands.base",
            ),
            # ? NOT DOCUMENTED
            (
                "Passing unrecognized arguments to super",
                DeprecationWarning,
                "ipywidgets.widgets.widget",
            ),
            # ? NOT DOCUMENTED
            (
                "`ipykernel.pylab.backend_inline` is deprecated",
                DeprecationWarning,
                "ipykernel.pylab.backend_inline",
            ),
            # ? NOT DOCUMENTED
            (
                "subprocess",
                ResourceWarning,
                "subprocess",
            ),
            # BuiltinImporter.module_repr:DeprecationWarning:importlib._bootstrap: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1493542865
            (
                "BuiltinImporter.module_repr",
                DeprecationWarning,
                "importlib._bootstrap",
            ),
            # lib2to3: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1502112446
            (
                "lib2to3 package is deprecated and may not be able to parse Python",
                PendingDeprecationWarning,
                "",
            ),
            (
                "lib2to3 package is deprecated and may not be able to parse Python",
                DeprecationWarning,
                "",
            ),
            # ImportDenier:ImportWarning: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1546359005
            (
                "ImportDenier",
                ImportWarning,
                "",
            ),
            # numpy.ndarray size changed:RuntimeWarning: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1546360423
            (
                r"numpy.ndarray size changed",
                RuntimeWarning,
                "",
            ),
            # :DeprecationWarning:sphinx.util.images...sphinx_book_theme: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1591786172
            (
                "",
                DeprecationWarning,
                "sphinx.util.images",
            ),
            # ? NOT DOCUMENTED
            (
                "",
                DeprecationWarning,
                "myst_nb.sphinx_ext",
            ),
            # ? NOT DOCUMENTED
            (
                "",
                DeprecationWarning,
                "myst_parser.mdit_to_docutils.base",
            ),
            # ? NOT DOCUMENTED
            (
                "",
                DeprecationWarning,
                "optparse",
            ),
            # ? NOT DOCUMENTED
            (
                "Proactor event loop",
                RuntimeWarning,
                "zmq._future",
            ),
            # ? NOT DOCUMENTED
            (
                "",
                PendingDeprecationWarning,
                "myst_nb.ext.execution_tables",
            ),
            # ? NOT DOCUMENTED
            (
                "",
                PendingDeprecationWarning,
                "sphinx_book_theme",
            ),
            # trackpy: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1615198787
            (
                "Please use `binary_dilation`",
                DeprecationWarning,
                "trackpy.uncertainty",
            ),
            (
                "Importing clear_output from IPython.core.display is deprecated",
                DeprecationWarning,
                "trackpy.utils",
            ),
            # VSCode debugging: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1644830915
            (
                r"distutils Version classes are deprecated\. Use packaging\.version instead\.",
                DeprecationWarning,
                "",
            ),
            (
                r"unclosed file <_io\.BufferedReader name='.*'>",
                ResourceWarning,
                "",
            ),
            # ! NOT LINKED
            (
                (
                    "subpackages can technically be lazily loaded, but it causes the "
                    "package to be eagerly loaded even if it is already lazily loaded."
                    "So, you probably shouldn't use subpackages with this lazy feature."
                ),
                RuntimeWarning,
                "",
            ),
            (
                "invalid escape sequence",
                DeprecationWarning,
                "sparklines.sparklines",
            ),
        )
    ),
)

ALL_WARNINGS = [*ENCODING_WARNINGS, *OTHER_WARNINGS]

init()
