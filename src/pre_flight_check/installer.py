"""Deploy / remove pre-flight-check adapter files for any supported AI tool.

This is a Python port of ``install.sh`` and ``install.ps1``. It reads the
adapter files bundled inside the package (via ``importlib.resources``) and
writes them into the target project tree at the path each AI tool expects.
"""

from __future__ import annotations

import os
from importlib import resources
from pathlib import Path
from typing import Dict, List, NamedTuple

SUPPORTED_TOOLS: List[str] = [
    "claude", "codex", "gemini", "cursor", "copilot",
    "windsurf", "cline", "kiro", "roo", "agents-skills",
]


class FileMap(NamedTuple):
    """A single file deployment: source within _data, destination relative to target_dir."""

    src_data_name: str
    dest_rel: str


# Per-tool adapter file plans (excluding the engine script, which is handled separately).
_ADAPTER_PLANS: Dict[str, List[FileMap]] = {
    "claude": [
        FileMap("SKILL.md", ".claude/skills/pre-flight-check/SKILL.md"),
    ],
    "codex": [
        FileMap("AGENTS.md", "AGENTS.md"),
    ],
    "gemini": [
        FileMap("GEMINI.md", "GEMINI.md"),
        FileMap("gemini-extension.json", "gemini-extension.json"),
    ],
    "cursor": [
        FileMap("cursor.mdc", ".cursor/rules/pre-flight-check.mdc"),
    ],
    "copilot": [
        FileMap("copilot-instructions.md", ".github/copilot-instructions.md"),
    ],
    "windsurf": [
        FileMap("windsurf.md", ".windsurf/rules/pre-flight-check.md"),
    ],
    "cline": [
        FileMap("cline.md", ".clinerules/pre-flight-check.md"),
    ],
    "kiro": [
        FileMap("kiro.md", ".kiro/steering/pre-flight-check.md"),
    ],
    "roo": [
        FileMap("roo.md", ".roo/rules/pre-flight-check.md"),
    ],
    "agents-skills": [
        FileMap("SKILL.md", ".agents/skills/pre-flight-check/SKILL.md"),
    ],
}


def script_dest_rel(tool: str) -> str:
    """Where the pipeline engine ends up for a given tool, relative to target_dir."""
    if tool == "claude":
        return ".claude/skills/pre-flight-check/scripts/run-pipeline.py"
    if tool == "agents-skills":
        return ".agents/skills/pre-flight-check/scripts/run-pipeline.py"
    return ".pre-flight-check/scripts/run-pipeline.py"


def adapter_paths(tool: str, target_dir: Path) -> List[Path]:
    """Absolute paths the tool will touch (excluding the engine script)."""
    if tool not in _ADAPTER_PLANS:
        raise ValueError(f"unknown tool: {tool}")
    return [target_dir / fm.dest_rel for fm in _ADAPTER_PLANS[tool]]


def _read_data(name: str) -> bytes:
    """Read a file from the bundled _data/ directory."""
    payload = resources.files("pre_flight_check._data").joinpath(name).read_bytes()
    return bytes(payload)


def _write_file(dest: Path, payload: bytes, executable: bool = False) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(payload)
    if executable:
        # chmod +x on POSIX; on Windows this is a no-op.
        mode = dest.stat().st_mode
        dest.chmod(mode | 0o111)


def install_tool(tool: str, target_dir: Path, force: bool = False) -> List[Path]:
    """Deploy adapter + engine for one tool. Returns the list of written paths.

    Raises FileExistsError if a target exists and force=False.
    """
    if tool not in _ADAPTER_PLANS:
        raise ValueError(f"unknown tool: {tool}")

    plan = _ADAPTER_PLANS[tool]
    script_dest = target_dir / script_dest_rel(tool)
    candidates = [target_dir / fm.dest_rel for fm in plan] + [script_dest]
    if not force:
        existing = [p for p in candidates if p.exists()]
        if existing:
            joined = ", ".join(str(p) for p in existing)
            raise FileExistsError(
                f"refusing to overwrite (pass force=True to override): {joined}"
            )

    written: List[Path] = []
    for fm in plan:
        payload = _read_data(fm.src_data_name)
        dest = target_dir / fm.dest_rel
        _write_file(dest, payload, executable=False)
        written.append(dest)

    # Always deploy the engine.
    payload = _read_data("run-pipeline.py")
    _write_file(script_dest, payload, executable=True)
    written.append(script_dest)

    return written


def uninstall_tool(tool: str, target_dir: Path) -> List[Path]:
    """Remove adapter + engine for one tool. Returns the list of removed paths.

    Missing files are not an error. Empty parent directories we created are
    pruned best-effort.
    """
    if tool not in _ADAPTER_PLANS:
        raise ValueError(f"unknown tool: {tool}")

    removed: List[Path] = []
    for fm in _ADAPTER_PLANS[tool]:
        p = target_dir / fm.dest_rel
        if p.exists():
            p.unlink()
            removed.append(p)
    script = target_dir / script_dest_rel(tool)
    if script.exists():
        script.unlink()
        removed.append(script)

    # Best-effort prune of empty parents — same dirs the installer created.
    pruning_candidates = {
        "claude": [".claude/skills/pre-flight-check/scripts", ".claude/skills/pre-flight-check", ".claude/skills", ".claude"],
        "cursor": [".cursor/rules", ".cursor"],
        "windsurf": [".windsurf/rules", ".windsurf"],
        "cline": [".clinerules"],
        "kiro": [".kiro/steering", ".kiro"],
        "roo": [".roo/rules", ".roo"],
        "agents-skills": [".agents/skills/pre-flight-check/scripts", ".agents/skills/pre-flight-check", ".agents/skills", ".agents"],
    }
    if tool not in {"claude", "agents-skills"}:
        pruning_candidates.setdefault(tool, []).extend([".pre-flight-check/scripts", ".pre-flight-check"])
    for rel in pruning_candidates.get(tool, []):
        d = target_dir / rel
        try:
            d.rmdir()  # only succeeds if empty
        except OSError:
            pass

    return removed


def resolve_target(scope: str, custom_dir: Path | None = None) -> Path:
    """Compute the target_dir for a given scope."""
    if scope == "global":
        return Path(os.path.expanduser("~"))
    if scope == "custom":
        if custom_dir is None:
            raise ValueError("custom scope requires custom_dir")
        return custom_dir.resolve()
    return Path.cwd()
