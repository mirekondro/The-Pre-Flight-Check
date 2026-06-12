---
tags: [infra]
---

# CI

`.github/workflows/ci.yml` — runs on every push / PR to `main` and `dev`.

- **Lint + types** — `ruff` and `mypy --strict` on the [[Engine]] (Python 3.8)
  and the package (3.9).
- **Package smoke** — build the wheel, `pipx` round-trip `init` → `uninstall`
  on Ubuntu / macOS / Windows.
- **Fixtures** — `examples/node-broken` and `examples/python-broken` must exit
  `1` at the TYPECHECK gate.
- **Installer round-trips** + ShellCheck / PSScriptAnalyzer on the installers.

Green CI gates the [[Release Pipeline]].

Related: [[Engine]] · [[Release Pipeline]]
