"""Runs after `pythonrc.py` in IPython, and runs alone for Jupyter notebooks.

Avoid activating Rich features that break functionality in notebooks.
"""


def main():
    if is_notebook():
        from rich import inspect, traceback  # type: ignore  # For interactive mode

        traceback.install()


# https://stackoverflow.com/a/39662359
def is_notebook() -> bool:
    try:
        shell = get_ipython().__class__.__name__  # type: ignore  # Dynamic
        return shell == "ZMQInteractiveShell"
    except NameError:
        return False  # Probably standard Python interpreter


main()
