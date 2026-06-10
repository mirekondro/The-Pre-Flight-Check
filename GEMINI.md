# Pre-Flight Check — Gemini CLI Context

> This file is loaded as persistent context by Gemini CLI on every prompt.
> It instructs Gemini to run a fail-fast quality gate pipeline before
> declaring any task complete or committing code.
>
> The engine (`run-pipeline.py`) is vanilla Python 3 with zero external deps.

@./skills/pre-flight-check/SKILL.md

---

## Gemini-specific notes

### Running the pipeline

```bash
python3 .pre-flight-check/scripts/run-pipeline.py
```

If that path doesn't exist, the skill is not installed for this project. Install it:

```bash
curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash -s -- --project
```

### Available as an Agent Skill

`pre-flight-check` is also discoverable as an Agent Skill under `.agents/skills/pre-flight-check/` (or `.gemini/skills/pre-flight-check/`). When active as a Skill, Gemini will self-invoke the pipeline at the checkpoints defined in `SKILL.md` without you needing to ask explicitly.

To install the Skill tier for Gemini:

```bash
bash install.sh --project   # installs to .agents/skills/ in addition to the script
```

### Output blocks

| Output | Exit code | Action required |
|--------|-----------|-----------------|
| `### ✅ PRE-FLIGHT PASSED` | `0` | Proceed. |
| `### ❌ PRE-FLIGHT FAILURE: [STAGE]` | `1` | Stop. Read the `Context for AI Fix` block. Fix the named file at the named line. Re-run. |
| `### ⚠️  PRE-FLIGHT SKIPPED: …` | `1` | Runtime undetected. Verify you're running from the project root and the manifest file exists (`package.json` / `pyproject.toml` / `requirements.txt`). |

### Reload context

If you've just installed the skill or updated `SKILL.md` and Gemini doesn't seem aware of the protocol, run `/memory reload` to re-scan all context files.
