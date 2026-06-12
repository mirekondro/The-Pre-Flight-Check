---
tags: [engine]
---

# Python Runtime

Builds [[Pipeline Stages]] for a Python project (`pyproject.toml`,
`requirements.txt`, …).

- **Poetry aware** — if `poetry.lock` exists (or `[tool.poetry]` in
  `pyproject.toml`) and `poetry` is installed, tools run via `poetry run`.
- **Tool preference** — LINT prefers `ruff`, falls back to `flake8`; SECURITY
  AUDIT prefers `pip-audit`, falls back to `bandit`.
- Any stage whose tool is not on `PATH` is skipped silently.

Related: [[Runtime Detection]] · [[Pipeline Stages]] · [[Engine]]
