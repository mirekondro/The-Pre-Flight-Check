<h1 align="center">pre-flight-check</h1>

<p align="center">
  <strong>stop your AI agent from saying "done" when the code is broken</strong>
</p>

<p align="center">
  <a href="https://github.com/mirekondro/The-Pre-Flight-Check/stargazers"><img src="https://img.shields.io/github/stars/mirekondro/The-Pre-Flight-Check?style=flat&color=yellow" alt="Stars"></a>
  <a href="https://github.com/mirekondro/The-Pre-Flight-Check/commits/main"><img src="https://img.shields.io/github/last-commit/mirekondro/The-Pre-Flight-Check?style=flat" alt="Last Commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/mirekondro/The-Pre-Flight-Check?style=flat" alt="License"></a>
  <a href="#install"><img src="https://img.shields.io/badge/install-one--line-brightgreen?style=flat" alt="Install"></a>
</p>

<p align="center">
  <a href="#why">Why</a> •
  <a href="#before--after">Before/After</a> •
  <a href="#install">Install</a> •
  <a href="#what-it-checks">What It Checks</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="./INSTALL.md">Full install guide</a>
</p>

---

A universal AI-agent quality gate that runs a strict, fail-fast pipeline **before** your agent is allowed to declare a task complete or commit code. Auto-detects Node.js or Python projects. Runs **Typecheck → Lint → Test → Security Audit** sequentially. Emits structured Markdown the agent is contractually forbidden from ignoring.

