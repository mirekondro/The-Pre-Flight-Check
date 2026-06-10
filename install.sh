#!/usr/bin/env bash
# pre-flight-check — multi-tool installer (macOS / Linux).
#
# Installs the pre-flight-check skill for one or more AI coding tools.
# The pipeline engine (run-pipeline.py) is the same across all tools;
# only the instruction/rule file format and deploy path differ.
#
# One-line install (Claude Code, global):
#   curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash
#
# One-line install for a different tool (project-local):
#   curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash -s -- --tool cursor --project
#
# Install for every supported tool in the current project:
#   curl -fsSL https://raw.githubusercontent.com/mirekondro/The-Pre-Flight-Check/main/install.sh | bash -s -- --tool all --project
#
# Local clone:
#   bash install.sh [flags]
#
# Flags:
#   --tool TOOL      AI tool to install for. See --list-tools. Default: claude
#   --global         Install to ~/.claude/skills/ (Claude only — all other tools are project-scoped)
#   --project        Install into the current directory (default for non-Claude tools)
#   --dir PATH       Override the project root the adapter is deployed into
#   --ref REF        Git ref (branch/tag/sha) to download from (default: main)
#   --force          Overwrite existing files without prompting
#   --uninstall      Remove the install (honours --tool / --global / --project / --dir)
#   --list-tools     Print the supported AI tools table and exit
#   -h, --help       Show this help

set -euo pipefail

REPO="mirekondro/The-Pre-Flight-Check"
SKILL_NAME="pre-flight-check"
DEFAULT_REF="main"
SUPPORTED_TOOLS="claude codex gemini cursor copilot windsurf cline kiro roo agents-skills all"

# ANSI colors — disabled if stdout is not a tty.
if [ -t 1 ]; then
  C_BOLD='\033[1m'; C_DIM='\033[2m'; C_RED='\033[31m'
  C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_CYAN='\033[36m'; C_RESET='\033[0m'
else
  C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_RESET=''
fi

log()  { printf "%s==>%s %s\n" "$C_CYAN" "$C_RESET" "$*"; }
ok()   { printf "%s✓%s  %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf "%s!%s  %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf "%s✗%s  %s\n" "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

show_help() {
  sed -n '2,/^set -euo/p' "$0" | sed -e 's/^# \{0,1\}//' -e '$d'
  exit 0
}

show_tools() {
  cat <<'EOF'
Supported AI tools (--tool):

  claude          Claude Code            -> ~/.claude/skills/  or  .claude/skills/
  codex           OpenAI Codex / AGENTS  -> AGENTS.md at repo root
  gemini          Gemini CLI             -> GEMINI.md + gemini-extension.json at repo root
  cursor          Cursor                 -> .cursor/rules/pre-flight-check.mdc
  copilot         GitHub Copilot         -> .github/copilot-instructions.md
  windsurf        Windsurf               -> .windsurf/rules/pre-flight-check.md
  cline           Cline                  -> .clinerules/pre-flight-check.md
  kiro            Kiro                   -> .kiro/steering/pre-flight-check.md
  roo             Roo Code               -> .roo/rules/pre-flight-check.md
  agents-skills   Agent Skills standard  -> .agents/skills/pre-flight-check/

  all             Install for every supported tool above.

The pipeline engine (run-pipeline.py) is deployed once per scope:
  - Claude: .claude/skills/pre-flight-check/scripts/run-pipeline.py
  - All others: .pre-flight-check/scripts/run-pipeline.py
EOF
  exit 0
}

# ---------- argument parsing ----------
TOOL="claude"
SCOPE_EXPLICIT=0
SCOPE="global"
CUSTOM_DIR=""
REF="$DEFAULT_REF"
FORCE=0
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)        [ $# -ge 2 ] || die "--tool requires a value (see --list-tools)"; TOOL="$2"; shift 2 ;;
    --global)      SCOPE="global"; SCOPE_EXPLICIT=1; shift ;;
    --project)     SCOPE="project"; SCOPE_EXPLICIT=1; shift ;;
    --dir)         [ $# -ge 2 ] || die "--dir requires a path"; CUSTOM_DIR="$2"; SCOPE="custom"; SCOPE_EXPLICIT=1; shift 2 ;;
    --ref)         [ $# -ge 2 ] || die "--ref requires a value"; REF="$2"; shift 2 ;;
    --force)       FORCE=1; shift ;;
    --uninstall)   UNINSTALL=1; shift ;;
    --list-tools)  show_tools ;;
    -h|--help)     show_help ;;
    *)             die "unknown flag: $1 (run with --help)" ;;
  esac
