"""pre-flight-check — fail-fast quality gate for AI coding agents.

The Python package wraps the same engine that ships in
`skills/pre-flight-check/scripts/run-pipeline.py` and provides a CLI
that can deploy the skill into a project for any supported AI tool
(Claude Code, Codex, Gemini CLI, Cursor, Copilot, Windsurf, Cline,
Kiro, Roo Code, Agent Skills standard).

Public API: see :mod:`pre_flight_check.cli`.
"""

from __future__ import annotations

from importlib.metadata import PackageNotFoundError, version

try:
    # Single source of truth is the version in pyproject.toml; read it from
    # the installed distribution metadata so the two can never drift.
    __version__ = version("pre-flight-check")
except PackageNotFoundError:  # running from a source tree, not installed
    __version__ = "0.0.0+dev"

__all__ = ["__version__"]
