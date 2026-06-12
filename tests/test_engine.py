"""Unit tests for the pipeline engine (run-pipeline.py)."""

from __future__ import annotations

import importlib.util
import json
import types

import pytest

HAS_TOMLLIB = importlib.util.find_spec("tomllib") is not None


def write(p, name, content=""):
    (p / name).write_text(content, encoding="utf-8")


# --------------------------------------------------------------------------- #
# Runtime detection
# --------------------------------------------------------------------------- #

def test_detect_runtime_node(engine, tmp_path):
    write(tmp_path, "package.json", "{}")
    assert engine.detect_runtime(tmp_path) == "node"


@pytest.mark.parametrize("sig", ["pyproject.toml", "requirements.txt", "setup.py", "setup.cfg", "poetry.lock"])
def test_detect_runtime_python(engine, tmp_path, sig):
    write(tmp_path, sig)
    assert engine.detect_runtime(tmp_path) == "python"


def test_detect_runtime_unknown(engine, tmp_path):
    assert engine.detect_runtime(tmp_path) == "unknown"


def test_detect_runtime_node_takes_precedence(engine, tmp_path):
    write(tmp_path, "package.json", "{}")
    write(tmp_path, "pyproject.toml")
    assert engine.detect_runtime(tmp_path) == "node"


# --------------------------------------------------------------------------- #
# package.json parsing
# --------------------------------------------------------------------------- #

def test_package_json_scripts_valid(engine, tmp_path):
    write(tmp_path, "package.json", json.dumps({"scripts": {"lint": "eslint ."}}))
    assert engine.package_json_scripts(tmp_path) == {"lint": "eslint ."}


def test_package_json_scripts_missing_file(engine, tmp_path):
    assert engine.package_json_scripts(tmp_path) == {}


def test_package_json_scripts_malformed(engine, tmp_path):
    write(tmp_path, "package.json", "{not valid json")
    assert engine.package_json_scripts(tmp_path) == {}


def test_package_json_scripts_non_dict(engine, tmp_path):
    write(tmp_path, "package.json", json.dumps({"scripts": ["nope"]}))
    assert engine.package_json_scripts(tmp_path) == {}


def test_has_dep_across_blocks(engine, tmp_path):
    write(tmp_path, "package.json", json.dumps({"devDependencies": {"eslint": "^9"}}))
    assert engine.has_dep(tmp_path, "eslint") is True
    assert engine.has_dep(tmp_path, "jest") is False


# --------------------------------------------------------------------------- #
# Package-manager command shapes
# --------------------------------------------------------------------------- #

def test_pm_run(engine):
    assert engine.pm_run("npm", "lint") == ["npm", "run", "lint", "--if-present"]
    assert engine.pm_run("yarn", "lint") == ["yarn", "run", "lint"]
    assert engine.pm_run("pnpm", "lint") == ["pnpm", "run", "lint"]


def test_pm_exec(engine):
    assert engine.pm_exec("npm", "tsc", "--noEmit") == ["npx", "--no-install", "tsc", "--noEmit"]
    assert engine.pm_exec("yarn", "eslint", ".") == ["yarn", "eslint", "."]
    assert engine.pm_exec("pnpm", "vitest", "run") == ["pnpm", "exec", "vitest", "run"]


# --------------------------------------------------------------------------- #
# Node stage builder
# --------------------------------------------------------------------------- #

@pytest.fixture()
def all_tools_present(engine, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda cmd: True)


def stage_names(stages):
    return [s["name"] for s in stages]


def test_node_placeholder_test_skipped(engine, tmp_path, all_tools_present):
    write(tmp_path, "package.json", json.dumps(
        {"scripts": {"test": 'echo "Error: no test specified" && exit 1'}}))
    write(tmp_path, "package-lock.json", "{}")
    assert "TEST" not in stage_names(engine.build_node_stages(tmp_path))


def test_node_real_test_used(engine, tmp_path, all_tools_present):
    write(tmp_path, "package.json", json.dumps({"scripts": {"test": "jest"}}))
    assert "TEST" in stage_names(engine.build_node_stages(tmp_path))


def test_node_audit_requires_lockfile(engine, tmp_path, all_tools_present):
    write(tmp_path, "package.json", json.dumps({"scripts": {"lint": "eslint ."}}))
    # No lockfile → no audit stage.
    assert "SECURITY AUDIT" not in stage_names(engine.build_node_stages(tmp_path))
    write(tmp_path, "package-lock.json", "{}")
    assert "SECURITY AUDIT" in stage_names(engine.build_node_stages(tmp_path))


