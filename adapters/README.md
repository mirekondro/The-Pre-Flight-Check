# Adapters

Instruction files for AI coding tools other than Claude Code. Each subdirectory
contains the source file(s) for one tool. The installer (`install.sh` /
`install.ps1`) deploys them to the right path in the user's project.

| Directory | Tool | Deployed to | Format |
|-----------|------|-------------|--------|
| `cursor/` | [Cursor](https://cursor.com) | `.cursor/rules/pre-flight-check.mdc` | Cursor Rules (MDC frontmatter) |
| `copilot/` | [GitHub Copilot](https://github.com/features/copilot) | `.github/copilot-instructions.md` | Markdown (no frontmatter) |
| `windsurf/` | [Windsurf](https://codeium.com/windsurf) | `.windsurfrules` | Markdown |
| `cline/` | [Cline](https://github.com/cline/cline) | `.clinerules` | Markdown |

## Claude Code and AGENTS.md / GEMINI.md

- **Claude Code:** uses `skills/pre-flight-check/` (deployed to `.claude/skills/`). See [skills/pre-flight-check/SKILL.md](../skills/pre-flight-check/SKILL.md).
- **Codex / generic agents:** `AGENTS.md` at repo root.
- **Gemini CLI:** `GEMINI.md` at repo root + `gemini-extension.json`.
- **Kiro / Roo / `.agents/skills/` agents:** Part F — ships as a shared `SKILL.md` in `.agents/skills/pre-flight-check/`.

## Adapter content principle

Every adapter file contains the **same fail-fast protocol** — mandatory trigger,
forbidden actions, stage repair rules, anti-patterns. Only the delivery
mechanism (file path, frontmatter format) differs per tool.

When the protocol changes, update **all** adapter files and `SKILL.md` together.
The fastest way: `grep -r "FORBIDDEN" adapters/ skills/ AGENTS.md GEMINI.md` to
find every copy of the protocol block.

## Adding a new adapter

1. Create `adapters/<tool>/` with the instruction file in the tool's native format.
2. Add a row to the table above.
3. Add a deploy step to `install.sh` and `install.ps1` (Part G).
4. Add a row to the "Supported AI tools" table in `README.md`.
5. Send the PR — see [CONTRIBUTING.md](../CONTRIBUTING.md).
