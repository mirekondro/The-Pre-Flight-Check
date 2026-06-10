"""Thin wrapper that runs the bundled pipeline engine.

The canonical engine source is ``skills/pre-flight-check/scripts/run-pipeline.py``
in the repo. At build time (hatch), it gets copied into
``pre_flight_check/_data/run-pipeline.py``. This module locates that bundled
copy and executes it as a subprocess in the user's current working directory —
preserving the engine's `Path.cwd()` runtime detection logic.
"""

from __future__ import annotations

import subprocess
import sys
from importlib import resources
from pathlib import Path


def script_path() -> Path:
    """Return the filesystem path of the bundled run-pipeline.py."""
    pkg = __package__ or "pre_flight_check"
    files = resources.files(pkg).joinpath("_data").joinpath("run-pipeline.py")
    # `as_file` materialises the resource to disk if it's inside a zip; on a
    # regular wheel install it's a real path already.
    with resources.as_file(files) as fp:
        return Path(fp)


def run() -> int:
    """Execute the bundled engine. Returns its exit code."""
    script = script_path()
    if not script.is_file():
        sys.stderr.write(
            f"pre-flight-check: bundled engine not found at {script}\n"
            "This indicates a broken installation — reinstall with "
            "`pipx install --force pre-flight-check`.\n"
        )
        return 2
    completed = subprocess.run([sys.executable, str(script)], check=False)
    return completed.returncode
