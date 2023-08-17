"""Warning filters and `.env` updater."""

from pathlib import Path
from warnings import filterwarnings


def filter_warnings_and_update_dotenv():
    """Filter warnings and update PYTHONWARNINGS in `.env` file."""
    filters: list[str] = []
    for filt in FILTERS:
        # Filter warnings before modifying for writing to `.env`
        filterwarnings(*filt)  # type: ignore  # pyright 1.1.317
        # Since `.env` files don't support regex matching, un-escape slashes and
        # truncate after the first `.*`.
        if len(filt) > (msg_pos := 1):
            msg = filt[msg_pos].replace("\\", "")  # type: ignore  # pyright 1.1.317
            for splittable in [",", ".*", "=", "'", '"']:
                msg = msg.split(splittable)[0]
            filt[msg_pos] = msg
        # Convert classes to string representations of their names
        if len(filt) > (warn_pos := 2):
            filt[warn_pos] = filt[warn_pos].__name__  # type: ignore  # pyright 1.1.317
        # Join filter parts with colons, as expected in `.env` files
        filters.append(":".join(str(f) for f in filt))
    # ! Truncate `.env` after notice and insert filters
    dotenv = Path(".env")
    content = dotenv.read_text(encoding="utf-8")
    notice = "# ! Don't edit below. `warning_filters.py` may trash any changes."
    loc = content.find(notice)  # Returns -1 if not found
    insert_point = len(content) if loc == -1 else loc
    content = f"{content[:insert_point]}{notice}\nPYTHONWARNINGS={','.join(filters)}\n"
    dotenv.write_text(encoding="utf-8", data=content)


FILTERS = (
    # Warn for all warnings, even `DeprecationWarning`
    ["default"],
    *(
        ["ignore", *w]
        for w in (
            # pkg_resources: https://github.com/blakeNaccarato/copier-python/issues/319#issue-1609228740
            (
                "Deprecated call to `pkg_resources.declare_namespace",
                DeprecationWarning,
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
            ),
            (
                "lib2to3 package is deprecated and may not be able to parse Python",
                DeprecationWarning,
            ),
            # ImportDenier:ImportWarning: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1546359005
            (
                "ImportDenier",
                ImportWarning,
            ),
            # numpy.ndarray size changed:RuntimeWarning: https://github.com/blakeNaccarato/copier-python/issues/319#issuecomment-1546360423
            (
                r"numpy.ndarray size changed",
                RuntimeWarning,
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
            ),
            (
                r"unclosed file <_io\.BufferedReader name='.*'>",
                ResourceWarning,
            ),
            # ! NOT LINKED
            (
                (
                    "subpackages can technically be lazily loaded, but it causes the "
                    "package to be eagerly loaded even if it is already lazily loaded."
                    "So, you probably shouldn't use subpackages with this lazy feature."
                ),
                RuntimeWarning,
            ),
            (
                "invalid escape sequence",
                DeprecationWarning,
                "sparklines.sparklines",
            ),
        )
    ),
)

if __name__ == "__main__":
    filter_warnings_and_update_dotenv()
