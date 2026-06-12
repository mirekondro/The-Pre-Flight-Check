---
tags: [tooling]
---

# Supported AI Tools

Ten tools, each delivered to its native instruction path by the [[Installer]]
using an [[AI Tool Adapters|adapter]].

| Tool | Native path |
|------|-------------|
| Claude Code | `.claude/skills/pre-flight-check/` |
| OpenAI Codex / AGENTS.md | `AGENTS.md` |
| Gemini CLI | `GEMINI.md` + `gemini-extension.json` |
| Cursor | `.cursor/rules/pre-flight-check.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Windsurf | `.windsurf/rules/pre-flight-check.md` |
| Cline | `.clinerules/pre-flight-check.md` |
| Kiro | `.kiro/steering/pre-flight-check.md` |
| Roo Code | `.roo/rules/pre-flight-check.md` |
| Agent Skills standard | `.agents/skills/pre-flight-check/` |

`init --tool all` installs every one at once.

Related: [[AI Tool Adapters]] · [[Installer]] · [[CLI]]
