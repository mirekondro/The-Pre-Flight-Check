# Fixture: `python-broken`

A minimal Python project rigged to fail at **TYPECHECK** when `pre-flight-check` runs against it.

## What's broken

[`src/calc.py`](./src/calc.py) declares:

```python
def safe_divide(numerator: int, denominator: int) -> int:
    if denominator == 0:
        return "undefined"          # returns str
    return numerator // denominator # returns int
```

The zero-divisor branch returns a `str` where the signature promises `int`. Under `[tool.mypy] strict = true`, mypy flags it.

Error code: **`[return-value]`**.

## Reproduce

```bash
cd examples/python-broken
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
python3 ../../skills/pre-flight-check/scripts/run-pipeline.py
```

## Expected output

```
# Pre-Flight Check — runtime: python

→ [TYPECHECK] mypy .

### ❌ PRE-FLIGHT FAILURE: TYPECHECK
**Command Executed:** `mypy .`
**Context for AI Fix:**

```
src/calc.py:12: error: Incompatible return value type (got "str", expected "int")  [return-value]
Found 1 error in 1 file (checked 2 source files)
```

Exit code: **1**. Stage: **TYPECHECK**. No subsequent stages run (fail-fast).

## How to make it pass

Two valid fixes — both demonstrate the protocol's "fix the root, don't suppress" rule:

```python
# Option A — raise instead of returning a sentinel value
def safe_divide(numerator: int, denominator: int) -> int:
    if denominator == 0:
        raise ZeroDivisionError("denominator must be non-zero")
    return numerator // denominator

# Option B — widen the return type to express the actual contract
def safe_divide(numerator: int, denominator: int) -> int | str:
    if denominator == 0:
        return "undefined"
    return numerator // denominator
```

What `SKILL.md` forbids:

```python
def safe_divide(numerator: int, denominator: int) -> int:
    if denominator == 0:
        return "undefined"  # type: ignore[return-value]  ← DO NOT do this
    return numerator // denominator
```
