# Pre-Flight Check — Agent Instructions

> **For:** OpenAI Codex, Codex CLI, any agent that reads `AGENTS.md`.
> The engine (`run-pipeline.py`) is vanilla Python 3 with no external deps — it runs anywhere.

---

## What this is

`pre-flight-check` is a mandatory, fail-fast quality gate. It runs your project's real tooling in a strict sequence:

```
Typecheck → Lint → Test → Security Audit
```

The script auto-detects Node.js (`package.json`) or Python (`pyproject.toml`, `requirements.txt`, etc.) and invokes the appropriate tools. Each stage only runs if the previous one passed.

---

## Mandatory trigger rule

You **MUST** run the pre-flight check before:

- Telling the user a task is "done", "complete", "fixed", "ready", or any synonym.
- Staging, committing, or pushing any code change.
- Opening or marking a pull request ready for review.
- Moving on to a different task or file after a code edit.

If you are about to produce any of those outputs — stop, run the check first.

## How to run

```bash
python3 .pre-flight-check/scripts/run-pipeline.py
```

The script prints a header per stage as it runs, then emits one of three terminal blocks:

| Output | Exit code | Meaning |
|--------|-----------|---------|
| `### ✅ PRE-FLIGHT PASSED` | `0` | All gates green. You may proceed. |
| `### ❌ PRE-FLIGHT FAILURE: [STAGE]` | `1` | A gate failed. Stop. Fix. |
| `### ⚠️  PRE-FLIGHT SKIPPED: …` | `1` | Runtime undetected or no tools found. Resolve before proceeding. |

---

## Strict Fail-Fast Protocol

If the script outputs `### ❌ PRE-FLIGHT FAILURE: [STAGE_NAME]`, you are **FORBIDDEN** from:

- Declaring the task done.
- Committing, staging, or pushing any code.
- Switching to a different task, file, or feature.
- Suppressing the error (`// @ts-ignore`, `# type: ignore`, `# noqa`, `eslint-disable`, removing the failing test, adding to an ignore list).
- Re-running the pipeline unchanged hoping for a different result.

Your **only** permitted next action: repair the exact error named by the failing stage, then re-run. Loop until `### ✅ PRE-FLIGHT PASSED`.

---

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

Extract in order:
1. **Stage name** — tells you which repair recipe to follow (below).
2. **`Command Executed`** — confirms which tool failed. Do not guess.
3. **`Context for AI Fix`** — find the **file path**, **line:col**, **rule / error code**, and **diagnostic message** verbatim.

Open the named file at the named line. Repair the exact diagnostic. Do not touch unrelated code.

---

## Stage-specific repair rules

### TYPECHECK failure

1. Parse the file path and line number from `Context for AI Fix`.
2. Read that file at that line.
3. Fix the type at its source — narrow the type, add a missing field, correct the signature, fix the call site.
4. Do **not** use `any`, `as unknown as X`, `# type: ignore`, or any escape hatch. If a cast is genuinely required at an external boundary, use the minimum-width cast at the narrowest possible scope with a one-line comment explaining why.
5. Re-run the pipeline.

### LINT failure

1. Identify the rule ID and file from the context block.
2. Run the project's auto-fix command first:
   - **Node:** `npx eslint . --fix` / `npm run lint -- --fix` / `pnpm lint --fix`
   - **Python:** `ruff check . --fix` then `ruff format .` or `black .`
3. For rules the auto-fixer can't resolve, edit the file manually.
4. Do **not** add files to ignore lists. Do **not** add file-level disables. Inline rule disables are only allowed for a single line with a comment justifying why.
5. Re-run the pipeline.

### TEST failure

1. Read the assertion message and failing test name from the context block.
2. Determine whether production code is wrong or the test expectation is wrong. Default: production code is wrong.
3. Fix the root cause in the production code.
4. Do **not** delete, skip, or relax the assertion to make the test pass.
5. Re-run the pipeline.

### SECURITY AUDIT failure

1. Identify the vulnerable package and CVE / advisory ID.
2. Upgrade to the patched version. If no patch exists, assess whether the affected code path is reachable.
3. Do **not** add the advisory to an ignore list without explicitly stating the risk to the user and getting confirmation.
4. Re-run the pipeline.

---

## Anti-patterns — refuse these

- Re-running the pipeline unchanged hoping the result differs.
- Editing a file not named in the diagnostic.
- "Fixing" by deleting the failing test, suppressing the rule, or relaxing the type.
- Declaring done while a failure is on screen.
- Switching strategy after a single failure — repair, re-run, repeat.
- Bundling speculative refactors alongside the targeted repair.

---

## Success state

When the script prints:

```
### ✅ PRE-FLIGHT PASSED
All quality gates verified successfully.
```

and exits `0`, you may proceed with the original action (commit, mark done, open PR).

---

## Script not found?

If `.pre-flight-check/scripts/run-pipeline.py` does not exist, the skill has not been installed for your current project. Install it:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash -s -- --project

# Windows (PowerShell)
irm https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.ps1 | iex
# then re-run with: & .\install.ps1 -Project
```

See [INSTALL.md](./INSTALL.md) for the full matrix.
