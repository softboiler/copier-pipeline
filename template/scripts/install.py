"""Install a Python version.

Uses prebuilt Python distributions from indygreg/python-build-standalone.

Args:
    version (str): Python version to install.

Source: https://github.com/astral-sh/uv/blob/5270624b113d13525ef2e5bef92516915497dc50/scripts/bootstrap/install.py
License: https://github.com/astral-sh/uv/blob/5270624b113d13525ef2e5bef92516915497dc50/LICENSE-MIT
"""

import tarfile
from hashlib import sha256
from json import loads
from pathlib import Path
from platform import machine, system
from shutil import copyfileobj, rmtree
from sys import argv, platform
from sysconfig import get_config_var
from tempfile import TemporaryFile
from urllib.request import urlopen

from zstandard import ZstdDecompressor

BIN = Path("bin")
"""Local project binaries."""
PLAT = platform
"""Current platform."""
VER = argv[1] if len(argv) > 1 else "3.11"
"""Version to install."""
# Retrieve Python versions and metadata from `astral/uv` tooling
_source = "https://raw.githubusercontent.com/astral-sh/uv/5270624b113d13525ef2e5bef92516915497dc50"
with urlopen(f"{_source}/.python-versions") as response:  # noqa: S310
    VERSIONS = response.read().decode("utf-8").splitlines()
with urlopen(f"{_source}/scripts/bootstrap/versions.json") as response:  # noqa: S310
    META = loads(response.read().decode("utf-8"))


def main():  # noqa: D103
    path = BIN / f"python{VER}"
    if not path.exists():
        install(path)
    print(path / ("python.exe" if PLAT == "win32" else "bin/python3"))  # noqa: T201


def install(path: Path):
    """Install Python distribution."""
    key = "-".join([
        "cpython",
        next(v for v in VERSIONS if v.startswith(VER)),
        {"win32": "windows"}.get(PLAT, PLAT),
        {"aarch64": "arm64", "amd64": "x86_64"}.get(arch := machine().lower(), arch),
        get_config_var("SOABI").split("-")[-1] if system() == "Linux" else "none",
    ])
    # Download
    url = META[key]["url"]
    if not url:
        raise ValueError(f"No URL for {key}")
    name = url.split("/")[-1]
    downloaded = BIN / name
    BIN.mkdir(exist_ok=True, parents=True)
    if not downloaded.exists():
        with urlopen(url) as response, downloaded.open("wb") as file:  # noqa: S310
            copyfileobj(response, file)
    if not (sha := META[key]["sha256"]):
        raise ValueError(f"No checksum for {key}")
    if sha256_file(downloaded) != sha:
        raise ValueError(f"Checksum mismatch for {key}")
    # Decompress
    decompressed = BIN / "python"  # `.with_suffix` replaces patch Python version
    if not decompressed.exists():
        decompress(downloaded, BIN)
    # Install
    (decompressed / "install").rename(path)
    rmtree(decompressed)


def decompress(decompressed: Path, output: Path):
    """Decompress Python distribution."""
    if not str(decompressed).endswith(".tar.zst"):
        raise ValueError(f"Unknown archive type {decompressed.suffix}")
    decompressor = ZstdDecompressor()
    with TemporaryFile(suffix=".tar") as out_handle:
        with decompressed.open("rb") as decomp_handle:
            decompressor.copy_stream(decomp_handle, out_handle)
        out_handle.seek(0)
        with tarfile.open(fileobj=out_handle) as tar_handle:
            tar_handle.extractall(output)  # noqa: S202  # pyright: ignore[reportDeprecated]


def sha256_file(path: Path) -> str:
    """SHA256 file."""
    h = sha256()
    with path.open("rb") as file:
        while True:
            # Reading is buffered, so we can read smaller chunks.
            if chunk := file.read(h.block_size):
                h.update(chunk)
            else:
                break
    return h.hexdigest()


if __name__ == "__main__":
    main()