def test_node_typecheck_from_tsconfig(engine, tmp_path, all_tools_present):
    write(tmp_path, "package.json", "{}")
    write(tmp_path, "tsconfig.json", "{}")
    assert "TYPECHECK" in stage_names(engine.build_node_stages(tmp_path))


# --------------------------------------------------------------------------- #
# Python stage builder
# --------------------------------------------------------------------------- #

def test_python_prefers_ruff_over_flake8(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda cmd: cmd in {"ruff", "flake8"})
    stages = engine.build_python_stages(tmp_path)
    lint = [s for s in stages if s["name"] == "LINT"][0]
    assert lint["cmd"][0] == "ruff"


def test_python_audit_prefers_pip_audit(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda cmd: cmd in {"pip-audit", "bandit"})
    stages = engine.build_python_stages(tmp_path)
    audit = [s for s in stages if s["name"] == "SECURITY AUDIT"][0]
    assert audit["cmd"][0] == "pip-audit"


def test_python_no_tools_no_stages(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda cmd: False)
    assert engine.build_python_stages(tmp_path) == []


# --------------------------------------------------------------------------- #
# Go / Rust runtimes
# --------------------------------------------------------------------------- #

@pytest.mark.parametrize("manifest,expected", [("go.mod", "go"), ("Cargo.toml", "rust")])
def test_detect_runtime_go_rust(engine, tmp_path, manifest, expected):
    write(tmp_path, manifest)
    assert engine.detect_runtime(tmp_path) == expected


def test_go_stages_full(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda c: True)
    stages = engine.build_go_stages(tmp_path)
    assert stage_names(stages) == ["TYPECHECK", "LINT", "TEST", "SECURITY AUDIT"]
    lint = [s for s in stages if s["name"] == "LINT"][0]
    assert lint["cmd"][0] == "golangci-lint"


def test_go_lint_falls_back_to_vet(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda c: c == "go")
    stages = engine.build_go_stages(tmp_path)
    assert stage_names(stages) == ["TYPECHECK", "LINT", "TEST"]
    lint = [s for s in stages if s["name"] == "LINT"][0]
    assert lint["cmd"] == ["go", "vet", "./..."]


def test_go_no_toolchain_no_stages(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda c: False)
    assert engine.build_go_stages(tmp_path) == []


def test_rust_stages_full(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda c: True)
    assert stage_names(engine.build_rust_stages(tmp_path)) == [
        "TYPECHECK", "LINT", "TEST", "SECURITY AUDIT"]


def test_rust_minimal(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda c: c == "cargo")
    assert stage_names(engine.build_rust_stages(tmp_path)) == ["TYPECHECK", "TEST"]


def test_rust_no_cargo_no_stages(engine, tmp_path, monkeypatch):
    monkeypatch.setattr(engine, "which", lambda c: False)
    assert engine.build_rust_stages(tmp_path) == []


# --------------------------------------------------------------------------- #
# Cross-platform executable resolution
# --------------------------------------------------------------------------- #

def test_resolve_exe_not_found(engine, monkeypatch):
    monkeypatch.setattr(engine.shutil, "which", lambda c: None)
    assert engine.resolve_exe(["nope", "--x"]) is None


def test_resolve_exe_posix_passthrough(engine, monkeypatch):
    monkeypatch.setattr(engine.os, "name", "posix")
    monkeypatch.setattr(engine.shutil, "which", lambda c: "/usr/bin/mypy")
    assert engine.resolve_exe(["mypy", "."]) == ["/usr/bin/mypy", "."]


def test_resolve_exe_windows_wraps_cmd(engine, monkeypatch):
    monkeypatch.setattr(engine.os, "name", "nt")
    monkeypatch.setattr(engine.shutil, "which", lambda c: r"C:\\npm\\npm.cmd")
    monkeypatch.setenv("COMSPEC", r"C:\\Windows\\cmd.exe")
    resolved = engine.resolve_exe(["npm", "run", "lint"])
    assert resolved[:2] == [r"C:\\Windows\\cmd.exe", "/c"]
    assert resolved[-3:] == [r"C:\\npm\\npm.cmd", "run", "lint"]


def test_resolve_exe_windows_exe_not_wrapped(engine, monkeypatch):
    monkeypatch.setattr(engine.os, "name", "nt")
    monkeypatch.setattr(engine.shutil, "which", lambda c: r"C:\\py\\python.exe")
    assert engine.resolve_exe(["python", "-V"]) == [r"C:\\py\\python.exe", "-V"]


# --------------------------------------------------------------------------- #
# Stage filtering (--only / --skip)
# --------------------------------------------------------------------------- #

def _stages(engine) -> list:
    return [
        {"name": "TYPECHECK", "cmd": ["t"]},
        {"name": "LINT", "cmd": ["l"]},
        {"name": "TEST", "cmd": ["x"]},
        {"name": "SECURITY AUDIT", "cmd": ["a"]},
    ]


