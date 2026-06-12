---
tags: [engine]
---

# Pipeline Stages

Four sequential gates, run fail-fast. The first to fail halts the run and exits
`1`. Stages whose tools are absent are **skipped silently** — no false
positives.

| # | Stage | [[Node.js Runtime]] | [[Python Runtime]] |
|---|-------|---------|--------|
| 1 | TYPECHECK | `tsc --noEmit` | `mypy .` |
| 2 | LINT | `eslint .` | `ruff` → `flake8` |
| 3 | TEST | `jest` / `vitest` | `pytest -q` |
| 4 | SECURITY AUDIT | `npm audit` | `pip-audit` → `bandit` |

Stage keys for [[Doctor & Stage Selection|--only / --skip]]: `typecheck`,
`lint`, `test`, `audit`.

The shape of the failure block is a public contract — see [[No Escape Hatches]].

Related: [[Runtime Detection]] · [[Engine]]
