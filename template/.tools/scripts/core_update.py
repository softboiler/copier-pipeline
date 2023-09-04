"""Update script to run after core dependencies are installed, but before others."""

from contextlib import closing
from dataclasses import dataclass
from pathlib import Path
from re import MULTILINE, VERBOSE, Pattern, compile

from dulwich.porcelain import submodule_list
from dulwich.repo import Repo


def main():
    *_, submodule_deps = get_submodules()
    requirements_files = [
        Path("pyproject.toml"),
        *sorted(Path(".tools/requirements").glob("requirements*.txt")),
    ]
    for file in requirements_files:
        original_content = content = file.read_text("utf-8")
        content = sync_paired_dependency(content, "pandas", "pandas-stubs")
        for dep in submodule_deps:
            content = sync_submodule_dependency(content, dep)
        if content != original_content:
            file.write_text(encoding="utf-8", data=content)


@dataclass
class Submodule:
    """Represents a git submodule."""

    _path: str | bytes
    """Submodule path as reported by the submodule source."""
    commit: str
    """Commit hash currently tracked by the submodule."""
    path: Path = Path()
    """Submodule path."""
    name: str = ""
    """Submodule name."""

    def __post_init__(self):
        """Handle byte strings reported by some submodule sources, like dulwich."""
        # dulwich.porcelain.submodule_list returns bytes
        self.path = Path(
            self._path.decode("utf-8") if isinstance(self._path, bytes) else self._path
        )
        self.name = self.path.name


def get_submodules() -> tuple[Submodule, Submodule, list[Submodule]]:
    """Get the special template and typings submodules, as well as the rest."""
    with closing(repo := Repo(str(Path.cwd()))):
        all_submodules = [Submodule(*item) for item in list(submodule_list(repo))]
    submodules: list[Submodule] = []
    template = typings = None
    for submodule in all_submodules:
        if submodule.name == "template":
            template = submodule
        elif submodule.name == "typings":
            typings = submodule
        else:
            submodules.append(submodule)
    if not template or not typings:
        raise ValueError("Could not find one of the template or typings submodules.")
    return template, typings, submodules


def sync_paired_dependency(content: str, src_name: str, dst_name: str) -> str:
    """Synchronize paired dependencies.

    Synchronize the `dst` dependency version from the `src` dependency version. This
    allows for certain complicated dependency relationships to be maintained, such as
    the one between `pandas` and `pandas-stubs`, in which `pandas-stubs` first three
    version numbers should match those of releases of `pandas`.
    """
    if match := dependency(src_name).search(content):
        return dependency(dst_name).sub(
            repl=rf"\g<pre>{dst_name}\g<detail>{match['version']}\g<post>",
            string=content,
        )
    else:
        return content


def dependency(name: str) -> Pattern[str]:
    """Pattern for a dependency in 'requirements.txt' or 'pyproject.toml'."""
    return compile_dependency(
        rf"""
        {name}               # The dependency name
        (?P<detail>          # e.g. `~=` or `[hdf5,performance]~=`
            (\[[^\]]*\])?       # e.g. [hdf5,performance] (optional)
            [=~><]=             # ==, ~=, >=, <=
        )
        (?P<version>[^\n]+)  # e.g. 2.0.2
        """
    )


def sync_submodule_dependency(content: str, sub: Submodule) -> str:
    """Synchronize commit-pinned dependencies to their respective submodule commit."""
    return commit_dependency(sub.name, "https://github.com").sub(
        repl=rf"\g<before_commit>{sub.commit}\g<post>", string=content
    )


def commit_dependency(name: str, url: str) -> Pattern[str]:
    """Pattern for a commit-pinned dep in 'requirements.txt' or 'pyproject.toml'."""
    return compile_dependency(
        rf"""
        (?P<before_commit>      # Everything up to the commit hash
            {name}@git\+{url}/      # e.g. name@git+https://github.com/
            (?P<org>[^/]+/)         # org/
            {name}@                 # name@
        )
        (?P<commit>[^\n]+)      # <commit-hash>
        """
    )


def compile_dependency(pattern: str) -> Pattern[str]:
    """Compile a regex pattern for dependencies in verbose, multiline mode.

    Supports specifications in both `pyproject.toml` and `requirements.txt`.
    """
    return compile(
        pattern=(
            rf"""
            ^                   # Start of line
            (?P<pre>\s*['"])?   # `"` if in pyproject.toml
            {pattern}
            (?P<post>\s*['"])?  # `",` if in pyproject.toml
            $                   # End of line
            """
        ),
        flags=VERBOSE | MULTILINE,
    )


if __name__ == "__main__":
    main()
