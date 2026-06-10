#!/usr/bin/env bash
# pre-flight-check — installer (macOS / Linux).
#
# Installs the pre-flight-check Claude Code skill either globally
# (~/.claude/skills/) or into the current project (./.claude/skills/).
#
# One-line install (global):
#   curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.sh | bash
#
# One-line install (project-local):
#   curl -fsSL https://raw.githubusercontent.com/mirekondro1/The-Pre-Flight-Check/main/install.sh | bash -s -- --project
#
# Local clone:
#   bash install.sh [flags]
#
# Flags:
#   --global         Install to ~/.claude/skills/ (default)
#   --project        Install to ./.claude/skills/ in the current directory
#   --dir PATH       Install to a custom .claude/skills/ parent (overrides --global/--project)
#   --ref REF        Git ref (branch/tag/sha) to install from when downloading (default: main)
#   --force          Overwrite an existing install without prompting
#   --uninstall      Remove an existing install (honours --global / --project / --dir)
#   -h, --help       Show this help

set -euo pipefail

REPO="mirekondro1/The-Pre-Flight-Check"
SKILL_NAME="pre-flight-check"
DEFAULT_REF="main"

# ANSI colors — disabled if stdout is not a tty.
if [ -t 1 ]; then
  C_BOLD='\033[1m'; C_DIM='\033[2m'; C_RED='\033[31m'
  C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
else
  C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_RESET=''
fi

log()  { printf "${C_CYAN}==>${C_RESET} %s\n" "$*"; }
ok()   { printf "${C_GREEN}✓${C_RESET}  %s\n" "$*"; }
warn() { printf "${C_YELLOW}!${C_RESET}  %s\n" "$*" >&2; }
die()  { printf "${C_RED}✗${C_RESET}  %s\n" "$*" >&2; exit 1; }

show_help() {
  sed -n '2,/^set -euo/p' "$0" | sed -e 's/^# \{0,1\}//' -e '$d'
  exit 0
}

# ---------- argument parsing ----------
SCOPE="global"
CUSTOM_DIR=""
REF="$DEFAULT_REF"
FORCE=0
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --global)     SCOPE="global"; shift ;;
    --project)    SCOPE="project"; shift ;;
    --dir)        [ $# -ge 2 ] || die "--dir requires a path"; CUSTOM_DIR="$2"; SCOPE="custom"; shift 2 ;;
    --ref)        [ $# -ge 2 ] || die "--ref requires a value"; REF="$2"; shift 2 ;;
    --force)      FORCE=1; shift ;;
    --uninstall)  UNINSTALL=1; shift ;;
    -h|--help)    show_help ;;
    *)            die "unknown flag: $1 (run with --help)" ;;
  esac
done

# ---------- resolve install destination ----------
case "$SCOPE" in
  global)  PARENT="${HOME}/.claude/skills" ;;
  project) PARENT="$(pwd)/.claude/skills" ;;
  custom)  PARENT="${CUSTOM_DIR%/}" ;;
esac
DEST="${PARENT}/${SKILL_NAME}"

# ---------- uninstall path ----------
if [ "$UNINSTALL" -eq 1 ]; then
  if [ -d "$DEST" ]; then
    log "Removing ${C_BOLD}${DEST}${C_RESET}"
    rm -rf "$DEST"
    ok "Uninstalled."
  else
    warn "Nothing to remove at $DEST"
  fi
  exit 0
fi

# ---------- prerequisite checks ----------
if ! command -v python3 >/dev/null 2>&1; then
  die "python3 not found on PATH. Install Python 3.8+ first (https://www.python.org)."
fi

PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=${PY_VER%.*}
PY_MINOR=${PY_VER#*.}
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 8 ]; }; then
  die "Python $PY_VER too old. Need Python ≥3.8."
fi

# ---------- existing install ----------
if [ -d "$DEST" ] && [ "$FORCE" -ne 1 ]; then
  if [ -t 0 ]; then
    printf "%s?%s  %s exists. Overwrite? [y/N] " "$C_YELLOW" "$C_RESET" "$DEST"
    read -r REPLY
    case "$REPLY" in
      y|Y|yes|YES) : ;;
      *) die "Aborted." ;;
    esac
  else
    die "$DEST already exists. Re-run with --force to overwrite."
  fi
fi

# ---------- locate skill source ----------
# Prefer local repo clone if this script lives next to skills/<name>/.
HERE=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || HERE=""
fi
LOCAL_SRC=""
if [ -n "$HERE" ] && [ -f "$HERE/skills/$SKILL_NAME/SKILL.md" ]; then
  LOCAL_SRC="$HERE/skills/$SKILL_NAME"
fi

mkdir -p "$DEST/scripts"

if [ -n "$LOCAL_SRC" ]; then
  log "Installing from local clone: ${C_DIM}${LOCAL_SRC}${C_RESET}"
  cp "$LOCAL_SRC/SKILL.md" "$DEST/SKILL.md"
  cp "$LOCAL_SRC/scripts/run-pipeline.py" "$DEST/scripts/run-pipeline.py"
else
  if ! command -v curl >/dev/null 2>&1; then
    die "curl not found. Install curl or clone the repo and run install.sh locally."
  fi
  BASE="https://raw.githubusercontent.com/${REPO}/${REF}/skills/${SKILL_NAME}"
  log "Downloading from ${C_DIM}${BASE}${C_RESET}"
  curl -fsSL "$BASE/SKILL.md"                -o "$DEST/SKILL.md" \
    || die "Failed to download SKILL.md from $BASE/SKILL.md"
  curl -fsSL "$BASE/scripts/run-pipeline.py" -o "$DEST/scripts/run-pipeline.py" \
    || die "Failed to download run-pipeline.py from $BASE/scripts/run-pipeline.py"
fi

chmod +x "$DEST/scripts/run-pipeline.py"

# ---------- post-install summary ----------
echo
ok "Installed ${C_BOLD}pre-flight-check${C_RESET} → ${C_BOLD}${DEST}${C_RESET}"
echo
printf "  ${C_DIM}Scope:${C_RESET}   %s\n" "$SCOPE"
printf "  ${C_DIM}Python:${C_RESET}  %s ($(command -v python3))\n" "$PY_VER"
printf "  ${C_DIM}Source:${C_RESET}  %s\n" "${LOCAL_SRC:-${REPO}@${REF}}"
echo
echo "Next steps:"
echo "  1. Open Claude Code in a project root."
echo "  2. The skill is auto-discovered — ask Claude to 'run pre-flight check'."
echo "  3. Or run it directly:"
printf "       ${C_BOLD}python3 %s/scripts/run-pipeline.py${C_RESET}\n" "$DEST"
echo
echo "Uninstall: re-run this script with --uninstall (same scope flag)."
