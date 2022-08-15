"""Startup for IPython and the REPL. Isn't run for notebooks (see `ipythonrc.py`).

Avoid activating Rich features that break functionality outside of the REPL.
"""


def main():

    from rich import inspect, traceback

    traceback.install()

    if not is_notebook_or_ipython():
        from rich import pretty, print

        pretty.install()


# https://stackoverflow.com/a/39662359
def is_notebook_or_ipython() -> bool:
    try:
        shell = get_ipython().__class__.__name__  # pyright: ignore
        return shell == "TerminalInteractiveShell"
    except NameError:
        return False  # Probably standard Python interpreter


main()
