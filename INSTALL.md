# Install Guide

Everything you need to install, upgrade, configure, or remove `pre-flight-check`. For the 30-second pitch, see [README.md](./README.md).

## Table of contents

1. [Prerequisites](#prerequisites)
2. [Install scopes: global vs project](#install-scopes-global-vs-project)
3. [One-line install](#one-line-install)
4. [Install from a local clone](#install-from-a-local-clone)
5. [Manual install (no installer)](#manual-install-no-installer)
6. [Pinning a version](#pinning-a-version)
7. [Verifying the install](#verifying-the-install)
8. [Upgrading](#upgrading)
9. [Uninstalling](#uninstalling)
10. [Configuration](#configuration)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Minimum | Check |
|---|---|---|
| **Python** | 3.8 | `python3 --version` |
| **Claude Code** | any version with skill support | `claude --version` |
| **OS** | macOS, Linux, Windows | — |
| **Internet** | only for one-line install (raw GitHub download). Offline install works from a local clone. | — |

The pipeline itself imports only Python stdlib — no `pip install` step. Your project's own dev tooling (`tsc`, `eslint`, `pytest`, etc.) is invoked by the pipeline; install it the normal way for your project.

---

## Install scopes: global vs project

Pick one. You can run both at the same time — global is your default, project overrides it for one repo.

| Scope | Path | Use when |
|---|---|---|
| **Global** *(default)* | `~/.claude/skills/pre-flight-check/` | You want the skill in every project you open with Claude Code. |
| **Project** | `./.claude/skills/pre-flight-check/` (current repo) | You want the skill **only** in this repo, and you want to commit it to git so your team gets it too. |
| **Custom** | wherever `--dir` points | CI, dotfiles, monorepo with a non-standard layout. |

> **Tip — committing the skill into a repo.** If you want every contributor on your team to get the skill automatically, use `--project` and commit `.claude/skills/pre-flight-check/` to git. Claude Code picks it up on clone, no installer required for teammates.

---

## One-line install

### macOS / Linux

**Global (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.sh | bash
```

**Project-local:**

```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.sh | bash -s -- --project
```

**Custom directory:**

```bash
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.sh | bash -s -- --dir /opt/team-skills/.claude/skills
```

### Windows (PowerShell)

**Global:**

```powershell
irm https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.ps1 | iex
```

**Project-local:**

```powershell
$installer = "$env:TEMP\preflight-install.ps1"
irm https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.ps1 -OutFile $installer
& $installer -Project
```

> PowerShell's `irm | iex` pattern can't pass flags directly — download first, then invoke with parameters.

### Flag reference

| Bash | PowerShell | Default | Meaning |
|---|---|---|---|
| `--global` | *(default)* | ✓ | Install to `~/.claude/skills/` |
| `--project` | `-Project` | | Install to `./.claude/skills/` |
| `--dir PATH` | `-Dir PATH` | | Install to a custom `…/.claude/skills/` parent |
| `--ref REF` | `-Ref REF` | `main` | Git ref (branch/tag/sha) to download from |
| `--force` | `-Force` | | Overwrite an existing install without prompting |
| `--uninstall` | `-Uninstall` | | Remove the install (honours scope flags) |
| `-h` / `--help` | `Get-Help .\install.ps1` | | Show usage |

---

## Install from a local clone

Best for offline boxes, air-gapped environments, or when you want to read the code before running it.

```bash
git clone https://github.com/mirekondro1/The-Pre-Flight-Check.git
cd The-Pre-Flight-Check
bash install.sh --global        # or --project, --dir PATH, etc.
```

The installer detects it's running from a clone and copies files locally — no network needed.

---

## Manual install (no installer)

If you don't trust scripts and want to do it yourself, the skill is just two files:

```bash
git clone https://github.com/mirekondro1/The-Pre-Flight-Check.git
mkdir -p ~/.claude/skills                                    # or ./.claude/skills for project-local
cp -r The-Pre-Flight-Check/skills/pre-flight-check ~/.claude/skills/
chmod +x ~/.claude/skills/pre-flight-check/scripts/run-pipeline.py
```

That's the entirety of the install. The installer just automates this plus version-pinning and overwrite safety.

---

## Pinning a version

The default `--ref main` tracks `main` — good for "always latest." For reproducible installs, pin to a tag or commit sha:

```bash
# Pin to a release tag
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/v1.0.0/install.sh \
  | bash -s -- --ref v1.0.0

# Pin to a specific commit
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/3592de9/install.sh \
  | bash -s -- --ref 3592de9
```

Note: pass the ref **in both** the installer URL (so you run the matching installer) **and** in `--ref` (so it downloads the matching skill files).

---

## Verifying the install

After installing, run two quick checks:

**1. The files are where you expect:**

```bash
ls ~/.claude/skills/pre-flight-check/        # or ./.claude/skills/...
# SKILL.md  scripts/
```

**2. The pipeline runs end-to-end:**

```bash
python3 ~/.claude/skills/pre-flight-check/scripts/run-pipeline.py
```

In a fresh directory with no project manifest, you should see:

```
### ⚠️  PRE-FLIGHT SKIPPED: UNKNOWN RUNTIME
**Context for AI Fix:** No `package.json`, `pyproject.toml`, …
```

Exit code `1`. **That's expected** — no runtime detected.

Run it again in an actual Node or Python project and you should see stage headers and a final `### ✅ PRE-FLIGHT PASSED` (or a `❌ PRE-FLIGHT FAILURE` block if something is broken — that's the point).

**3. Claude Code discovers the skill:**

Open Claude Code in a project root and ask: *"do you have a pre-flight check skill available?"* Claude should reply yes and name it.

---

## Upgrading

Just re-run the installer with `--force`:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.sh | bash -s -- --force

# Windows
$installer = "$env:TEMP\preflight-install.ps1"
irm https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.ps1 -OutFile $installer
& $installer -Force
```

The skill is two files; the upgrade is two file overwrites. Your project tooling and Claude Code config are not touched.

---

## Uninstalling

**Global:**

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/uninstall.sh | bash

# Or from a clone
bash uninstall.sh
```

**Project:**

```bash
bash uninstall.sh --project   # from clone, in the project root
```

**Windows:**

```powershell
$installer = "$env:TEMP\preflight-install.ps1"
irm https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.ps1 -OutFile $installer
& $installer -Uninstall          # or -Uninstall -Project
```

**Pure manual:**

```bash
rm -rf ~/.claude/skills/pre-flight-check    # global
rm -rf ./.claude/skills/pre-flight-check    # project
```

The skill leaves nothing else behind — no caches, no config files, no system state.

---

## Configuration

The skill currently takes no configuration — it auto-detects everything from your project tree.

If you want to customise stage behaviour, edit `~/.claude/skills/pre-flight-check/scripts/run-pipeline.py` directly. Common tweaks:

| Want to… | Edit |
|---|---|
| Skip a stage (e.g. no audit) | Comment out the relevant `stages.append(...)` block in `build_node_stages` / `build_python_stages`. |
| Use a different audit tool | Replace the `npm audit` / `pip-audit` invocation with your tool. |
| Use a different lint command | Define a `lint` script in your `package.json` — the pipeline prefers that over invoking `eslint` directly. |
| Tighten audit severity | Change `--audit-level=high` to `--audit-level=moderate` in the Node stages. |
| Change the truncation cap | Bump `MAX_CONTEXT_CHARS` at the top of `run-pipeline.py`. |

Edits to the global install survive across all your projects. Edits to a project-local install only affect that repo.

---

## Troubleshooting

### `python3: command not found`

The installer needs Python 3.8+ on `PATH`. Install it:

- **macOS:** `brew install python` (or download from python.org).
- **Ubuntu/Debian:** `sudo apt install python3`.
- **Windows:** `winget install Python.Python.3.12` or download from python.org (tick *"Add to PATH"*).

After install, open a new shell and verify: `python3 --version` (or `python --version` on Windows).

### `Python <version> too old`

You have Python on PATH but it's older than 3.8. Either upgrade Python globally, or use `pyenv` / `asdf` / a venv to point `python3` at a newer version before running the installer.

### `curl: command not found`

Install curl:

- **macOS:** comes preinstalled. If missing, `brew install curl`.
- **Linux:** `sudo apt install curl` (Debian/Ubuntu), `sudo dnf install curl` (Fedora).
- **Windows:** comes preinstalled in modern Windows. If absent, install via winget or use the PowerShell installer instead.

### `<dest> already exists. Re-run with --force to overwrite.`

You already have a pre-flight-check install at the target location. Either:

```bash
bash install.sh --force          # overwrite
bash install.sh --uninstall      # remove first
```

### Claude Code doesn't see the skill

1. Confirm the files exist: `ls ~/.claude/skills/pre-flight-check/SKILL.md` (or the project-local path).
2. Confirm the `SKILL.md` frontmatter is intact — it must start with `---\nname: pre-flight-check\ndescription: …\n---`.
3. Fully restart Claude Code (close the session and re-open). Skills are scanned on session start.
4. In Claude Code, list available skills and look for `pre-flight-check`.

### `### ⚠️ PRE-FLIGHT SKIPPED: UNKNOWN RUNTIME` in a real project

The detector looks for: `package.json`, `pyproject.toml`, `poetry.lock`, `requirements.txt`, `setup.py`, or `setup.cfg` in the current working directory. If your project root has none of these (e.g. you're in a subdirectory), `cd` to the project root and re-run. For monorepos with a custom layout, see [Configuration](#configuration) to extend the detector.

### `### ⚠️ PRE-FLIGHT SKIPPED: NO STAGES RESOLVED`

The runtime was detected but no usable tools were found on PATH (no `tsc`, `eslint`, `pytest`, `mypy`, etc.). Install at least one of the dev tools listed in the [README runtime table](./README.md#what-it-checks), or define a `scripts` entry in your `package.json` for Node projects.

### A stage fails when I expect it to pass

The pipeline runs your project's actual tooling. If `npx eslint .` fails when invoked directly by the pipeline but passes in your editor, the discrepancy is in the tool config, not the pipeline. Reproduce the failing command (printed in the `Command Executed:` line) in your shell to debug.

### PowerShell: `running scripts is disabled on this system`

Windows blocks unsigned scripts by default. Either:

```powershell
# Allow signed scripts + locally-created scripts for the current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Or one-shot bypass for a single invocation
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### Behind a corporate proxy

The installer uses `curl` (Bash) / `Invoke-WebRequest` (PowerShell). Both honour `HTTP_PROXY` / `HTTPS_PROXY` environment variables. Set those before running, or do a [manual install](#manual-install-no-installer) from a clone.

### Still stuck

Open an issue: [github.com/mirekondro1/The-Pre-Flight-Check/issues](https://github.com/mirekondro1/The-Pre-Flight-Check/issues). Include: OS + version, `python3 --version`, `claude --version`, the exact command you ran, and the full output.
