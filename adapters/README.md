# Adapters

Instruction files for AI coding tools other than Claude Code. Each subdirectory
contains the source file(s) for one tool. The installer (`install.sh` /
`install.ps1`) deploys them to the right path in the user's project.

| Directory | Tool | Deployed to | Format |
|-----------|------|-------------|--------|
| `cursor/` | [Cursor](https://cursor.com) | `.cursor/rules/pre-flight-check.mdc` | Cursor Rules (MDC frontmatter, `alwaysApply: true`) |
| `copilot/` | [GitHub Copilot](https://github.com/features/copilot) | `.github/copilot-instructions.md` | Markdown (no frontmatter) |
| `windsurf/` | [Windsurf](https://windsurf.com) | `.windsurf/rules/pre-flight-check.md` | Markdown (YAML frontmatter, `trigger: always_on`) |
| `cline/` | [Cline](https://cline.bot) | `.clinerules/pre-flight-check.md` | Markdown (no frontmatter = always active) |
| `kiro/` | [Kiro](https://kiro.dev) | `.kiro/steering/pre-flight-check.md` | Markdown (YAML frontmatter, `inclusion: always`) |
| `roo/` | [Roo Code](https://roocode.com) | `.roo/rules/pre-flight-check.md` | Markdown (no frontmatter) |
| *(see below)* | [Agent Skills standard](https://agentskills.io) | `.agents/skills/pre-flight-check/` | Copy of `skills/pre-flight-check/` (cross-tool alias) |

## Special cases

### Claude Code, AGENTS.md, GEMINI.md

- **Claude Code:** uses `skills/pre-flight-check/` (deployed to `.claude/skills/`). See [skills/pre-flight-check/SKILL.md](../skills/pre-flight-check/SKILL.md).
- **Codex / generic agents that read AGENTS.md:** `AGENTS.md` at repo root.
- **Gemini CLI:** `GEMINI.md` at repo root + `gemini-extension.json`.

### `.agents/skills/` — cross-tool interop tier

The [Agent Skills standard](https://agentskills.io) defines `.agents/skills/<name>/SKILL.md` as a tool-neutral discovery path. Gemini CLI, future Codex tooling, and any other Agent Skills-compatible agent will load skills from there.

**There is no `adapters/agents/` directory.** The installer copies the canonical [`skills/pre-flight-check/`](../skills/pre-flight-check/) verbatim to `.agents/skills/pre-flight-check/`. One source, two install paths — no drift.

### Tools that read AGENTS.md as a fallback

These tools recognize a root-level `AGENTS.md` even if their native adapter isn't installed:

- GitHub Copilot Coding Agent
- Windsurf (Cascade)
- Kiro
- Codex / Codex CLI

That means **shipping `AGENTS.md` alone gives users baseline coverage across the entire ecosystem.** The native adapters are the polished UX layer on top of that baseline.

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
