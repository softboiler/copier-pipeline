"""Startup for Python.

Avoid activating Rich features that break functionality outside of the REPL.
"""


def main():
    from rich import inspect, traceback  # noqa: F401  # pyright: ignore

    traceback.install()

    if not is_notebook_or_ipython():
        from rich import pretty, print  # noqa: F401  # pyright: ignore

        pretty.install()


# https://stackoverflow.com/a/39662359
def is_notebook_or_ipython() -> bool:
    try:
        shell = get_ipython().__class__.__name__  # pyright: ignore  # Dynamic
    except NameError:
        return False  # Probably standard Python interpreter
    else:
        return shell == "TerminalInteractiveShell"


main()