**Works with:** [Claude Code](https://docs.anthropic.com/en/docs/claude-code) · [OpenAI Codex](https://openai.com/codex) · [Gemini CLI](https://github.com/google-gemini/gemini-cli) · [Cursor](https://cursor.com) · [GitHub Copilot](https://github.com/features/copilot) · [Windsurf](https://windsurf.com) · [Cline](https://cline.bot) · [Kiro](https://kiro.dev) · [Roo Code](https://roocode.com) · [Agent Skills standard](https://agentskills.io)

No more "I've successfully implemented the feature!" while the TypeScript compiler is on fire.

## Why

LLM coding agents have one persistent failure mode: **declaring victory on broken code.** They write a function, watch it not throw, and report "done" — while `tsc` would have caught a type error in 50ms, `eslint` would have flagged an unused import, and `pytest` would have failed three tests.

`pre-flight-check` closes that loop. It's a tool-neutral quality gate that ships as a native skill, rule, or instruction file for **every major AI coding agent**:

1. **Triggers automatically** when the agent is about to say "done", commit, or open a PR.
2. **Runs real tooling** (your project's actual typecheck, lint, test, audit commands).
3. **Halts on first failure** with a Markdown block engineered for an LLM to parse and act on — exact file, line, rule ID, error message.
4. **Forbids the agent from suppressing errors** (no `// @ts-ignore`, no `# noqa`, no deleting failing tests) via explicit rules in `SKILL.md`.

The agent has to actually fix the bug. Not work around it.

## Before / After

<table>
<tr>
<td width="50%">

### 🤖 Claude without pre-flight-check

> "I've implemented the user authentication flow. The login function validates credentials, the session middleware handles token refresh, and I've added the necessary database schema migrations. The implementation is complete and ready for review."

*(typecheck fails on 3 files, 2 tests broken, lint warnings ignored)*

</td>
<td width="50%">

### 🚀 Claude with pre-flight-check

> Running pre-flight check...
>
> ```
> ### ❌ PRE-FLIGHT FAILURE: TYPECHECK
> Command Executed: npx --no-install tsc --noEmit
> Context for AI Fix:
> src/auth/session.ts:42:18 - error TS2345:
>   Argument of type 'string | undefined' is not
>   assignable to parameter of type 'string'.
> ```
>
> Fixing `src/auth/session.ts:42` — `userId` can be undefined when the cookie is unset. Adding the guard now.

</td>
</tr>
</table>

**Same agent. Same task. One catches the bug before you do.**

```
┌─────────────────────────────────────────┐
│  FALSE "DONE" CLAIMS    ████████ -90%   │
│  BUGS CAUGHT PRE-COMMIT ████████ +100%  │
│  ESCAPE HATCHES BLOCKED ████████ 100%   │
│  DEPENDENCIES           ████████ 0      │
└─────────────────────────────────────────┘
```

Vanilla Python 3. No `pip install`. No `npm install`. No Node runtime. No SaaS. Runs anywhere `python3` runs.

## Install

### Pick your AI tool

| Tool | One-line install (macOS / Linux) | Deploys to |
|------|----------------------------------|------------|
| **Claude Code** | `curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh \| bash` | `~/.claude/skills/pre-flight-check/` (global) |
| **OpenAI Codex** | `curl -fsSL …/install.sh \| bash -s -- --tool codex --project` | `AGENTS.md` at repo root |
| **Gemini CLI** | `curl -fsSL …/install.sh \| bash -s -- --tool gemini --project` | `GEMINI.md` + `gemini-extension.json` |
| **Cursor** | `curl -fsSL …/install.sh \| bash -s -- --tool cursor --project` | `.cursor/rules/pre-flight-check.mdc` |
| **GitHub Copilot** | `curl -fsSL …/install.sh \| bash -s -- --tool copilot --project` | `.github/copilot-instructions.md` |
| **Windsurf** | `curl -fsSL …/install.sh \| bash -s -- --tool windsurf --project` | `.windsurf/rules/pre-flight-check.md` |
| **Cline** | `curl -fsSL …/install.sh \| bash -s -- --tool cline --project` | `.clinerules/pre-flight-check.md` |
| **Kiro** | `curl -fsSL …/install.sh \| bash -s -- --tool kiro --project` | `.kiro/steering/pre-flight-check.md` |
| **Roo Code** | `curl -fsSL …/install.sh \| bash -s -- --tool roo --project` | `.roo/rules/pre-flight-check.md` |
| **Agent Skills standard** | `curl -fsSL …/install.sh \| bash -s -- --tool agents-skills --project` | `.agents/skills/pre-flight-check/` |
| **Everything, all at once** | `curl -fsSL …/install.sh \| bash -s -- --tool all --project` | All of the above |

> **Don't see your tool?** Most agents read `AGENTS.md` at the repo root as a fallback (Codex, Copilot Coding Agent, Windsurf, Kiro). Install with `--tool codex` and most of the ecosystem is covered.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.ps1 -OutFile $env:TEMP\preflight.ps1
& $env:TEMP\preflight.ps1 -Tool cursor -Project        # or any tool from the table above
```

### Manual install

```bash
git clone https://github.com/mirekondro/The-Pre-Flight-Check.git
cd The-Pre-Flight-Check
bash install.sh --tool all --project                   # installs into the current repo for every tool
```

Open your AI tool in the project root — the skill/rule/instruction file is auto-discovered. See [INSTALL.md](./INSTALL.md) for the full matrix, troubleshooting, and version pinning.

## What It Checks

| Stage | Node.js | Python |
|-------|---------|--------|
| **1. Typecheck** | `tsc --noEmit` (or `npm run typecheck`) | `mypy .` |
| **2. Lint** | `eslint .` (or `npm run lint`) | `ruff check .` → `flake8 .` |
| **3. Test** | `jest --passWithNoTests` / `vitest run` (or `npm test`) | `pytest -q` |
| **4. Security Audit** | `npm audit --audit-level=high` (or `pnpm`/`yarn` equivalent) | `pip-audit` → `bandit -r .` |

**Auto-detection:**
- Picks the package manager from the lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm.
- Prefers `package.json` scripts over direct tool invocation — your project's `npm run lint` config wins.
- For Python: uses `poetry run <tool>` if `poetry.lock` (or `[tool.poetry]` in `pyproject.toml`) is detected and poetry is on `PATH`. Otherwise falls back to the bare tool.
- Tools that aren't installed are skipped silently — no false failures from missing optional gear.

## How It Works

1. **Your AI agent triggers the skill.** Either it self-invokes (the skill/rule file instructs it to run before saying "done"), or you ask explicitly: *"run pre-flight check"*.
2. **Script runs `python3 <install-path>/scripts/run-pipeline.py`** from the repo root. The path depends on which AI tool you installed for — Claude looks under `.claude/skills/…`, others look under `.pre-flight-check/scripts/…`. The installer handles this for you.
3. **Each stage runs sequentially.** First non-zero exit code halts the loop — no point linting code that doesn't typecheck.
4. **Output is structured Markdown.** The success block is one line. The failure block names the exact command, the file:line:rule, and the raw stderr — everything an LLM needs to act:

   ```
   ### ❌ PRE-FLIGHT FAILURE: LINT
   Command Executed: npx --no-install eslint .
   Context for AI Fix:
   ```
   /repo/src/utils/format.ts
     12:7  error  'tmp' is assigned a value but never used  no-unused-vars
   ```
   ```

5. **The instruction file enforces the protocol.** Whether it's `SKILL.md` (Claude / Agent Skills), `AGENTS.md` (Codex), `GEMINI.md`, a Cursor `.mdc` rule, a Copilot instructions file, or any of the other native formats — the body explicitly forbids the agent from:
   - Declaring the task done while a failure is on screen.
   - Suppressing errors with ignore comments, ignore lists, or skipped tests.
   - "Fixing" by deleting the failing assertion.
   - Re-running the pipeline unchanged hoping for a different result.

6. **Exit code = source of truth.** `0` = green, proceed. `1` = stop everything.

## Supported Runtimes

| Runtime | Detection signal | Stages supported |
|---------|------------------|------------------|
| **Node.js** | `package.json` | typecheck, lint, test, audit |
| **Python** | `pyproject.toml`, `poetry.lock`, `requirements.txt`, `setup.py`, `setup.cfg` | typecheck, lint, test, audit |

Roadmap: Go (`go.mod`), Rust (`Cargo.toml`), Ruby (`Gemfile`). PRs welcome — see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Requirements

- **Python 3.8+** on `PATH` (the pipeline engine — no other Python deps).
- **One of the supported AI tools** (see the install table above).
- Your project's normal dev tooling (`tsc`, `eslint`, `pytest`, etc.) — `pre-flight-check` orchestrates them, doesn't replace them.

## FAQ

**Does it slow my agent down?**
Only by the time your test suite takes. The pipeline engine itself is ~50ms of Python overhead.

**Can the agent bypass it?**
The instruction file (whichever native format your tool uses) explicitly forbids common bypass patterns and lists them as "anti-patterns to refuse." A determined agent can technically not invoke the gate, but the instructions tell it to invoke before every "done" / commit. In practice, well-behaved Claude, Codex, Gemini, Cursor, Windsurf, etc. all follow the rule.

**Does it modify my code?**
No. It only **reads** by running your existing tools and reporting their output. Fixes are the agent's job.

**Does it work without internet?**
Yes. Everything runs locally. The security audit stage will warn or skip gracefully if its tool can't reach its CVE feed.

**My project has neither Node nor Python.**
The skill emits `⚠️ PRE-FLIGHT SKIPPED: UNKNOWN RUNTIME` and exits 1. Add a project manifest, or contribute a new runtime adapter.

## License

[MIT](./LICENSE)

---

<p align="center">
  <em>Pre-flight check passed. You are cleared for commit.</em>
</p>
