#!/usr/bin/env bash
# pre-flight-check — convenience uninstaller (macOS / Linux).
#
# Thin wrapper around `install.sh --uninstall`. Pass the same --tool flag
# you used at install time. Defaults to `--tool claude --global`.
#
# Usage:
#   bash uninstall.sh [--tool TOOL] [--global|--project|--dir PATH]
#   bash uninstall.sh --tool all --project
#
# Curl-pipe:
#   curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/uninstall.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/uninstall.sh | bash -s -- --tool cursor --project

set -euo pipefail

REPO="mirekondro/The-Pre-Flight-Check"
DEFAULT_REF="main"

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
