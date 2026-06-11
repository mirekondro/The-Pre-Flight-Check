<div align="center">

<h1>✈️ pre-flight-check</h1>

### Stop your AI coding agent from declaring **"done"** on broken code.

A universal quality gate that runs **Typecheck → Lint → Test → Security Audit**
before any task is marked complete.
Auto-detects Node.js and Python. Works with [10 AI coding tools](#-supported-ai-tools).

<br>

[![CI](https://github.com/mirekondro/The-Pre-Flight-Check/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mirekondro/The-Pre-Flight-Check/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/mirekondro/The-Pre-Flight-Check?color=blue)](https://github.com/mirekondro/The-Pre-Flight-Check/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Zero deps](https://img.shields.io/badge/runtime%20deps-0-success.svg)](#-how-it-works)

<br>

**[Website](https://mirekondro.github.io/The-Pre-Flight-Check/)** &nbsp;·&nbsp; **[Install](#-install)** &nbsp;·&nbsp; **[How it works](#-how-it-works)** &nbsp;·&nbsp; **[Supported AI tools](#-supported-ai-tools)** &nbsp;·&nbsp; **[Full guide](INSTALL.md)**

> 🌐 The landing-page source now lives in [`site/`](site/) and auto-deploys to GitHub Pages.

</div>

---

```text
        ┌───────────┐   ┌──────┐   ┌──────┐   ┌────────────────┐
   →    │ TYPECHECK │ → │ LINT │ → │ TEST │ → │ SECURITY AUDIT │ → ✅ cleared for takeoff
        └───────────┘   └──────┘   └──────┘   └────────────────┘
              ↓ first failure halts the pipeline → ❌ exit 1
```

## 🛑 The problem

Your AI agent writes a function, watches it not throw at runtime, and reports "done" — while `tsc`
would have caught a type error in 50ms, `eslint` would have flagged dead code, and `pytest` would
have failed three tests.

`pre-flight-check` closes that loop. **One command, four gates, structured failure output the agent
has to act on.** No more "I've successfully implemented the feature!" while the build is on fire.

## 📦 Install

Pick the install path that matches your platform.

<details open>
<summary><b>🍎 macOS · 🐧 Linux (Homebrew)</b></summary>

```bash
brew tap mirekondro/pre-flight-check
brew install pre-flight-check
```

</details>

<details>
<summary><b>🪟 Windows (Scoop)</b></summary>

```powershell
scoop bucket add pre-flight-check https://github.com/mirekondro/The-Pre-Flight-Check
scoop install pre-flight-check
```

</details>

<details>
<summary><b>🐍 Any platform (pipx)</b></summary>

```bash
pipx install pre-flight-check
```

</details>

<details>
<summary><b>⚡ One-line install (no package manager)</b></summary>

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.ps1 | iex
```

</details>

<details>
<summary><b>🤖 Claude Code plugin marketplace</b></summary>

```bash
claude plugin marketplace add mirekondro/The-Pre-Flight-Check
claude plugin install pre-flight-check
```

</details>

Then in any project:

```bash
pre-flight-check init --tool claude          # or cursor, codex, gemini, copilot, …
pre-flight-check init --tool all --project   # install for every supported AI tool at once
```

See **[INSTALL.md](INSTALL.md)** for the full per-tool matrix and troubleshooting.

## ⚙️ What it does

When your AI agent says "I'm done," it doesn't always mean the code works. `pre-flight-check`
interposes a strict, fail-fast pipeline:

```text
Typecheck → Lint → Test → Security Audit
```

The first stage that fails **halts the pipeline**, prints a structured Markdown block, and exits `1`.
The agent reads that block and **must fix the exact error** before continuing.

Here's what the agent actually sees on a failure:

```text
### ❌ PRE-FLIGHT FAILURE: TYPECHECK
**Command Executed:** `npx --no-install tsc --noEmit`
**Context for AI Fix:**

src/auth/session.ts(42,18): error TS2345: Argument of type 'string | undefined'
is not assignable to parameter of type 'string'.
```

It knows: which **file** (`session.ts`), which **line** (`42:18`), which **rule** (`TS2345`), and
what's wrong. No more "I think the auth flow is implemented."

On success:

```text
### ✅ PRE-FLIGHT PASSED
All quality gates verified successfully.
```

## 🤖 Supported AI tools

| Tool | Native delivery path | One-liner |
|---|---|---|
| **Claude Code** | `.claude/skills/pre-flight-check/` | `pre-flight-check init --tool claude` |
| **OpenAI Codex / AGENTS.md** | `AGENTS.md` at repo root | `pre-flight-check init --tool codex --project` |
| **Gemini CLI** | `GEMINI.md` + `gemini-extension.json` | `pre-flight-check init --tool gemini --project` |
| **Cursor** | `.cursor/rules/pre-flight-check.mdc` | `pre-flight-check init --tool cursor --project` |
| **GitHub Copilot** | `.github/copilot-instructions.md` | `pre-flight-check init --tool copilot --project` |
| **Windsurf** | `.windsurf/rules/pre-flight-check.md` | `pre-flight-check init --tool windsurf --project` |
| **Cline** | `.clinerules/pre-flight-check.md` | `pre-flight-check init --tool cline --project` |
| **Kiro** | `.kiro/steering/pre-flight-check.md` | `pre-flight-check init --tool kiro --project` |
| **Roo Code** | `.roo/rules/pre-flight-check.md` | `pre-flight-check init --tool roo --project` |
| **Agent Skills standard** | `.agents/skills/pre-flight-check/` | `pre-flight-check init --tool agents-skills --project` |

> Several tools (Codex, Copilot Coding Agent, Windsurf, Kiro) read `AGENTS.md` at the repo root as a
> fallback. Installing `--tool codex` alone gives broad ecosystem coverage.

## ✅ What it checks

| Stage | Node.js | Python |
|---|---|---|
| **1. Typecheck** | `tsc --noEmit` (or `npm run typecheck`) | `mypy .` |
| **2. Lint** | `eslint .` (or `npm run lint`) | `ruff check .` → `flake8 .` |
| **3. Test** | `jest` / `vitest` (or `npm test`) | `pytest -q` |
| **4. Security Audit** | `npm audit --audit-level=high` | `pip-audit` → `bandit -r .` |

> Stages whose tools aren't installed are **skipped silently** — no false positives from missing
> optional gear.

## 🔍 How it works

- **🔎 Auto-detects** the runtime from manifest files (`package.json`, `pyproject.toml`, `requirements.txt`, …).
- **📦 Picks the right package manager** from the lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm.
- **🛠️ Prefers your existing scripts** — if `package.json` defines `lint`, the pipeline calls `npm run lint` instead of invoking `eslint` directly.
- **🛑 Halts on first failure** — no point linting code that doesn't typecheck.
- **🚫 Forbids escape hatches.** The instruction file the AI agent reads (`SKILL.md`, `AGENTS.md`, `.cursorrules/*.mdc`, etc.) explicitly bans `// @ts-ignore`, `# type: ignore`, deleting failing tests, adding to ignore lists, and other ways to mark the gate green without fixing the bug.

> The whole engine is **one Python file with zero runtime dependencies.** Audit it in five minutes.

## 📋 Requirements

- **Python 3.8+** on `PATH` (the engine — no other Python dependencies)
- Your project's existing dev tooling — `tsc`, `eslint`, `pytest`, etc. We orchestrate, we don't replace.

That's it.

## 🚦 Project status

**Stable.** Used in production on the maintainer's own projects. The failure-block Markdown format
is part of the public contract — any change to its shape is a major version bump.

Contributions welcome — see **[CONTRIBUTING.md](CONTRIBUTING.md)**. The bar for new features is high;
the bar for new runtime adapters (Go, Rust, Ruby, …) and additional AI-tool adapters is low.

## 📄 License

[MIT](LICENSE)

---

<div align="center">
<sub>If <code>pre-flight-check</code> catches a bug for you that would have shipped —
<a href="https://github.com/mirekondro/The-Pre-Flight-Check">⭐ star the repo</a> so the next developer finds it too.</sub>
</div>