def test_filter_only(engine):
    out = engine.filter_stages(_stages(engine), ["typecheck", "lint"], [])
    assert stage_names(out) == ["TYPECHECK", "LINT"]


def test_filter_skip(engine):
    out = engine.filter_stages(_stages(engine), [], ["audit", "test"])
    assert stage_names(out) == ["TYPECHECK", "LINT"]


def test_filter_none(engine):
    assert len(engine.filter_stages(_stages(engine), [], [])) == 4


# --------------------------------------------------------------------------- #
# Config layer
# --------------------------------------------------------------------------- #

def test_apply_config_override(engine):
    out = engine.apply_config([{"name": "LINT", "cmd": ["eslint", "."]}],
                              {"commands": {"lint": "biome check ."}})
    assert out == [{"name": "LINT", "cmd": ["biome", "check", "."]}]


def test_apply_config_adds_missing_stage(engine):
    out = engine.apply_config([], {"commands": {"test": "vitest run"}})
    assert out == [{"name": "TEST", "cmd": ["vitest", "run"]}]


def test_apply_config_disable(engine):
    stages = [{"name": "TYPECHECK", "cmd": ["t"]}, {"name": "SECURITY AUDIT", "cmd": ["a"]}]
    assert stage_names(engine.apply_config(stages, {"disable": ["audit"]})) == ["TYPECHECK"]


def test_apply_config_canonical_order(engine):
    stages = [{"name": "TEST", "cmd": ["x"]}, {"name": "TYPECHECK", "cmd": ["t"]}]
    assert stage_names(engine.apply_config(stages, {})) == ["TYPECHECK", "TEST"]


def test_apply_config_ignores_bad_types(engine):
    stages = [{"name": "LINT", "cmd": ["l"]}]
    assert engine.apply_config(stages, {"commands": "nope", "disable": "nope"}) == stages


@pytest.mark.skipif(not HAS_TOMLLIB, reason="tomllib requires Python 3.11+")
def test_load_config_standalone(engine, tmp_path):
    (tmp_path / ".pre-flight-check.toml").write_text(
        'disable = ["audit"]\n[commands]\nlint = "biome check ."\n')
    cfg = engine.load_config(tmp_path)
    assert cfg["disable"] == ["audit"]
    assert cfg["commands"]["lint"] == "biome check ."


@pytest.mark.skipif(not HAS_TOMLLIB, reason="tomllib requires Python 3.11+")
def test_load_config_pyproject(engine, tmp_path):
    (tmp_path / "pyproject.toml").write_text('[tool.pre-flight-check]\ndisable = ["test"]\n')
    assert engine.load_config(tmp_path)["disable"] == ["test"]


@pytest.mark.skipif(not HAS_TOMLLIB, reason="tomllib requires Python 3.11+")
def test_load_config_standalone_precedence(engine, tmp_path):
    (tmp_path / "pyproject.toml").write_text('[tool.pre-flight-check]\ndisable = ["test"]\n')
    (tmp_path / ".pre-flight-check.toml").write_text('disable = ["lint"]\n')
    assert engine.load_config(tmp_path)["disable"] == ["lint"]


def test_load_config_none(engine, tmp_path):
    assert engine.load_config(tmp_path) == {}


def test_config_source_standalone(engine, tmp_path):
    assert engine.config_source(tmp_path) is None
    (tmp_path / ".pre-flight-check.toml").write_text("disable = []\n")
    assert engine.config_source(tmp_path) == ".pre-flight-check.toml"


# --------------------------------------------------------------------------- #
# Small helpers
# --------------------------------------------------------------------------- #

def test_cmd_to_str_quotes_spaces(engine):
    assert engine.cmd_to_str(["npm", "run", "a b"]) == 'npm run "a b"'


def test_truncate_tail(engine):
    assert engine.truncate_tail("short") == "short"
    big = "x" * 5000
    out = engine.truncate_tail(big, limit=100)
    assert out.startswith("... [truncated")
    assert out.endswith("x" * 100)


# --------------------------------------------------------------------------- #
# run_stage integration (real subprocess)
# --------------------------------------------------------------------------- #

def test_run_stage_success(engine):
    rc, out, err = engine.run_stage({"name": "X", "cmd": ["python3", "-c", "print('hi')"]})
    assert rc == 0
    assert "hi" in out


def test_run_stage_missing_command(engine):
    rc, out, err = engine.run_stage({"name": "X", "cmd": ["definitely-not-a-real-binary-xyz"]})
    assert rc == 127
    assert "command not found" in err