done

# Validate --tool
case " $SUPPORTED_TOOLS " in
  *" $TOOL "*) ;;
  *) die "unknown tool: $TOOL (run with --list-tools)" ;;
esac

# --global only makes sense for Claude. For every other tool, default to --project.
if [ "$TOOL" != "claude" ] && [ "$SCOPE" = "global" ]; then
  if [ "$SCOPE_EXPLICIT" -eq 1 ]; then
    die "--global is only supported for --tool claude. Use --project or --dir for $TOOL."
  fi
  SCOPE="project"
fi

# ---------- resolve target directory (the project root we deploy into) ----------
case "$SCOPE" in
  global)  TARGET_DIR="$HOME" ;;            # Claude global → adapter lives under ~/.claude/skills/
  project) TARGET_DIR="$(pwd)" ;;
  custom)  TARGET_DIR="${CUSTOM_DIR%/}" ;;
esac

# ---------- prerequisite checks ----------
require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    die "python3 not found on PATH. Install Python 3.8+ first (https://www.python.org)."
  fi
  PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  PY_MAJOR=${PY_VER%.*}
  PY_MINOR=${PY_VER#*.}
  if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 8 ]; }; then
    die "Python $PY_VER too old. Need Python ≥3.8."
  fi
}

# ---------- locate clone (for local-source path) ----------
HERE=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || HERE=""
fi
LOCAL_REPO=""
if [ -n "$HERE" ] && [ -f "$HERE/skills/$SKILL_NAME/SKILL.md" ]; then
  LOCAL_REPO="$HERE"
fi

BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}"

# Copy a single source file (relative to repo root) into a destination path.
# Prefers the local clone; otherwise downloads from raw GitHub.
deploy_file() {
  local src_rel="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -n "$LOCAL_REPO" ] && [ -f "$LOCAL_REPO/$src_rel" ]; then
    cp "$LOCAL_REPO/$src_rel" "$dest"
  else
    command -v curl >/dev/null 2>&1 || die "curl not found. Install curl or clone the repo."
    curl -fsSL "$BASE_URL/$src_rel" -o "$dest" \
      || die "Failed to download $src_rel from $BASE_URL/$src_rel"
  fi
}

# Confirm overwrite (or refuse non-interactively) when any target file already exists.
confirm_overwrite() {
  local existing="$1"
  [ "$FORCE" -eq 1 ] && return 0
  if [ -t 0 ]; then
    printf "%s?%s  %s already exists. Overwrite? [y/N] " "$C_YELLOW" "$C_RESET" "$existing"
    read -r REPLY
    case "$REPLY" in
      y|Y|yes|YES) return 0 ;;
      *) die "Aborted." ;;
    esac
  else
    die "$existing already exists. Re-run with --force to overwrite."
  fi
}

# Where the pipeline engine lives, per tool.
script_dest_for() {
  case "$1" in
    claude)
      case "$SCOPE" in
        global)  echo "${TARGET_DIR}/.claude/skills/${SKILL_NAME}/scripts/run-pipeline.py" ;;
        *)       echo "${TARGET_DIR}/.claude/skills/${SKILL_NAME}/scripts/run-pipeline.py" ;;
      esac
      ;;
    agents-skills)
      echo "${TARGET_DIR}/.agents/skills/${SKILL_NAME}/scripts/run-pipeline.py"
      ;;
    *)
      echo "${TARGET_DIR}/.${SKILL_NAME}/scripts/run-pipeline.py"
      ;;
  esac
}

