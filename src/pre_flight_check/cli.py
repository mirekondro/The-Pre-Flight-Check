"""argparse CLI for the ``pre-flight-check`` console script.

Subcommands:
  run          Execute the bundled pipeline engine against the current dir.
  init         Deploy the skill / adapter file for one or more AI tools.
  list-tools   Print the supported AI tools table.
  uninstall    Remove a deployed install for one or more AI tools.
  version      Print the package version and exit.
"""

from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path
from typing import List, Optional


from . import __version__
from .engine import run as engine_run
from .installer import (
    SUPPORTED_TOOLS,
    install_tool,
    resolve_target,
    uninstall_tool,
)


def _ensure_utf8_stdout() -> None:
    """Re-wrap stdout/stderr as UTF-8 on Windows where cp1252 is the default.

    Lets us print ✓ and ✗ without UnicodeEncodeError on any active code page.
    errors='replace' ensures we never crash on exotic chars.
    """
    for stream_name in ("stdout", "stderr"):
        stream = getattr(sys, stream_name)
        enc = getattr(stream, "encoding", "utf-8") or "utf-8"
        if hasattr(stream, "buffer") and enc.lower().replace("-", "") not in ("utf8", "utf8sig"):
            setattr(
                sys,
                stream_name,
                io.TextIOWrapper(stream.buffer, encoding="utf-8", errors="replace"),
            )


_TOOL_DESCRIPTIONS = {
    "claude":        ("Claude Code",            "~/.claude/skills/  or  .claude/skills/"),
    "codex":         ("OpenAI Codex / AGENTS",  "AGENTS.md at repo root"),
    "gemini":        ("Gemini CLI",             "GEMINI.md + gemini-extension.json at repo root"),
    "cursor":        ("Cursor",                 ".cursor/rules/pre-flight-check.mdc"),
    "copilot":       ("GitHub Copilot",         ".github/copilot-instructions.md"),
    "windsurf":      ("Windsurf",               ".windsurf/rules/pre-flight-check.md"),
    "cline":         ("Cline",                  ".clinerules/pre-flight-check.md"),
    "kiro":          ("Kiro",                   ".kiro/steering/pre-flight-check.md"),
    "roo":           ("Roo Code",               ".roo/rules/pre-flight-check.md"),
    "agents-skills": ("Agent Skills standard",  ".agents/skills/pre-flight-check/"),
}


def _print_tools_table() -> None:
    print("Supported AI tools (--tool):\n")
    for name in SUPPORTED_TOOLS:
        label, dest = _TOOL_DESCRIPTIONS[name]
        print(f"  {name:<14}  {label:<22}  ->  {dest}")
    print("\n  all             Install for every supported tool above.")
    print("\nEngine path:")
    print("  Claude:       .claude/skills/pre-flight-check/scripts/run-pipeline.py")
    print("  agents-skills: .agents/skills/pre-flight-check/scripts/run-pipeline.py")
    print("  All others:   .pre-flight-check/scripts/run-pipeline.py")


def _expand_tool(tool: str) -> List[str]:
    if tool == "all":
        return list(SUPPORTED_TOOLS)
    if tool not in SUPPORTED_TOOLS:
        sys.exit(f"pre-flight-check: unknown tool '{tool}' (try `pre-flight-check list-tools`)")
    return [tool]


def _resolve_scope(args: argparse.Namespace, tool: str) -> Path:
    if args.dir:
        return resolve_target("custom", Path(args.dir))
    if args.global_scope:
        if tool != "claude":
            sys.exit(
                f"pre-flight-check: --global is only supported for --tool claude. "
                f"Use --project or --dir for {tool}."
            )
        return resolve_target("global")
    # Default: Claude → global; others → project. Matches install.sh behaviour.
    if tool == "claude" and not args.project:
        return resolve_target("global")
    return resolve_target("project")


# ---------- subcommand handlers ----------

_STAGE_CHOICES = ["typecheck", "lint", "test", "audit"]


def _stage_args(args: argparse.Namespace) -> List[str]:
    """Translate --only / --skip on the namespace into engine CLI args."""
    out: List[str] = []
    only = getattr(args, "only", None)
    skip = getattr(args, "skip", None)
    if only:
        out += ["--only", *only]
    if skip:
        out += ["--skip", *skip]
    return out


def _cmd_run(args: argparse.Namespace) -> int:
    return engine_run(_stage_args(args))


