---
tags: [engine, cli]
---

# Doctor & Stage Selection

Added in **v1.3.0**.

## `pre-flight-check doctor`

Previews what a run *would* do, without executing anything: the detected
runtime, the [[Pipeline Stages]] that will run (with their commands), and which
tools are present vs missing. Answers "why did that gate skip?". Maps to the
[[Engine]]'s `--plan` / `--dry-run` mode.

## `--only` / `--skip`

Filter stages by key — `typecheck`, `lint`, `test`, `audit` — on both `run` and
`doctor`. Mutually exclusive; validated by argparse `choices`.

```bash
pre-flight-check run --only typecheck
pre-flight-check run --skip audit
pre-flight-check doctor --skip test
```

Related: [[CLI]] · [[Engine]] · [[Pipeline Stages]]
