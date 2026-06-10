#!/usr/bin/env python3
"""Pre-Flight Check pipeline engine.

Auto-detects runtime (Node.js / Python), runs sequential fail-fast quality
gates (typecheck -> lint -> test -> security audit), and emits Markdown
output structured for LLM consumption.

Vanilla Python 3, no third-party deps.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


MAX_CONTEXT_CHARS = 4000


def which(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def file_exists(cwd: Path, name: str) -> bool:
    return (cwd / name).is_file()


def detect_node_pm(cwd: Path) -> str:
    """Pick package manager based on lockfile, then availability."""
    if file_exists(cwd, "pnpm-lock.yaml") and which("pnpm"):
        return "pnpm"
    if file_exists(cwd, "yarn.lock") and which("yarn"):
        return "yarn"
    if file_exists(cwd, "package-lock.json") and which("npm"):
        return "npm"
    for pm in ("pnpm", "yarn", "npm"):
        if which(pm):
            return pm
    return "npm"


def package_json_scripts(cwd: Path) -> dict:
    pj = cwd / "package.json"
    if not pj.is_file():
        return {}
    try:
        with pj.open("r", encoding="utf-8") as f:
            data = json.load(f)
        scripts = data.get("scripts") or {}
        return scripts if isinstance(scripts, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}


def has_dep(cwd: Path, dep: str) -> bool:
    pj = cwd / "package.json"
    if not pj.is_file():
        return False
    try:
        with pj.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return False
    for key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        block = data.get(key) or {}
        if isinstance(block, dict) and dep in block:
            return True
    return False


def pm_run(pm: str, script: str) -> list[str]:
    """Build a 'run <script>' command for the chosen package manager."""
    if pm == "npm":
        return ["npm", "run", script, "--if-present"]
    if pm == "yarn":
        return ["yarn", "run", script]
    return ["pnpm", "run", script]


def pm_exec(pm: str, binary: str, *args: str) -> list[str]:
    """Run a locally-installed binary via the package manager."""
    if pm == "npm":
        return ["npx", "--no-install", binary, *args]
    if pm == "yarn":
        return ["yarn", binary, *args]
    return ["pnpm", "exec", binary, *args]


def build_node_stages(cwd: Path) -> list[dict]:
    pm = detect_node_pm(cwd)
    scripts = package_json_scripts(cwd)
    stages: list[dict] = []

    # Typecheck
    if "typecheck" in scripts:
        stages.append({"name": "TYPECHECK", "cmd": pm_run(pm, "typecheck")})
    elif "type-check" in scripts:
        stages.append({"name": "TYPECHECK", "cmd": pm_run(pm, "type-check")})
    elif has_dep(cwd, "typescript") or file_exists(cwd, "tsconfig.json"):
        stages.append({"name": "TYPECHECK", "cmd": pm_exec(pm, "tsc", "--noEmit")})

    # Lint
    if "lint" in scripts:
        stages.append({"name": "LINT", "cmd": pm_run(pm, "lint")})
    elif has_dep(cwd, "eslint"):
        stages.append({"name": "LINT", "cmd": pm_exec(pm, "eslint", ".")})

    # Test
    if "test" in scripts:
        stages.append({"name": "TEST", "cmd": pm_run(pm, "test")})
    elif has_dep(cwd, "jest"):
        stages.append({"name": "TEST", "cmd": pm_exec(pm, "jest", "--passWithNoTests")})
    elif has_dep(cwd, "vitest"):
        stages.append({"name": "TEST", "cmd": pm_exec(pm, "vitest", "run")})

    # Security audit
    if pm == "npm":
        stages.append({"name": "SECURITY AUDIT", "cmd": ["npm", "audit", "--audit-level=high"]})
    elif pm == "pnpm":
        stages.append({"name": "SECURITY AUDIT", "cmd": ["pnpm", "audit", "--audit-level", "high"]})
    elif pm == "yarn":
        stages.append({"name": "SECURITY AUDIT", "cmd": ["yarn", "npm", "audit", "--severity", "high"]})

    return stages


def python_runner(cwd: Path) -> list[str]:
    """Prefix to invoke a tool: poetry run X / pip-installed X."""
    if file_exists(cwd, "poetry.lock") and which("poetry"):
        return ["poetry", "run"]
    if file_exists(cwd, "pyproject.toml") and which("poetry"):
        try:
            with (cwd / "pyproject.toml").open("r", encoding="utf-8") as f:
                if "[tool.poetry]" in f.read() and which("poetry"):
                    return ["poetry", "run"]
        except OSError:
            pass
    return []


def build_python_stages(cwd: Path) -> list[dict]:
    runner = python_runner(cwd)
    stages: list[dict] = []

    def wrap(tool: str, *args: str) -> list[str] | None:
        if runner:
            return [*runner, tool, *args]
        if which(tool):
            return [tool, *args]
        return None

    # Typecheck
    mypy_cmd = wrap("mypy", ".")
    if mypy_cmd:
        stages.append({"name": "TYPECHECK", "cmd": mypy_cmd})

    # Lint - prefer ruff, fallback flake8
    ruff_cmd = wrap("ruff", "check", ".")
    flake_cmd = wrap("flake8", ".")
    if ruff_cmd:
        stages.append({"name": "LINT", "cmd": ruff_cmd})
    elif flake_cmd:
        stages.append({"name": "LINT", "cmd": flake_cmd})

    # Test
    pytest_cmd = wrap("pytest", "-q")
    if pytest_cmd:
        stages.append({"name": "TEST", "cmd": pytest_cmd})

    # Security audit - prefer pip-audit, fallback bandit
    pip_audit = wrap("pip-audit")
    bandit_cmd = wrap("bandit", "-r", ".", "-q")
    if pip_audit:
        stages.append({"name": "SECURITY AUDIT", "cmd": pip_audit})
    elif bandit_cmd:
        stages.append({"name": "SECURITY AUDIT", "cmd": bandit_cmd})

    return stages


def detect_runtime(cwd: Path) -> str:
    if file_exists(cwd, "package.json"):
        return "node"
    for sig in ("pyproject.toml", "poetry.lock", "requirements.txt", "setup.py", "setup.cfg"):
        if file_exists(cwd, sig):
            return "python"
    return "unknown"


def truncate_tail(text: str, limit: int = MAX_CONTEXT_CHARS) -> str:
    text = text.rstrip()
    if len(text) <= limit:
        return text
    return "... [truncated, showing tail] ...\n" + text[-limit:]


def cmd_to_str(cmd: list[str]) -> str:
    """Shell-ish representation of the command for display."""
    parts: list[str] = []
    for tok in cmd:
        if any(c.isspace() for c in tok) or tok == "":
            parts.append(f'"{tok}"')
        else:
            parts.append(tok)
    return " ".join(parts)


def run_stage(stage: dict) -> tuple[int, str, str]:
    cmd = stage["cmd"]
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False,
        )
        return proc.returncode, proc.stdout or "", proc.stderr or ""
    except FileNotFoundError as e:
        return 127, "", f"command not found: {e}"


def emit_failure(stage_name: str, cmd: list[str], stdout: str, stderr: str, rc: int) -> None:
    context = stderr.strip() or stdout.strip() or f"(no output, exit code {rc})"
    context = truncate_tail(context)
    print(f"### ❌ PRE-FLIGHT FAILURE: {stage_name}")
    print(f"**Command Executed:** `{cmd_to_str(cmd)}`")
    print("**Context for AI Fix:**")
    print()
    print("```")
    print(context)
    print("```")


def emit_success() -> None:
    print("### ✅ PRE-FLIGHT PASSED")
    print("All quality gates verified successfully.")


def main() -> int:
    cwd = Path(os.getcwd())
    runtime = detect_runtime(cwd)

    if runtime == "node":
        stages = build_node_stages(cwd)
    elif runtime == "python":
        stages = build_python_stages(cwd)
    else:
        print("### ⚠️  PRE-FLIGHT SKIPPED: UNKNOWN RUNTIME")
        print("**Context for AI Fix:** No `package.json`, `pyproject.toml`, "
              "`poetry.lock`, or `requirements.txt` found in current directory. "
              "Cannot determine project runtime.")
        return 1

    if not stages:
        print(f"### ⚠️  PRE-FLIGHT SKIPPED: NO STAGES RESOLVED ({runtime.upper()})")
        print("**Context for AI Fix:** Runtime detected but no usable tools "
              "(typecheck/lint/test/audit) were found. Install dev tooling or "
              "define `scripts` in `package.json`.")
        return 1

    print(f"# Pre-Flight Check — runtime: {runtime}", flush=True)
    for stage in stages:
        name = stage["name"]
        cmd = stage["cmd"]
        print(f"\n→ [{name}] {cmd_to_str(cmd)}", flush=True)
        rc, out, err = run_stage(stage)
        if rc != 0:
            print()
            emit_failure(name, cmd, out, err, rc)
            return 1

    print()
    emit_success()
    return 0


if __name__ == "__main__":
    sys.exit(main())
