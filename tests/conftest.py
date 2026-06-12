"""Shared fixtures: load the standalone engine script as an importable module."""

from __future__ import annotations

import importlib.util
import pathlib
import types

import pytest

ENGINE_PATH = (
    pathlib.Path(__file__).resolve().parents[1]
    / "skills"
    / "pre-flight-check"
    / "scripts"
    / "run-pipeline.py"
)


def _load_engine() -> types.ModuleType:
    spec = importlib.util.spec_from_file_location("pfc_engine", ENGINE_PATH)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture()
def engine() -> types.ModuleType:
    """A freshly-loaded copy of run-pipeline.py."""
    return _load_engine()
