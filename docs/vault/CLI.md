---
tags: [cli]
---

# CLI

`src/pre_flight_check/cli.py` — the `pre-flight-check` console script (argparse).

## Subcommands

- `run` — execute the [[Engine]] against the current dir (the default when no
  subcommand is given). Accepts `--only` / `--skip` — see
  [[Doctor & Stage Selection]].
- `doctor` — preview stages without running. See [[Doctor & Stage Selection]].
- `init` — deploy adapter files via the [[Installer]].
- `uninstall` — remove a deployed install.
- `list-tools` — print the [[Supported AI Tools]] table.
- `version` / `--version` — derived from package metadata (single source of
  truth: `pyproject.toml`).

`engine.py` is a thin wrapper that locates the bundled engine and runs it as a
subprocess, forwarding flags.

Related: [[Engine]] · [[Installer]] · [[Distribution Channels]]