# All the destination paths a given tool touches (excluding the script).
# Used for both install (to compute "would overwrite?") and uninstall.
adapter_paths_for() {
  case "$1" in
    claude)        echo "${TARGET_DIR}/.claude/skills/${SKILL_NAME}/SKILL.md" ;;
    codex)         echo "${TARGET_DIR}/AGENTS.md" ;;
    gemini)        echo "${TARGET_DIR}/GEMINI.md" "${TARGET_DIR}/gemini-extension.json" ;;
    cursor)        echo "${TARGET_DIR}/.cursor/rules/pre-flight-check.mdc" ;;
    copilot)       echo "${TARGET_DIR}/.github/copilot-instructions.md" ;;
    windsurf)      echo "${TARGET_DIR}/.windsurf/rules/pre-flight-check.md" ;;
    cline)         echo "${TARGET_DIR}/.clinerules/pre-flight-check.md" ;;
    kiro)          echo "${TARGET_DIR}/.kiro/steering/pre-flight-check.md" ;;
    roo)           echo "${TARGET_DIR}/.roo/rules/pre-flight-check.md" ;;
    agents-skills) echo "${TARGET_DIR}/.agents/skills/${SKILL_NAME}/SKILL.md" ;;
  esac
}

# Install everything for one tool.
install_tool() {
  local tool="$1"
  log "Installing for ${C_BOLD}${tool}${C_RESET}"

  # Pre-flight: refuse to clobber if --force not set.
  local script_dest
  script_dest=$(script_dest_for "$tool")
  for path in $(adapter_paths_for "$tool") "$script_dest"; do
    [ -e "$path" ] && confirm_overwrite "$path"
  done

  # Deploy the engine (always).
  deploy_file "skills/${SKILL_NAME}/scripts/run-pipeline.py" "$script_dest"
  chmod +x "$script_dest"

  # Deploy the tool-specific adapter file(s).
  case "$tool" in
    claude)
      deploy_file "skills/${SKILL_NAME}/SKILL.md" "${TARGET_DIR}/.claude/skills/${SKILL_NAME}/SKILL.md"
      ;;
    codex)
      deploy_file "AGENTS.md" "${TARGET_DIR}/AGENTS.md"
      ;;
    gemini)
      deploy_file "GEMINI.md" "${TARGET_DIR}/GEMINI.md"
      deploy_file "gemini-extension.json" "${TARGET_DIR}/gemini-extension.json"
      ;;
    cursor)
      deploy_file "adapters/cursor/pre-flight-check.mdc" "${TARGET_DIR}/.cursor/rules/pre-flight-check.mdc"
      ;;
    copilot)
      deploy_file "adapters/copilot/copilot-instructions.md" "${TARGET_DIR}/.github/copilot-instructions.md"
      ;;
    windsurf)
      deploy_file "adapters/windsurf/pre-flight-check.md" "${TARGET_DIR}/.windsurf/rules/pre-flight-check.md"
      ;;
    cline)
      deploy_file "adapters/cline/pre-flight-check.md" "${TARGET_DIR}/.clinerules/pre-flight-check.md"
      ;;
    kiro)
      deploy_file "adapters/kiro/pre-flight-check.md" "${TARGET_DIR}/.kiro/steering/pre-flight-check.md"
      ;;
    roo)
      deploy_file "adapters/roo/pre-flight-check.md" "${TARGET_DIR}/.roo/rules/pre-flight-check.md"
      ;;
    agents-skills)
      deploy_file "skills/${SKILL_NAME}/SKILL.md" "${TARGET_DIR}/.agents/skills/${SKILL_NAME}/SKILL.md"
      ;;
  esac

  ok "Installed for ${C_BOLD}${tool}${C_RESET}"
}

