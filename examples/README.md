# Examples

Minimal fixture projects rigged to demonstrate what `pre-flight-check` does. Each fixture is the smallest possible project that triggers a specific stage failure — useful for:

1. **Seeing the failure block format** before installing the skill yourself.
2. **Smoke-testing changes** to `run-pipeline.py` (CI runs these — see [.github/workflows/ci.yml](../.github/workflows/ci.yml) once Part 7 ships).
3. **Reproducing bugs** in issue reports — clone the fixture, run the pipeline, paste the output.

## Fixtures

| Fixture | Runtime | Fails at stage | What's broken |
|---|---|---|---|
| [`node-broken/`](./node-broken/) | Node.js (TypeScript) | **TYPECHECK** | A function returns `string \| undefined` where `string` is required. |
| [`python-broken/`](./python-broken/) | Python (mypy) | **TYPECHECK** | A function annotated `-> int` returns a `str` in one branch. |

Each fixture has its own `README.md` with reproduction steps and the expected output. None of them require you to install the skill globally — you can run the pipeline directly against the fixture.

## Why only "broken" fixtures?

The success path (`### ✅ PRE-FLIGHT PASSED`) is one line and looks the same on every project. The failure paths are where the design work lives — what file is named, how the rule ID surfaces, how stderr is truncated. Those are worth shipping examples of.

## Adding a fixture

PRs welcome. Each new fixture should:

- Be **minimal** — the smallest project that triggers one failure.
- Be **deterministic** — running the pipeline twice produces identical output (modulo absolute paths).
- Include a **README.md** with: what's broken, how to reproduce, expected exit code, expected stage name.
- Be **self-contained** — declare dev deps in `package.json` / `requirements.txt`. Don't rely on globally-installed tools.

See [CONTRIBUTING.md](../CONTRIBUTING.md) (Part 6) for the full workflow.
