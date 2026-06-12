# Launch copy

Ready-to-paste promo for **pre-flight-check**. Attach `site/social-card.png`
where an image is supported. Links:

- Repo: https://github.com/mirekondro/The-Pre-Flight-Check
- Site: https://mirekondro.github.io/The-Pre-Flight-Check/
- PyPI: https://pypi.org/project/pre-flight-check/

> Honesty notes: it's free, MIT, open source, zero runtime deps. Always
> disclose you're the author ("I built this") — every sub below expects it.
> Reply to early comments fast; that's what keeps a post alive.

---

## Reddit

### r/ClaudeAI

**Title:** I built a skill that stops Claude Code from saying "done" on code that doesn't compile

**Body:**

Claude Code is great until it confidently reports "I've implemented the feature!" while `tsc` would have caught a type error, eslint would have flagged dead code, and three tests are failing.

So I made **pre-flight-check** — a quality gate Claude has to pass before it can call a task done. It runs **Typecheck → Lint → Test → Security Audit** in order, stops at the first failure, and hands Claude a structured block with the exact file, line, and rule to fix. The skill also forbids the usual cheats — `@ts-ignore`, deleting failing tests, ignore-list edits — so "green" means actually fixed.

It auto-detects Node.js and Python, uses your existing tooling (tsc/eslint/jest, mypy/ruff/pytest), and the whole engine is one Python file with zero dependencies. It installs as a native Claude Code skill (and works with 9 other AI tools too).

```
pipx install pre-flight-check
pre-flight-check init --tool claude
```

Free + MIT. I'm the author — would love feedback on the failure-block format, since that's what the agent actually reads: https://github.com/mirekondro/The-Pre-Flight-Check

---

### r/cursor

**Title:** Made a free tool that blocks Cursor from marking work "done" on broken code (typecheck/lint/test/audit gate)

**Body:**

Cursor's agent will happily finish a task while the build is red. I built **pre-flight-check** to close that loop: a fail-fast gate that runs Typecheck → Lint → Test → Security Audit and won't pass until each one is green — with the failing file/line/rule fed back to the agent so it fixes the real error instead of suppressing it.

It drops in as a Cursor rule (`.cursor/rules/pre-flight-check.mdc`), auto-detects Node + Python, and reuses your existing tooling. One Python file, zero deps, MIT.

```
pipx install pre-flight-check
pre-flight-check init --tool cursor --project
```

I built it — feedback welcome: https://github.com/mirekondro/The-Pre-Flight-Check

---

### r/ChatGPTCoding

**Title:** pre-flight-check — a universal "definition of done" gate for AI coding agents (Codex, Copilot, Claude, Cursor + more)

**Body:**

Every AI coding agent has the same failure mode: it declares victory before verifying the code works. **pre-flight-check** is a tool-agnostic quality gate that runs **Typecheck → Lint → Test → Security Audit** before a task counts as done, halts on the first failure, and returns a structured block (command + file + line + rule) the agent must act on. It explicitly bans the escape hatches — `@ts-ignore`, `# type: ignore`, deleting tests.

Works with 10 AI tools (Codex/AGENTS.md, Copilot, Claude Code, Cursor, Gemini, Windsurf, Cline, Kiro, Roo, Agent Skills standard), auto-detects Node.js and Python, reuses your existing linters/test runners. Single-file engine, zero runtime deps, MIT.

```
pipx install pre-flight-check
pre-flight-check init --tool all --project
```

Author here — happy to answer anything: https://github.com/mirekondro/The-Pre-Flight-Check

---

## LinkedIn

**Post:**

AI coding agents have one expensive habit: they say "done" before the code actually works.

The agent writes a function, watches it not crash at runtime, and reports success — while the type checker would've caught a bug in 50ms, the linter would've flagged dead code, and the test suite was already red.

I built **pre-flight-check** to fix that.

It's a fail-fast quality gate that runs before any task is marked complete:
 → Typecheck
 → Lint
 → Test
 → Security Audit

The first gate that fails stops everything and hands the agent the exact file, line, and rule to fix — and it forbids the usual shortcuts like `@ts-ignore` or deleting failing tests. "Green" means the bug is fixed, not hidden.

It works with 10 AI coding tools (Claude Code, Cursor, Copilot, Codex, Gemini and more), auto-detects Node.js and Python, and reuses the tooling you already have. The whole engine is a single Python file with zero runtime dependencies. Free and open source (MIT).

```
pipx install pre-flight-check
```

GitHub → https://github.com/mirekondro/The-Pre-Flight-Check

If your team ships with AI agents, this is the guardrail between "the agent said it's done" and "it's actually done."

#AI #SoftwareEngineering #DeveloperTools #OpenSource #CodeQuality #LLM

---

## Product Hunt

**Name:** pre-flight-check

**Tagline (≤60 chars):** Stop your AI coding agent from shipping broken code

**Topics:** Developer Tools · Artificial Intelligence · Open Source · GitHub

**Description:**

pre-flight-check is a universal quality gate for AI coding agents. Before any task is marked "done," it runs Typecheck → Lint → Test → Security Audit, halts on the first failure, and gives the agent the exact file, line, and rule to fix — while forbidding shortcuts like @ts-ignore or deleting failing tests. Works with 10 AI tools (Claude Code, Cursor, Copilot, Codex, Gemini…), auto-detects Node.js and Python, reuses your existing tooling. One Python file, zero runtime deps, MIT.

**First comment (maker):**

Hey Product Hunt 👋

I kept watching AI agents declare "I've successfully implemented the feature!" while the build was on fire — a type error here, a failing test there. The agent never actually checked.

pre-flight-check is the guardrail I wanted: a strict, fail-fast pipeline (Typecheck → Lint → Test → Security Audit) that an agent has to pass before it can call a task done. The key detail is the failure output — it's structured for the agent to read and act on (command, file, line, rule), and the skill explicitly bans the cheats that make a gate falsely green.

It's free, MIT, zero dependencies, and installs as a native skill/rule for 10 different AI tools:

```
pipx install pre-flight-check
pre-flight-check init --tool all --project
```

Would genuinely love feedback on the failure-block format and which runtimes to add next (Go and Rust are on my list). AMA!