# Remove everything for one tool. Best-effort: missing files are warnings, not errors.
uninstall_tool() {
  local tool="$1"
  log "Uninstalling ${C_BOLD}${tool}${C_RESET}"

  local removed=0
  for path in $(adapter_paths_for "$tool") "$(script_dest_for "$tool")"; do
    if [ -e "$path" ]; then
      rm -f "$path"
      removed=$((removed + 1))
    fi
  done

  # Best-effort cleanup of empty parent dirs we created.
  case "$tool" in
    claude)        rmdir "${TARGET_DIR}/.claude/skills/${SKILL_NAME}/scripts" "${TARGET_DIR}/.claude/skills/${SKILL_NAME}" 2>/dev/null || true ;;
    cursor)        rmdir "${TARGET_DIR}/.cursor/rules" "${TARGET_DIR}/.cursor" 2>/dev/null || true ;;
    windsurf)      rmdir "${TARGET_DIR}/.windsurf/rules" "${TARGET_DIR}/.windsurf" 2>/dev/null || true ;;
    cline)         rmdir "${TARGET_DIR}/.clinerules" 2>/dev/null || true ;;
    kiro)          rmdir "${TARGET_DIR}/.kiro/steering" "${TARGET_DIR}/.kiro" 2>/dev/null || true ;;
    roo)           rmdir "${TARGET_DIR}/.roo/rules" "${TARGET_DIR}/.roo" 2>/dev/null || true ;;
    agents-skills) rmdir "${TARGET_DIR}/.agents/skills/${SKILL_NAME}/scripts" "${TARGET_DIR}/.agents/skills/${SKILL_NAME}" "${TARGET_DIR}/.agents/skills" "${TARGET_DIR}/.agents" 2>/dev/null || true ;;
  esac
  # Shared neutral script dir for non-Claude tools.
  if [ "$tool" != "claude" ] && [ "$tool" != "agents-skills" ]; then
    rmdir "${TARGET_DIR}/.${SKILL_NAME}/scripts" "${TARGET_DIR}/.${SKILL_NAME}" 2>/dev/null || true
  fi

  if [ "$removed" -eq 0 ]; then
    warn "Nothing to remove for $tool at $TARGET_DIR."
  else
    ok "Removed $removed file(s) for ${C_BOLD}${tool}${C_RESET}."
  fi
}

# ---------- main ----------
if [ "$UNINSTALL" -eq 0 ]; then
  require_python
fi

# Expand `--tool all` to every concrete tool.
if [ "$TOOL" = "all" ]; then
  TOOLS_TO_RUN="claude codex gemini cursor copilot windsurf cline kiro roo agents-skills"
else
  TOOLS_TO_RUN="$TOOL"
fi

if [ "$UNINSTALL" -eq 1 ]; then
  for t in $TOOLS_TO_RUN; do
    uninstall_tool "$t"
  done
  exit 0
fi

for t in $TOOLS_TO_RUN; do
  install_tool "$t"
done

# ---------- post-install summary ----------
echo
ok "Done."
echo
printf "  %sTool(s):%s   %s\n" "$C_DIM" "$C_RESET" "$TOOLS_TO_RUN"
printf "  %sScope:%s     %s\n" "$C_DIM" "$C_RESET" "$SCOPE"
printf "  %sTarget:%s    %s\n" "$C_DIM" "$C_RESET" "$TARGET_DIR"
printf "  %sPython:%s    %s (%s)\n" "$C_DIM" "$C_RESET" "${PY_VER:-?}" "$(command -v python3 || echo n/a)"
printf "  %sSource:%s    %s\n" "$C_DIM" "$C_RESET" "${LOCAL_REPO:-${REPO}@${REF}}"
echo
echo "Next steps:"
echo "  1. Open your AI tool in the project root: $TARGET_DIR"
echo "  2. The skill / rule / instruction file is auto-discovered."
echo "  3. Ask your agent to 'run pre-flight check' — it should invoke:"
case "$TOOLS_TO_RUN" in
  claude*) printf "       %spython3 %s/.claude/skills/%s/scripts/run-pipeline.py%s\n" "$C_BOLD" "$TARGET_DIR" "$SKILL_NAME" "$C_RESET" ;;
  agents-skills*) printf "       %spython3 %s/.agents/skills/%s/scripts/run-pipeline.py%s\n" "$C_BOLD" "$TARGET_DIR" "$SKILL_NAME" "$C_RESET" ;;
  *) printf "       %spython3 %s/.%s/scripts/run-pipeline.py%s\n" "$C_BOLD" "$TARGET_DIR" "$SKILL_NAME" "$C_RESET" ;;
esac
echo
echo "Uninstall: re-run with --uninstall (and the same --tool flag)."
