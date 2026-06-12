---
tags: [engine]
---

# Engine

`skills/pre-flight-check/scripts/run-pipeline.py` — the canonical pipeline.
A single vanilla-Python file with **zero third-party dependencies**. It is the
single source of truth; the wheel force-includes it into `_data/` at build time
and [[CLI|the CLI]] runs it as a subprocess.

## Flow

1. [[Runtime Detection]] — is this a Node.js or Python project?
2. Build [[Pipeline Stages]] from [[Node.js Runtime]] or [[Python Runtime]].
3. Run each stage fail-fast; halt on the first non-zero exit.
4. Emit a Markdown failure block (see [[No Escape Hatches]]) or a pass block.

## Cross-platform execution

`resolve_exe()` resolves each command via `shutil.which()` and wraps Windows
`.cmd`/`.bat` shims (npm, npx, tsc, …) through `COMSPEC`, which `CreateProcess`
cannot exec directly.

## Modes

- Default: run every resolved stage.
- `--plan` / `--dry-run`: preview only — see [[Doctor & Stage Selection]].
- `--only` / `--skip`: filter [[Pipeline Stages]].

Related: [[CLI]] · [[CI]]
