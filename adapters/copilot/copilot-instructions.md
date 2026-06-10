# Pre-Flight Check — GitHub Copilot Instructions

Before declaring any code change complete or ready to commit, you **MUST** run the pre-flight check:

```bash
python3 .pre-flight-check/scripts/run-pipeline.py
```

This pipeline auto-detects Node.js or Python projects and runs Typecheck → Lint → Test → Security Audit sequentially. It exits `0` on success and `1` on the first failure.

## Mandatory trigger rule

Run the pre-flight check before:

- Saying "done", "fixed", "complete", "ready", or any equivalent claim.
- Staging, committing, or pushing code.
- Opening a pull request or marking one ready for review.
- Switching to a different task after editing code.

## Output blocks

| Block | Exit | Action |
|-------|------|--------|
| `### ✅ PRE-FLIGHT PASSED` | `0` | Proceed with the original action. |
| `### ❌ PRE-FLIGHT FAILURE: [STAGE]` | `1` | **Stop.** Read the failure block. Fix the named file at the named line. Re-run. |
| `### ⚠️  PRE-FLIGHT SKIPPED: …` | `1` | Runtime undetected. Verify project root has `package.json` / `pyproject.toml` / `requirements.txt`. |

## Strict Fail-Fast Protocol

When a `### ❌ PRE-FLIGHT FAILURE` block appears, the following actions are **forbidden**:

- Declaring the task done while the failure is on screen.
- Committing, staging, or pushing any code.
- Switching to a different file, task, or feature.
- Suppressing the error: no `// @ts-ignore`, `# type: ignore`, `# noqa`, `eslint-disable`, or equivalent.
- Deleting, skipping, or relaxing a failing test to make it pass.
- Adding the failing file or package to any ignore list.
- Re-running the pipeline unchanged hoping the result differs.

The **only permitted next action** is to repair the exact error named by the failing stage and re-run. Continue until you see `### ✅ PRE-FLIGHT PASSED`.

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

Extract:
1. **Stage name** → tells you which repair recipe to follow.
2. **`Command Executed`** → confirms which tool failed. Do not guess.
3. **`Context for AI Fix`** → file path, line:col, rule/error code, message verbatim.

Open the named file at the named line. Repair that diagnostic. Do not edit unrelated code.

## Stage-specific repair rules

### TYPECHECK
Fix the type at its source — narrow the type, add the missing field, correct the signature. No `any` or escape-hatch casts unless at a genuine external boundary, with a comment explaining why.

### LINT
Run the auto-fixer first (`npx eslint . --fix` or `ruff check . --fix`). For remaining issues, edit manually. No file-level disables, no ignore-list additions.

### TEST
Default assumption: production code is wrong, not the test. Fix the root cause. Do not delete or skip the assertion.

### SECURITY AUDIT
Upgrade the vulnerable package to the patched version. Do not silence the advisory without explicit user confirmation of the risk.

## Anti-patterns to refuse

- Editing files not named in the diagnostic.
- Bundling speculative refactors with the targeted repair.
- Declaring done while a failure block is visible.
- Re-running the pipeline unchanged hoping for a different result.

## If the script is not installed

```bash
curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash -s -- --project
```

See [github.com/mirekondro/The-Pre-Flight-Check](https://github.com/mirekondro/The-Pre-Flight-Check) for full documentation.
