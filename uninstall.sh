#!/usr/bin/env bash
# pre-flight-check — convenience uninstaller (macOS / Linux).
#
# Thin wrapper around `install.sh --uninstall`. Use --project to target the
# current repo's .claude/skills/, --dir PATH for a custom location, or no flag
# for the global install under ~/.claude/skills/.
#
# Usage:
#   bash uninstall.sh [--global|--project|--dir PATH]
#
# Curl-pipe:
#   curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/uninstall.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/uninstall.sh | bash -s -- --project

set -euo pipefail

REPO="mirekondro1/The-Pre-Flight-Check"
DEFAULT_REF="main"

# Prefer local install.sh if we're inside a clone.
HERE=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || HERE=""
fi

if [ -n "$HERE" ] && [ -x "$HERE/install.sh" ]; then
  exec bash "$HERE/install.sh" --uninstall "$@"
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "uninstall.sh: curl required for remote uninstall. Clone the repo and run install.sh --uninstall locally." >&2
  exit 1
fi

curl -fsSL "https://raw.githubusercontent.com/${REPO}/${DEFAULT_REF}/install.sh" | bash -s -- --uninstall "$@"
