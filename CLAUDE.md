# CLAUDE.md — pre-flight-check repository

> This file is loaded by Claude Code when contributors work on this repo itself.
> It's not the skill that ships to users — that lives in [`skills/pre-flight-check/SKILL.md`](./skills/pre-flight-check/SKILL.md).

## What this project is

`pre-flight-check` is a tool-neutral quality gate that ships as a native skill, rule, or instruction file for 10 AI coding agents. The engine is a single vanilla-Python script. The repo is the canonical source for the skill content, the adapter files, and the cross-platform installer.

## Project philosophy — read before editing

The skill enforces these rules on **users**; this repo enforces them on **itself**:

| Rule | Why |
|---|---|
| **Zero runtime dependencies** in `run-pipeline.py` | The engine must install anywhere `python3` runs. No `pip install` step. No supply-chain risk for users. |
| **Two-file skill content** (`SKILL.md` + `run-pipeline.py`) | Auditable in 5 minutes. Easy to fork. Easy to copy manually. |
| **Auto-detect, never configure** | If a heuristic is wrong, fix the heuristic, don't add a config knob. |
| **Fail-fast, never paper over** | The instruction files explicitly forbid agents from suppressing errors. Code changes that loosen this contract get rejected. |
| **Structured output is load-bearing** | The Markdown failure block format is part of the public contract. Any change to its shape is a breaking change — bump major. |

Full philosophy in [`CONTRIBUTING.md`](./CONTRIBUTING.md). If your change conflicts with one of these, it's probably the wrong change — but the conversation is welcome via issue.

## Layout

```
.
├── skills/pre-flight-check/         # CANONICAL SKILL SOURCE
│   ├── SKILL.md                     #   Agent contract (load-bearing)
│   └── scripts/run-pipeline.py      #   The pipeline engine (vanilla Python 3, no deps)
│
├── adapters/                        # Per-tool instruction file sources
│   ├── cursor/pre-flight-check.mdc
│   ├── copilot/copilot-instructions.md
│   ├── windsurf/pre-flight-check.md
│   ├── cline/pre-flight-check.md
│   ├── kiro/pre-flight-check.md
│   ├── roo/pre-flight-check.md
│   └── README.md                    #   Maintainer index — read when adding a new tool
│
├── AGENTS.md                        # Codex / generic AGENTS.md-based agents
├── GEMINI.md                        # Gemini CLI context file
├── gemini-extension.json            # Gemini CLI extension manifest
│
├── .claude-plugin/                  # Claude Code plugin marketplace manifest
│   ├── plugin.json
│   └── marketplace.json
│
├── install.sh / install.ps1         # Multi-tool installer (--tool flag, see --list-tools)
├── uninstall.sh                     # Thin wrapper around install.sh --uninstall
│
├── examples/                        # Fixtures that double as docs and CI smoke targets
│   ├── node-broken/                 #   Rigged TS2345 failure
│   └── python-broken/               #   Rigged mypy [return-value] failure
│
├── .github/workflows/ci.yml         # ruff + mypy + shellcheck + PSScriptAnalyzer + fixture runs + installer round-trip
└── (README.md, INSTALL.md, CONTRIBUTING.md, LICENSE)
```

## When editing the engine (`skills/pre-flight-check/scripts/run-pipeline.py`)

- Python 3.8 is the floor. CI enforces `mypy --strict --python-version 3.8`.
- No third-party imports. If you need YAML parsing, use a 20-line stdlib parser for the subset you need.
- Type annotations are required everywhere. Use the `Stage` TypedDict for stage dicts.
- After editing, run both fixture pipelines:
  ```bash
  (cd examples/node-broken && python3 ../../skills/pre-flight-check/scripts/run-pipeline.py)
  (cd examples/python-broken && PATH="$PWD/.venv/bin:$PATH" python3 ../../skills/pre-flight-check/scripts/run-pipeline.py)
  ```
  Both should exit `1` with `### ❌ PRE-FLIGHT FAILURE: TYPECHECK`.

## When editing `SKILL.md` or any adapter file under `adapters/`

The fail-fast protocol — the **FORBIDDEN actions** list, **Anti-patterns to refuse**, **Stage-specific repair rules** — is duplicated across 7 files on purpose (one per adapter tool). When you change the protocol, **update all of them together**.

Find every copy:
```bash
grep -rn "FORBIDDEN" skills/ adapters/ AGENTS.md GEMINI.md
```

## When adding a new AI tool

1. Add `adapters/<tool>/<file>.<ext>` in that tool's native rule format.
2. Add a row to the matrix in `adapters/README.md`.
3. Add a deploy case to `install.sh` (function `install_tool`) and `install.ps1` (`Install-OneTool`).
4. Add the path to `adapter_paths_for` in `install.sh` and `Get-AdapterPaths` in `install.ps1`.
5. Add the tool name to `SUPPORTED_TOOLS` in `install.sh` and `$SupportedTools` in `install.ps1`.
6. Add a row to the README install matrix.
7. Add the expected file path to the `installer-multitool` CI job's expected array.

`adapters/README.md` has a longer checklist.

## When adding a new runtime (Go, Rust, Ruby, etc.)

1. Add detection in `detect_runtime` (signature files).
2. Add `build_<runtime>_stages` returning `list[Stage]`.
3. Use `shutil.which(tool)` to gate stages — missing tools skip, never fail.
4. Add a `examples/<runtime>-broken/` fixture rigged to fail one stage.
5. Update the runtime table in `README.md` and `INSTALL.md`.
6. Add a CI fixture job mirroring `fixture-node-broken` / `fixture-python-broken`.

## Smoke test before pushing

```bash
# Engine lint
ruff check skills/pre-flight-check/scripts/run-pipeline.py
mypy --strict --python-version 3.8 skills/pre-flight-check/scripts/run-pipeline.py

# Installer lint
shellcheck -s bash install.sh uninstall.sh

# Installer round-trip in a temp project
TMP=$(mktemp -d) && cd "$TMP" \
  && bash /path/to/this/repo/install.sh --tool all --project --force \
  && bash /path/to/this/repo/install.sh --tool all --project --uninstall
```

Or just push to `dev` and let CI run — the workflow does all of the above plus the fixture pipelines.

## Commit style

Conventional Commits: `<type>(<scope>): <subject>`. Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `ci`, `build`. Subject ≤72 chars, imperative. See recent commits for examples.

## Release flow

1. PR `dev` → `main`.
2. Merge with squash or merge commit.
3. `gh release create vX.Y.Z --target main --title "vX.Y.Z — <headline>" --notes "..."`
4. The release notes go on the GitHub Releases page; users see them when checking for updates.
