# Contributing to `pre-flight-check`

Thanks for considering a contribution. This project is small, vanilla, and intentionally so — the bar for added complexity is high. Reading this doc end-to-end should take about 5 minutes.

## TL;DR

- **Bugs:** open an [issue](https://github.com/mirekondro1/The-Pre-Flight-Check/issues/new/choose) using the *Bug report* template.
- **Features:** open an [issue](https://github.com/mirekondro1/The-Pre-Flight-Check/issues/new/choose) using the *Feature request* template **first**. Don't open a PR for a new feature without prior discussion.
- **Docs / typos / new runtime adapter / new fixture:** PR welcome without prior issue.

## Project philosophy

Before you propose a change, understand the rules the project enforces on itself:

| Rule | Why |
|---|---|
| **Zero runtime dependencies.** `run-pipeline.py` uses only Python stdlib. | Installs anywhere `python3` runs. No `pip install` step. No supply-chain attack surface. |
| **Two files of skill content.** `SKILL.md` + `run-pipeline.py`. | The installer is two `cp` calls. Easy to audit. Easy to fork. |
| **Auto-detect, don't configure.** | Users shouldn't fill out a config file to use a quality gate. If a heuristic is wrong, fix the heuristic, don't add a knob. |
| **Fail-fast, never paper over.** | `SKILL.md` forbids the agent from suppressing errors. Code changes that loosen this contract will be rejected. |
| **Structured output is load-bearing.** | The Markdown failure block format is part of the public contract. Breaking changes to it need a major version bump. |

If your change conflicts with one of these, it's probably the wrong change — but the conversation is still welcome. Open an issue and pitch the case.

## What we want

- **New runtime adapters** — Go, Rust, Ruby, Elixir, etc. Each needs a detector (signature files) + the 4-stage map (typecheck / lint / test / audit) using zero-config-friendly defaults.
- **Fixture coverage** — additional fixtures in `examples/` for the failure modes not yet shown (LINT, TEST, AUDIT). See `examples/README.md`.
- **Sharper failure context** — if a tool's stderr format includes file:line and we're missing it, send a PR with the truncation/parsing tweak.
- **Installer robustness** — edge cases on weird shells, weird PowerShell hosts, weird proxies.
- **Documentation** — typos, broken links, unclear sections in `README.md` / `INSTALL.md` / `SKILL.md`.

## What we don't want

- **New dependencies** in `run-pipeline.py`. Not even `requests`, not even `rich`. If you need YAML parsing, add a 20-line parser for the subset you need or use stdlib.
- **Configuration files.** No `.preflightrc`, no `preflight.yaml`. Detection is the design.
- **Per-tool plugins** that download/install missing tools. The skill orchestrates the user's existing tooling — installing tooling is the user's job.
- **Telemetry, network calls, analytics.** This script runs locally and stays local.
- **Cosmetic refactors** with no behavior change. We won't reject them out of hand, but they're low priority and may sit.

## Local setup

```bash
git clone https://github.com/mirekondro1/The-Pre-Flight-Check.git
cd The-Pre-Flight-Check

# Install the skill into this very repo for self-dogfooding
bash install.sh --project --force
```

That's the setup. There's no build step.

## Development workflow

### 1. Pick a target

- For a bug fix, reference the issue in your branch name: `git checkout -b fix/issue-42-node-pm-detection`.
- For a new runtime, name it after the runtime: `git checkout -b feat/runtime-go`.
- For docs: `git checkout -b docs/<area>`.

### 2. Make the change

`skills/pre-flight-check/scripts/run-pipeline.py` is the engine. `skills/pre-flight-check/SKILL.md` is the agent contract. Keep them in sync.

If you touch `run-pipeline.py`:

```bash
# Syntax check
python3 -c "import py_compile; py_compile.compile('skills/pre-flight-check/scripts/run-pipeline.py', doraise=True)"

# Smoke test against an example fixture
cd examples/python-broken
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
python3 ../../skills/pre-flight-check/scripts/run-pipeline.py
echo "exit: $?"   # expect 1

# Node fixture
cd ../node-broken
npm install
python3 ../../skills/pre-flight-check/scripts/run-pipeline.py
echo "exit: $?"   # expect 1
```

If you touch `SKILL.md`:

- Frontmatter must remain valid YAML and start with `name: pre-flight-check`.
- The "Strict Fail-Fast Protocol" section enumerates forbidden agent actions — additions OK, deletions need strong justification.

### 3. Test against a real project

Synthetic fixtures aren't enough. Install the skill into a real Node or Python project you work on and ask Claude to run it. Confirm:

- Pipeline detects the runtime correctly.
- Failure output is parseable by Claude (it actually fixes the right file).
- Success output is one line.

### 4. Open a PR

- Use the *Pull Request* template (it'll pre-fill from `.github/PULL_REQUEST_TEMPLATE.md`).
- One PR = one logical change. Don't bundle a bug fix with a refactor.
- Branch off `main` unless we've coordinated a feature branch.
- Pass CI (see [.github/workflows/ci.yml](.github/workflows/ci.yml)).

## Adding a new runtime

The expected pattern, by example:

1. **Add detection** to `detect_runtime` in `run-pipeline.py`. Pick a signature file unique to the runtime (`go.mod`, `Cargo.toml`, `Gemfile`).
2. **Add a `build_<runtime>_stages` function** that returns the same `[{"name": ..., "cmd": [...]}, ...]` shape as the Node and Python builders.
3. **Skip stages whose tools aren't installed.** Use `shutil.which(tool)` to gate. Don't fail because the user didn't install bandit.
4. **Add a fixture** under `examples/<runtime>-broken/` rigged to fail one stage. Include a README with reproduction steps.
5. **Update the runtime table** in `README.md` and `INSTALL.md`.
6. **Update the CI matrix** in `.github/workflows/ci.yml` to run your new fixture.

## Code style

- **Python:** PEP 8, type hints, no third-party deps. The existing script is the style guide.
- **Bash:** `set -euo pipefail` at the top. Quote variables. Shellcheck-clean (CI enforces this in Part 7).
- **Markdown:** sentence-case headings (`## What we want`, not `## What We Want`). Use tables for matrices. Code fences with language hints.
- **No emojis in code or commit messages.** Emojis are fine in `README.md` and structured Markdown blocks emitted by the pipeline (`✅` / `❌` / `⚠️` are part of the public output contract).

## Commit messages

Conventional Commits format:

```
<type>(<scope>): <subject>

<body>
```

Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `ci`, `build`. Scope optional but encouraged (`feat(runtime-go)`, `fix(installer)`, `docs(readme)`).

Subject ≤72 chars, imperative mood ("add", not "added"). Body explains *why*, not *what* — the diff already shows what.

## Pull request review

A reviewer will check:

1. Does it match the project philosophy?
2. Does it add a dependency? (If yes, hard no unless we've discussed.)
3. Does it change the failure-block output format? (If yes, it's a breaking change — bump major.)
4. Does it have a fixture or test backing it?
5. Does CI pass?
6. Is `SKILL.md` updated if behavior changed?
7. Is `README.md` / `INSTALL.md` updated if user-visible?

Reviews aim for ≤72 hours. Ping the issue if it's been longer.

## License

By contributing, you agree your contribution is licensed under the [MIT License](./LICENSE).

## Code of conduct

Be decent. Don't be a jerk. We don't have a long-form CoC because the project is too small to need one yet, but the standard "be respectful in issues/PRs and don't harass anyone" applies. If something happens that you don't want to handle in public, email the maintainer.