def _cmd_doctor(args: argparse.Namespace) -> int:
    """Preview the runtime + stages that would run, without executing them."""
    return engine_run(["--plan", *_stage_args(args)])


def _cmd_list_tools(_: argparse.Namespace) -> int:
    _print_tools_table()
    return 0


def _cmd_version(_: argparse.Namespace) -> int:
    print(f"pre-flight-check {__version__}")
    return 0


def _cmd_init(args: argparse.Namespace) -> int:
    tools = _expand_tool(args.tool)
    written_total: List[Path] = []
    for tool in tools:
        target = _resolve_scope(args, tool)
        try:
            written = install_tool(tool, target, force=args.force)
        except FileExistsError as e:
            sys.stderr.write(f"✗  {e}\n")
            return 1
        written_total.extend(written)
        print(f"✓  Installed for {tool} ({len(written)} file(s)) -> {target}")
    print()
    print(f"Done. {len(written_total)} file(s) written across {len(tools)} tool(s).")
    return 0


def _cmd_uninstall(args: argparse.Namespace) -> int:
    tools = _expand_tool(args.tool)
    removed_total = 0
    for tool in tools:
        target = _resolve_scope(args, tool)
        removed = uninstall_tool(tool, target)
        if removed:
            print(f"✓  Removed {len(removed)} file(s) for {tool} from {target}")
            removed_total += len(removed)
        else:
            print(f"!  Nothing to remove for {tool} at {target}")
    print()
    print(f"Done. {removed_total} file(s) removed.")
    return 0


# ---------- argparse wiring ----------

def _add_stage_flags(p: argparse.ArgumentParser) -> None:
    g = p.add_mutually_exclusive_group()
    g.add_argument("--only", nargs="+", metavar="STAGE", choices=_STAGE_CHOICES,
                   help="Run only these stages: typecheck, lint, test, audit.")
    g.add_argument("--skip", nargs="+", metavar="STAGE", choices=_STAGE_CHOICES,
                   help="Run every stage except these.")


def _add_scope_flags(p: argparse.ArgumentParser) -> None:
    p.add_argument("--tool", default="claude",
                   help="AI tool to target (default: claude). Use 'all' for every supported tool.")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--global", dest="global_scope", action="store_true",
                   help="Install Claude globally to ~/.claude/skills/. Claude-only.")
    g.add_argument("--project", action="store_true",
                   help="Install into the current directory (default for non-Claude tools).")
    g.add_argument("--dir", metavar="PATH",
                   help="Install into a custom project root.")
    p.add_argument("--force", action="store_true",
                   help="Overwrite existing files without prompting.")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="pre-flight-check",
        description=(
            "Fail-fast quality gate for AI coding agents. "
            "Auto-detects Node.js and Python projects; runs Typecheck → Lint → "
            "Test → Security Audit sequentially and halts on the first failure."
        ),
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    sub = parser.add_subparsers(dest="cmd")

    p_run = sub.add_parser("run", help="Run the pipeline engine against the current directory.")
    _add_stage_flags(p_run)
    p_run.set_defaults(func=_cmd_run)

    p_doctor = sub.add_parser(
        "doctor",
        help="Preview the runtime and stages that would run (no execution).",
    )
    _add_stage_flags(p_doctor)
    p_doctor.set_defaults(func=_cmd_doctor)

    p_init = sub.add_parser("init", help="Deploy the skill / adapter file for one or more AI tools.")
    _add_scope_flags(p_init)
    p_init.set_defaults(func=_cmd_init)

    p_uninstall = sub.add_parser("uninstall", help="Remove a deployed install for one or more AI tools.")
    _add_scope_flags(p_uninstall)
    p_uninstall.set_defaults(func=_cmd_uninstall)

    p_list = sub.add_parser("list-tools", help="Print the supported AI tools table.")
    p_list.set_defaults(func=_cmd_list_tools)

    p_ver = sub.add_parser("version", help="Print the package version and exit.")
    p_ver.set_defaults(func=_cmd_version)

    return parser


def main(argv: Optional[List[str]] = None) -> int:
    _ensure_utf8_stdout()
    parser = _build_parser()
    args = parser.parse_args(argv)
    if not getattr(args, "func", None):
        # No subcommand → behave like `run` for the most common use case.
        return _cmd_run(args)
    return args.func(args)  # type: ignore[no-any-return]
