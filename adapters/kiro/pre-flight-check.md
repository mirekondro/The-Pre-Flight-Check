---
inclusion: always
---

# Pre-Flight Check

Mandatory fail-fast quality gate. Run before declaring any task complete, before committing or pushing, and after applying any bug fix.

## How to run

```bash
python3 .pre-flight-check/scripts/run-pipeline.py
```

Auto-detects Node.js (`package.json`) and Python (`pyproject.toml`, `requirements.txt`, etc.). Runs **Typecheck → Lint → Test → Security Audit** sequentially. Stops on first failure.

## Mandatory trigger rule

You **MUST** run the pre-flight check before:

- Saying "done", "fixed", "complete", "ready to commit", or any synonym.
- Staging, committing, or pushing code.
- Opening or marking a pull request ready for review.
- Switching to a different task after editing code.

## Output blocks

| Block | Exit | Action |
|-------|------|--------|
| `### ✅ PRE-FLIGHT PASSED` | `0` | Proceed. |
| `### ❌ PRE-FLIGHT FAILURE: [STAGE]` | `1` | Stop. Read failure block. Fix the named file at the named line. Re-run. |
| `### ⚠️  PRE-FLIGHT SKIPPED: …` | `1` | Runtime undetected — verify project root has `package.json` / `pyproject.toml` / `requirements.txt`. |

## Strict Fail-Fast Protocol

If `### ❌ PRE-FLIGHT FAILURE` appears, you are **FORBIDDEN** from:

- Declaring the task done.
- Committing, staging, or pushing.
- Switching to a different task or file.
- Using `// @ts-ignore`, `# type: ignore`, `# noqa`, `eslint-disable`, or any suppress mechanism.
- Deleting, skipping, or relaxing a failing test.
- Adding files or packages to ignore lists.
- Re-running the pipeline unchanged hoping for a different result.

**Only permitted action:** fix the exact error shown, re-run, repeat until `### ✅ PRE-FLIGHT PASSED`.

## Reading the failure block

```
### ❌ PRE-FLIGHT FAILURE: TYPECHECK
**Command Executed:** `npx --no-install tsc --noEmit`
**Context for AI Fix:**

```
src/auth/session.ts(42,18): error TS2345: Argument of type 'string | undefined'
is not assignable to parameter of type 'string'.
```
```

Extract: stage name → repair recipe; `Command Executed` → confirms tool; `Context for AI Fix` → file:line:col + rule + message. Open the named file at the named line. Repair only that diagnostic.

## Stage repair rules

- **TYPECHECK** — Fix at source: narrow the type, add missing field, correct signature. No `any`, no `as unknown as X`. Minimum-width cast at external boundaries only.
- **LINT** — Auto-fixer first (`npx eslint . --fix` / `ruff check . --fix`). Manual edit for the rest. No file-level disables, no ignore-list additions.
- **TEST** — Default: production code is wrong. Fix root cause. Never delete, skip, or relax the assertion.
- **SECURITY AUDIT** — Upgrade the vulnerable package. No advisory ignore-lists without explicit user confirmation.

## Anti-patterns to refuse

- Editing files not named in the diagnostic.
- Bundling speculative refactors with the targeted repair.
- Declaring done while a failure block is visible.
- Re-running the pipeline unchanged hoping for a different result.

## Not installed?

```bash
curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash -s -- --project
```

Full docs: [github.com/mirekondro/The-Pre-Flight-Check](https://github.com/mirekondro/The-Pre-Flight-Check).
