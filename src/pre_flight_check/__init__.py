"""pre-flight-check — fail-fast quality gate for AI coding agents.

The Python package wraps the same engine that ships in
`skills/pre-flight-check/scripts/run-pipeline.py` and provides a CLI
that can deploy the skill into a project for any supported AI tool
(Claude Code, Codex, Gemini CLI, Cursor, Copilot, Windsurf, Cline,
Kiro, Roo Code, Agent Skills standard).

Public API: see :mod:`pre_flight_check.cli`.
"""

from __future__ import annotations

__version__ = "1.2.0"
__all__ = ["__version__"]
