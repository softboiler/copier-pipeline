"""Startup for IPython and the REPL. Isn't run for notebooks (see `ipythonrc.py`).

Avoid activating Rich features that break functionality outside of the REPL.
"""


def main():

    from rich import inspect, traceback  # type: ignore  # For interactive mode

    traceback.install()

    if not is_notebook_or_ipython():
        from rich import pretty, print  # type: ignore

        pretty.install()


# https://stackoverflow.com/a/39662359
def is_notebook_or_ipython() -> bool:
    try:
        shell = get_ipython().__class__.__name__  # type: ignore  # Dynamic
        return shell == "TerminalInteractiveShell"
    except NameError:
        return False  # Probably standard Python interpreter


main()
