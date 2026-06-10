#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  Claude Code · Statusline Cockpit
#  Line 1: model, rate limits, context window, git branch
#  Line 2: git changes · CMS/framework detected · MCP servers · path
# ──────────────────────────────────────────────────────────────
#  Requires: jq, git
# ──────────────────────────────────────────────────────────────

input=$(cat)

DIM='\033[2m'
RESET='\033[0m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
SEP="${DIM}│${RESET}"

CWD=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$CWD" ] && CWD="$PWD"

# ── LINE 1: legacy statusline ────────────────────────────────
LEGACY="$HOME/.claude/statusline-legacy.sh"
if [ -x "$LEGACY" ]; then
  line1=$(echo "$input" | bash "$LEGACY")
else
  line1=$(echo "$input" | jq -r '.model.display_name // "Claude"')
fi

# ── LINE 2 ───────────────────────────────────────────────────
parts=()

# GIT: number of changes (branch is already in line 1)
if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty=$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dirty" -gt 0 ]; then
    parts+=("$(printf "${YELLOW}✱%s changes${RESET}" "$dirty")")
  else
    parts+=("$(printf "${GREEN}✓ clean${RESET}")")
  fi
fi

# CMS / FRAMEWORK detection
detect_stack() {
  local d="$CWD"
  if [ -f "$d/wp-config.php" ] || [ -f "$d/wp-load.php" ] || [ -d "$d/wp-content" ]; then
    local wpver=""
    local verfile="$d/wp-includes/version.php"
    [ -f "$verfile" ] && wpver=$(grep -oP "wp_version\s*=\s*'\K[0-9.]+" "$verfile" 2>/dev/null | head -1)
    if command -v php >/dev/null 2>&1; then
      local phpver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
      local wpcli=""
      command -v wp >/dev/null 2>&1 && wpcli=" · wp-cli ✓"
      echo "WP ${wpver:-?} · PHP ${phpver}${wpcli}"
    else
      echo "WP ${wpver:-?}"
    fi
    return
  fi
  [ -f "$d/artisan" ] && { echo "Laravel"; return; }
  [ -f "$d/core/lib/Drupal.php" ] && { echo "Drupal"; return; }
  { [ -f "$d/configuration.php" ] && [ -d "$d/administrator" ]; } && { echo "Joomla"; return; }
  { [ -f "$d/next.config.js" ] || [ -f "$d/next.config.mjs" ] || [ -f "$d/next.config.ts" ]; } && { echo "Next.js"; return; }
  if [ -f "$d/package.json" ]; then
    local nodever=""
    command -v node >/dev/null 2>&1 && nodever=$(node -v 2>/dev/null)
    echo "Node ${nodever}"; return
  fi
  { [ -f "$d/pyproject.toml" ] || [ -f "$d/requirements.txt" ]; } && { echo "Python"; return; }
}
stack=$(detect_stack)
[ -n "$stack" ] && parts+=("$(printf "${CYAN}%s${RESET}" "$stack")")

# MCP servers (project .mcp.json + global)
count_mcp() {
  local total=0
  local proj="$CWD/.mcp.json"
  if [ -f "$proj" ]; then
    local n=$(jq -r '(.mcpServers // {}) | length' "$proj" 2>/dev/null)
    [ -n "$n" ] && total=$((total + n))
  fi
  local glob="$HOME/.claude.json"
  if [ -f "$glob" ]; then
    local g=$(jq -r --arg p "$CWD" '
      ((.mcpServers // {}) | length) +
      ((.projects[$p].mcpServers // {}) | length)
    ' "$glob" 2>/dev/null)
    [ -n "$g" ] && total=$((total + g))
  fi
  echo "$total"
}
mcp=$(count_mcp)
[ "${mcp:-0}" -gt 0 ] && parts+=("$(printf "${BLUE}mcp: %s${RESET}" "$mcp")")

# Abbreviated path
short=$(echo "$CWD" | sed "s|$HOME|~|")
parts+=("$(printf "${DIM}%s${RESET}" "$short")")

# Assemble
line2=""
for i in "${!parts[@]}"; do
  if [ "$i" -eq 0 ]; then line2="${parts[$i]}"
  else line2="${line2}  ${SEP}  ${parts[$i]}"; fi
done

printf "%b\n%b" "$line1" "$line2"
