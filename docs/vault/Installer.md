---
tags: [cli]
---

# Installer

`src/pre_flight_check/installer.py` — deploys the [[AI Tool Adapters]] and the
[[Engine]] script into a project tree, reading bundled files via
`importlib.resources`.

- **Per-tool plans** map each adapter to its native destination (see
  [[Supported AI Tools]]).
- **Scopes** — `global` (`~`, Claude only), `project` (cwd), or a custom `--dir`.
- **Engine placement** — `.claude/skills/…/scripts/`, `.agents/skills/…/`, or
  `.pre-flight-check/scripts/` depending on the tool.
- **Uninstall** removes the files and best-effort prunes the empty dirs it
  created (never shared dirs like `.github`).

Driven by the [[CLI]]'s `init` / `uninstall` subcommands.

Related: [[AI Tool Adapters]] · [[Supported AI Tools]] · [[CLI]]
